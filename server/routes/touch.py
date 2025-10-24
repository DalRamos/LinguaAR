# fsl_api.py
from flask import Blueprint, jsonify, request
import os, time, json
import pickle
import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf
from tensorflow import keras
from collections import deque
from json import JSONDecodeError

# ──────────────────────────────────────────────────────────────────────────────
# Blueprint
# ──────────────────────────────────────────────────────────────────────────────
touch_routes = Blueprint('touch_routes', __name__)

# ──────────────────────────────────────────────────────────────────────────────
# Paths
# ──────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR  = os.path.join(SCRIPT_DIR, '..', 'Model')

# Alphabet (pickle, landmarks)
ALPHA_PKL = os.path.join(MODEL_DIR, 'model.p')

# Number (image CNN) + labels
NUM_KERAS = os.path.join(MODEL_DIR, 'number.keras')
NUM_LABEL = os.path.join(MODEL_DIR, 'number.json')  # can be JSON array/dict or newline/CSV text

# Word (LSTM) + actions + dataset norm
WORD_H5   = os.path.join(MODEL_DIR, 'word98.h5')
WORD_ACT  = os.path.join(MODEL_DIR, 'actions_order.txt')
NORM_MEAN = os.path.join(MODEL_DIR, 'norm_mean.npy')   # produced by your fslcreatemodel pipeline
NORM_STD  = os.path.join(MODEL_DIR, 'norm_std.npy')

# ──────────────────────────────────────────────────────────────────────────────
# Globals
# ──────────────────────────────────────────────────────────────────────────────
alphabet_model = None
number_model   = None
number_labels  = []
word_model     = None
word_actions   = []
norm_mean      = None
norm_std       = None

# constants / tunables (aligned with your hybrid + fslcreatemodel)
IMG_SIZE = (64, 64)            # number.keras input
MIN_HAND_BBOX_PIX = 60         # gate tiny/false hand boxes
WORD_CONF_THRESH  = 0.60       # server-side confidence threshold
WORD_SEQ_DEFAULT  = 30

ALPHABET_LABELS = {i: chr(ord('A') + i) for i in range(26)}

# per-session sequences for word streaming
word_sequences: dict[str, deque] = {}  # session_id -> deque

# ──────────────────────────────────────────────────────────────────────────────
# Utilities
# ──────────────────────────────────────────────────────────────────────────────
def _log(msg: str): print(msg, flush=True)

def _load_number_labels(path: str):
    """
    Be liberal in what we accept:
    - JSON array: ["0","1","2",...]
    - JSON dict:  {"0":"0","1":"1", ...} or {"labels":[...]} / {"classes":[...]}
    - Plain text: newline-separated or comma-separated
    """
    if not os.path.exists(path):
        return []

    try:
        with open(path, 'r', encoding='utf-8') as f:
            txt = f.read().strip()
        try:
            data = json.loads(txt)
            if isinstance(data, list):
                return [str(x) for x in data]
            if isinstance(data, dict):
                if 'labels' in data and isinstance(data['labels'], list):
                    return [str(x) for x in data['labels']]
                if 'classes' in data and isinstance(data['classes'], list):
                    return [str(x) for x in data['classes']]
                # dict of index->label
                try:
                    items = sorted(((int(k), str(v)) for k, v in data.items()), key=lambda kv: kv[0])
                    return [v for _, v in items]
                except Exception:
                    # fall-through to text parsing
                    pass
        except JSONDecodeError:
            # not valid JSON -> try text formats
            pass

        # text parse: lines or CSV
        if '\n' in txt:
            lines = [ln.strip() for ln in txt.splitlines() if ln.strip()]
            # handle "0,1,2" on one line as well
            if len(lines) == 1 and (',' in lines[0]):
                return [s.strip() for s in lines[0].split(',') if s.strip()]
            return lines
        if ',' in txt:
            return [s.strip() for s in txt.split(',') if s.strip()]
        # single token -> still return
        return [txt] if txt else []

    except Exception as e:
        _log(f"❌ Number labels load error (robust): {e}")
        return []

def _get_word_seq_len_and_dim():
    if word_model is None:
        return WORD_SEQ_DEFAULT, None
    ishape = word_model.input_shape  # (None, T, F)
    try:
        T = int(ishape[1]) if isinstance(ishape, (list, tuple)) else WORD_SEQ_DEFAULT
        F = int(ishape[2]) if isinstance(ishape, (list, tuple)) and len(ishape) > 2 else None
        return (T if T > 0 else WORD_SEQ_DEFAULT), F
    except Exception:
        return WORD_SEQ_DEFAULT, None

def _get_session_deque(session_id: str, maxlen: int):
    if session_id not in word_sequences:
        word_sequences[session_id] = deque(maxlen=maxlen)
    return word_sequences[session_id]

# dataset-level normalization for word sequences (preserve zeros)
def _normalize_seq_inplace(seq_np: np.ndarray):
    global norm_mean, norm_std
    if norm_mean is None or norm_std is None:
        return seq_np
    mean = norm_mean.reshape(1, 1, -1).astype(np.float32)
    std  = norm_std.reshape(1, 1, -1).astype(np.float32)
    nz_mask = seq_np != 0
    seq_np[:] = (seq_np - mean) / std
    seq_np[~nz_mask] = 0.0
    return seq_np

# ── MediaPipe setup
mp_hands    = mp.solutions.hands
mp_holistic = mp.solutions.holistic

hands_detector = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

holistic = mp_holistic.Holistic(
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# ── HYBRID helpers (numbers: largest-hand crop)
def _detect_largest_hand_roi(frame_bgr: np.ndarray):
    h, w = frame_bgr.shape[:2]
    res = hands_detector.process(cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB))
    if not res.multi_hand_landmarks:
        return None
    best = None; best_area = -1
    for lm in res.multi_hand_landmarks:
        xs = [p.x for p in lm.landmark]; ys = [p.y for p in lm.landmark]
        x1, y1 = int(min(xs)*w), int(min(ys)*h)
        x2, y2 = int(max(xs)*w), int(max(ys)*h)
        bw, bh = x2 - x1, y2 - y1
        area = max(0, bw) * max(0, bh)
        if area > best_area:
            best_area = area
            best = (x1, y1, x2, y2, bw, bh)
    if best is None:
        return None
    x1, y1, x2, y2, bw, bh = best
    if bw < MIN_HAND_BBOX_PIX or bh < MIN_HAND_BBOX_PIX:
        return None
    cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
    half = int(0.5 * max(bw, bh) * 1.35)  # small margin
    sx1, sy1 = max(0, cx - half), max(0, cy - half)
    sx2, sy2 = min(w, cx + half), min(h, cy + half)
    roi = frame_bgr[sy1:sy2, sx1:sx2]
    return roi if roi.size else None

def _preprocess_number_roi(roi_bgr: np.ndarray):
    rgb  = cv2.cvtColor(roi_bgr, cv2.COLOR_BGR2RGB)
    resz = cv2.resize(rgb, IMG_SIZE, interpolation=cv2.INTER_AREA)
    arr  = resz.astype('float32') / 255.0
    return np.expand_dims(arr, axis=0)

# ── fslcreatemodel-style feature builder for words (abs + relative)
def _extract_raw_segments(results, include_face=True):
    pose = (np.array([[lm.x, lm.y, lm.z, lm.visibility]
                      for lm in (results.pose_landmarks.landmark if results.pose_landmarks else [])],
                     dtype=np.float32).flatten()
            if results.pose_landmarks else np.zeros(33*4, dtype=np.float32))
    face = (np.array([[lm.x, lm.y, lm.z]
                      for lm in (results.face_landmarks.landmark if results.face_landmarks else [])],
                     dtype=np.float32).flatten()
            if (include_face and results.face_landmarks) else
            (np.zeros(468*3, dtype=np.float32) if include_face else np.zeros(0, dtype=np.float32)))
    lh = (np.array([[lm.x, lm.y, lm.z]
                    for lm in (results.left_hand_landmarks.landmark if results.left_hand_landmarks else [])],
                   dtype=np.float32).flatten()
          if results.left_hand_landmarks else np.zeros(21*3, dtype=np.float32))
    rh = (np.array([[lm.x, lm.y, lm.z]
                    for lm in (results.right_hand_landmarks.landmark if results.right_hand_landmarks else [])],
                   dtype=np.float32).flatten()
          if results.right_hand_landmarks else np.zeros(21*3, dtype=np.float32))
    return np.concatenate([pose, face, lh, rh]).astype(np.float32)

def _relative_wrist_to_shoulders(results):
    if not results.pose_landmarks:
        return np.zeros(6, dtype=np.float32)
    ls = results.pose_landmarks.landmark[11]
    rs = results.pose_landmarks.landmark[12]
    ls_xyz = np.array([ls.x, ls.y, ls.z], dtype=np.float32)
    rs_xyz = np.array([rs.x, rs.y, rs.z], dtype=np.float32)
    if results.left_hand_landmarks:
        lw = results.left_hand_landmarks.landmark[0]
        lw_xyz = np.array([lw.x, lw.y, lw.z], dtype=np.float32) - ls_xyz
    else:
        lw_xyz = np.zeros(3, dtype=np.float32)
    if results.right_hand_landmarks:
        rw = results.right_hand_landmarks.landmark[0]
        rw_xyz = np.array([rw.x, rw.y, rw.z], dtype=np.float32) - rs_xyz
    else:
        rw_xyz = np.zeros(3, dtype=np.float32)
    return np.concatenate([lw_xyz, rw_xyz]).astype(np.float32)

def _get_feature_vector(results):
    base = _extract_raw_segments(results, include_face=True)
    rel6 = _relative_wrist_to_shoulders(results)
    return np.concatenate([base, rel6]).astype(np.float32)

# ──────────────────────────────────────────────────────────────────────────────
# Load models & labels
# ──────────────────────────────────────────────────────────────────────────────
# Alphabet
if os.path.exists(ALPHA_PKL):
    try:
        with open(ALPHA_PKL, 'rb') as f:
            alpha_dict = pickle.load(f)
        alphabet_model = alpha_dict['model']
        _log("✅ Alphabet model (pickle) loaded")
    except Exception as e:
        _log(f"❌ Alphabet model load error: {e}")
else:
    _log("⚠️ Alphabet model not found")

# Number
if os.path.exists(NUM_KERAS):
    try:
        number_model = keras.models.load_model(NUM_KERAS)
        _log("✅ Number model loaded")
    except Exception as e:
        _log(f"❌ Number model load error: {e}")
else:
    _log("⚠️ Number model not found")

try:
    number_labels = _load_number_labels(NUM_LABEL)
    if number_labels:
        _log(f"✅ Number labels loaded: {len(number_labels)}")
    else:
        _log("⚠️ Number labels missing or empty — will fallback to class index")
except Exception as e:
    _log(f"❌ Number labels load error: {e}")

# Word
if os.path.exists(WORD_H5):
    try:
        word_model = tf.keras.models.load_model(WORD_H5)
        _log("✅ Word model loaded")
    except Exception as e:
        _log(f"❌ Word model load error: {e}")
else:
    _log("⚠️ Word model not found")

if os.path.exists(WORD_ACT):
    try:
        with open(WORD_ACT, 'r', encoding='utf-8') as f:
            word_actions = [ln.strip() for ln in f if ln.strip()]
        _log(f"✅ Word actions loaded: {len(word_actions)}")
    except Exception as e:
        _log(f"❌ Word actions load error: {e}")
else:
    _log("⚠️ actions_order.txt missing — labels may mismatch")

if os.path.exists(NORM_MEAN) and os.path.exists(NORM_STD):
    try:
        norm_mean = np.load(NORM_MEAN).astype(np.float32)
        norm_std  = np.load(NORM_STD).astype(np.float32)
        _log("✅ norm_mean/std loaded")
    except Exception as e:
        _log(f"❌ Failed loading norm stats: {e}")
else:
    _log("⚠️ norm_mean.npy / norm_std.npy missing — realtime word normalization will be skipped")

# ──────────────────────────────────────────────────────────────────────────────
# Routes
# ──────────────────────────────────────────────────────────────────────────────
@touch_routes.route('/static', methods=['POST'])
def recognize_static():
    """
    POST multipart/form-data:
      - file: image frame (jpeg)
      - category: 'alphabet' | 'number'  (default: 'alphabet')
    Returns JSON:
      {
        status: "success"|"error",
        predicted_character?: string,
        confidence?: float,
        type?: "alphabet"|"number",
        message?: string
      }
    """
    if 'file' not in request.files:
        return jsonify({"status": "error", "message": "No file part"}), 400

    category = (request.form.get('category') or request.args.get('category') or 'alphabet').lower()
    file = request.files['file']
    if not file.filename:
        return jsonify({"status": "error", "message": "No selected file"}), 400

    frame_bytes = np.frombuffer(file.read(), np.uint8)
    frame = cv2.imdecode(frame_bytes, cv2.IMREAD_COLOR)
    if frame is None:
        return jsonify({"status": "error", "message": "Invalid image file"}), 400

    try:
        # Numbers via CNN-on-image with hand ROI crop (hybrid)
        if category == 'number':
            if number_model is None:
                return jsonify({"status": "error", "message": "Number model not loaded"}), 500
            roi = _detect_largest_hand_roi(frame)
            if roi is None:
                return jsonify({"status": "error", "message": "No hand detected"}), 404
            x = _preprocess_number_roi(roi)
            probs = number_model.predict(x, verbose=0)[0]
            idx   = int(np.argmax(probs))
            conf  = float(np.max(probs))
            label = number_labels[idx] if (number_labels and 0 <= idx < len(number_labels)) else str(idx)
            return jsonify({"status": "success", "predicted_character": label, "confidence": conf, "type": "number"})

        # Alphabet via landmark pickle (classic)
        if alphabet_model is None:
            return jsonify({"status": "error", "message": "Alphabet model not loaded"}), 500

        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        res = hands_detector.process(rgb)
        if not res.multi_hand_landmarks:
            return jsonify({"status": "error", "message": "No hand detected"}), 404

        data_aux, xs, ys = [], [], []
        for hand_lm in res.multi_hand_landmarks:
            for i in range(len(hand_lm.landmark)):
                xs.append(hand_lm.landmark[i].x)
                ys.append(hand_lm.landmark[i].y)
            for i in range(len(hand_lm.landmark)):
                x = hand_lm.landmark[i].x; y = hand_lm.landmark[i].y
                data_aux.extend([x - min(xs), y - min(ys)])

        pred = alphabet_model.predict([np.asarray(data_aux)])
        char_idx = int(pred[0]) if hasattr(pred, '__len__') else int(pred)
        char = ALPHABET_LABELS.get(char_idx, '?')
        return jsonify({"status": "success", "predicted_character": char, "type": "alphabet"})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500


@touch_routes.route('/hands', methods=['POST'])
def recognize_gesture_compat():
    # alias for alphabet
    request.form = request.form.copy()
    request.form['category'] = 'alphabet'
    return recognize_static()


@touch_routes.route('/numbers', methods=['POST'])
def recognize_numbers_compat():
    # alias for number
    request.form = request.form.copy()
    request.form['category'] = 'number'
    return recognize_static()


@touch_routes.route('/words', methods=['POST'])
def recognize_words():
    """
    Stream frames for word (sequence) recognition.
    Request form-data:
      - file: frame (jpeg)
      - session_id: string
    Response:
      {
        status: "success"|"error",
        type: "word",
        ready: bool,
        detections: {pose,bool,left_hand,bool,right_hand,bool,face,bool},
        top_prediction?: { word, confidence, index }
      }
    """
    if 'file' not in request.files:
        return jsonify({"status":"error","message":"No file part"}), 400
    if word_model is None:
        return jsonify({"status":"error","message":"Word model not loaded"}), 500

    T, F_expected = _get_word_seq_len_and_dim()
    session_id = request.form.get('session_id', 'default')

    file = request.files['file']
    if not file.filename:
        return jsonify({"status":"error","message":"No selected file"}), 400

    frame_bytes = np.frombuffer(file.read(), np.uint8)
    frame = cv2.imdecode(frame_bytes, cv2.IMREAD_COLOR)
    if frame is None:
        return jsonify({"status":"error","message":"Invalid image file"}), 400

    try:
        img = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img.flags.writeable = False
        results = holistic.process(img)
        img.flags.writeable = True

        feats = _get_feature_vector(results)

        # pad/truncate to match model's feature dim
        if F_expected is not None and feats.shape[0] != F_expected:
            if feats.shape[0] < F_expected:
                tmp = np.zeros(F_expected, dtype=np.float32)
                tmp[:feats.shape[0]] = feats
                feats = tmp
            else:
                feats = feats[:F_expected]

        seq = _get_session_deque(session_id, maxlen=T)
        seq.append(feats)
        ready = (len(seq) >= T)

        resp = {
            "status": "success",
            "type": "word",
            "ready": ready,
            "detections": {
                "pose": results.pose_landmarks is not None,
                "left_hand": results.left_hand_landmarks is not None,
                "right_hand": results.right_hand_landmarks is not None,
                "face": results.face_landmarks is not None
            }
        }

        if ready:
            arr = np.array([list(seq)], dtype=np.float32)  # (1, T, F)
            _normalize_seq_inplace(arr)
            probs = word_model.predict(arr, verbose=0)[0]
            idx   = int(np.argmax(probs))
            conf  = float(np.max(probs))
            if conf >= WORD_CONF_THRESH and word_actions and 0 <= idx < len(word_actions):
                resp["top_prediction"] = {"word": word_actions[idx], "confidence": conf, "index": idx}

        return jsonify(resp)

    except Exception as e:
        return jsonify({"status":"error","message":str(e)}), 500


@touch_routes.route('/words/reset', methods=['POST'])
def reset_word_sequence():
    session_id = request.json.get('session_id', 'default') if request.is_json else 'default'
    if session_id in word_sequences:
        word_sequences[session_id].clear()
    return jsonify({"status":"success","message":"Word sequence reset","session_id":session_id})


@touch_routes.route('/words/actions', methods=['GET'])
def get_word_actions():
    return jsonify({"status":"success","actions":word_actions,"count":len(word_actions)})


@touch_routes.route('/words/status', methods=['GET'])
def get_word_status():
    session_id = request.args.get('session_id', 'default')
    seq = word_sequences.get(session_id, deque())
    return jsonify({"status":"success","session_id":session_id,"length":len(seq)})


@touch_routes.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status": "healthy",
        "models": {
            "alphabet": alphabet_model is not None,
            "number": number_model is not None,
            "word": word_model is not None
        },
        "word_actions_count": len(word_actions),
        "number_labels_count": len(number_labels),
        "word_seq_len": _get_word_seq_len_and_dim()[0],
        "timestamp": time.time()
    })


def create_touch_routes(app):
    # NOTE: url_prefix is '/gesture' so health becomes '/gesture/health'
    app.register_blueprint(touch_routes, url_prefix='/gesture')
