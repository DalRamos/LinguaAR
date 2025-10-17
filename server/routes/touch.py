from flask import Blueprint, jsonify, request
import os
import pickle
import cv2
import mediapipe as mp
import numpy as np
import json
import tensorflow as tf
from tensorflow import keras
import time
from collections import deque

# Initialize the Blueprint for gesture routes
touch_routes = Blueprint('touch_routes', __name__)

# Load the gesture recognition model for alphabets
script_dir = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(script_dir, '..', 'Model', 'model.p')
model_dict = pickle.load(open(model_path, 'rb'))
model = model_dict['model']

# Load the number model and labels
number_model_path = os.path.join(script_dir, '..', 'Model', 'number.keras')
number_labels_path = os.path.join(script_dir, '..', 'Model', 'number.json')

# Word recognition model and configuration
word_model_path = os.path.join(script_dir, '..', 'Model', 'word98.h5')
word_labels_path = os.path.join(script_dir, '..', 'Model', 'actions_order.txt')

# Load number model and labels
number_model = None
number_labels = []

# Word recognition variables
word_model = None
word_actions = []
word_sequence_length = 30
word_sequences = {}  # Store sequences per session

if os.path.exists(number_model_path):
    try:
        number_model = keras.models.load_model(number_model_path)
        print("✅ Number model loaded successfully")
    except Exception as e:
        print(f"❌ Failed to load number model: {e}")

if os.path.exists(number_labels_path):
    try:
        with open(number_labels_path, 'r', encoding='utf-8') as f:
            number_labels = json.load(f)
        print(f"✅ Number labels loaded: {number_labels}")
    except Exception as e:
        print(f"❌ Failed to load number labels: {e}")

# Load word recognition model
if os.path.exists(word_model_path) and os.path.exists(word_labels_path):
    try:
        word_model = tf.keras.models.load_model(word_model_path)
        with open(word_labels_path, 'r', encoding='utf-8') as f:
            word_actions = [line.strip() for line in f if line.strip()]
        print(f"✅ Word model loaded successfully with {len(word_actions)} actions: {word_actions}")
    except Exception as e:
        print(f"❌ Failed to load word model: {e}")
else:
    print("⚠️  Word model or labels not found, word recognition will be disabled")

# Initialize MediaPipe
mp_hands = mp.solutions.hands
mp_holistic = mp.solutions.holistic
hands = mp_hands.Hands(static_image_mode=True, min_detection_confidence=0.3)

# Initialize MediaPipe Holistic for word recognition
holistic = mp_holistic.Holistic(
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# Labels for alphabet gesture recognition
labels_dict = {
    0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J',
    10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S',
    19: 'T', 20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z'
}

# Word recognition helper functions
def mediapipe_detection(image, model):
    """MediaPipe detection function for word recognition"""
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    image.flags.writeable = False
    results = model.process(image)
    image.flags.writeable = True
    return cv2.cvtColor(image, cv2.COLOR_RGB2BGR), results

def extract_raw_segments(results, include_face=True):
    """Extract landmarks from MediaPipe results for word recognition"""
    # Pose (x,y,z,visibility)
    pose = (np.array([[lm.x, lm.y, lm.z, lm.visibility]
                     for lm in results.pose_landmarks.landmark], dtype=np.float32).flatten()
            if results.pose_landmarks else np.zeros(33*4, dtype=np.float32))
    
    # Face (x,y,z) - optional
    face = (np.array([[lm.x, lm.y, lm.z]
                     for lm in results.face_landmarks.landmark], dtype=np.float32).flatten()
            if (include_face and results.face_landmarks) else
            (np.zeros(468*3, dtype=np.float32) if include_face else np.zeros(0, dtype=np.float32)))
    
    # Hands (x,y,z)
    lh = (np.array([[lm.x, lm.y, lm.z]
                   for lm in results.left_hand_landmarks.landmark], dtype=np.float32).flatten()
          if results.left_hand_landmarks else np.zeros(21*3, dtype=np.float32))
    rh = (np.array([[lm.x, lm.y, lm.z]
                   for lm in results.right_hand_landmarks.landmark], dtype=np.float32).flatten()
          if results.right_hand_landmarks else np.zeros(21*3, dtype=np.float32))
    
    return np.concatenate([pose, face, lh, rh]).astype(np.float32)

def relative_wrist_to_shoulders(results):
    """Calculate relative wrist positions for word recognition"""
    if not results.pose_landmarks:
        return np.zeros(6, dtype=np.float32)
    
    ls = results.pose_landmarks.landmark[11]  # left shoulder
    rs = results.pose_landmarks.landmark[12]  # right shoulder
    ls_xyz = np.array([ls.x, ls.y, ls.z], dtype=np.float32)
    rs_xyz = np.array([rs.x, rs.y, rs.z], dtype=np.float32)
    
    # Left wrist
    if results.left_hand_landmarks:
        lw = results.left_hand_landmarks.landmark[0]
        lw_xyz = np.array([lw.x, lw.y, lw.z], dtype=np.float32) - ls_xyz
    else:
        lw_xyz = np.zeros(3, dtype=np.float32)
    
    # Right wrist
    if results.right_hand_landmarks:
        rw = results.right_hand_landmarks.landmark[0]
        rw_xyz = np.array([rw.x, rw.y, rw.z], dtype=np.float32) - rs_xyz
    else:
        rw_xyz = np.zeros(3, dtype=np.float32)
    
    return np.concatenate([lw_xyz, rw_xyz]).astype(np.float32)

def get_feature_vector(results):
    """Get combined feature vector for word recognition"""
    base = extract_raw_segments(results, include_face=True)
    rel6 = relative_wrist_to_shoulders(results)
    return np.concatenate([base, rel6]).astype(np.float32)

def get_session_sequence(session_id):
    """Get or create sequence for a session"""
    if session_id not in word_sequences:
        word_sequences[session_id] = deque(maxlen=word_sequence_length)
    return word_sequences[session_id]

def clear_session_sequence(session_id):
    """Clear sequence for a session"""
    if session_id in word_sequences:
        word_sequences[session_id].clear()

@touch_routes.route('/hands', methods=['POST'])
def recognize_gesture():
    """Recognize alphabet gestures"""
    if 'file' not in request.files:
        return jsonify({"status": "error", "message": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"status": "error", "message": "No selected file"}), 400

    try:
        # Read the image file
        file_bytes = np.frombuffer(file.read(), np.uint8)
        frame = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

        # Process the frame for gesture recognition
        data_aux = []
        x_ = []
        y_ = []

        H, W, _ = frame.shape
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = hands.process(frame_rgb)

        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                for i in range(len(hand_landmarks.landmark)):
                    x = hand_landmarks.landmark[i].x
                    y = hand_landmarks.landmark[i].y
                    x_.append(x)
                    y_.append(y)

                for i in range(len(hand_landmarks.landmark)):
                    x = hand_landmarks.landmark[i].x
                    y = hand_landmarks.landmark[i].y
                    data_aux.append(x - min(x_))
                    data_aux.append(y - min(y_))

            x1 = int(min(x_) * W) - 10
            y1 = int(min(y_) * H) - 10
            x2 = int(max(x_) * W) - 10
            y2 = int(max(y_) * H) - 10

            # Predict the gesture
            prediction = model.predict([np.asarray(data_aux)])
            predicted_character = labels_dict[int(prediction[0])]

            return jsonify({
                "status": "success",
                "predicted_character": predicted_character,
                "bounding_box": [x1, y1, x2, y2],
                "type": "alphabet"
            })
        else:
            return jsonify({"status": "error", "message": "No hand detected"}), 404

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@touch_routes.route('/numbers', methods=['POST'])
def recognize_numbers():
    """Recognize number gestures"""
    if 'file' not in request.files:
        return jsonify({"status": "error", "message": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"status": "error", "message": "No selected file"}), 400

    if number_model is None:
        return jsonify({"status": "error", "message": "Number model not loaded"}), 500

    try:
        # Read and preprocess the image
        file_bytes = np.frombuffer(file.read(), np.uint8)
        frame = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
        
        if frame is None:
            return jsonify({"status": "error", "message": "Invalid image file"}), 400

        # Use MediaPipe Hands for hand detection and cropping
        hand_detected, cropped_hand = detect_and_crop_hand(frame)
        
        if not hand_detected:
            return jsonify({"status": "error", "message": "No hand detected"}), 404

        # Preprocess the cropped hand image for the number model
        processed_image = preprocess_for_number_model(cropped_hand)
        
        # Make prediction
        predictions = number_model.predict(processed_image, verbose=0)
        predicted_class = np.argmax(predictions[0])
        confidence = float(np.max(predictions[0]))
        
        # Get the predicted number
        if number_labels and predicted_class < len(number_labels):
            predicted_number = number_labels[predicted_class]
        else:
            predicted_number = str(predicted_class)

        return jsonify({
            "status": "success",
            "predicted_character": predicted_number,
            "confidence": confidence,
            "type": "number",
            "message": "Number recognized successfully"
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@touch_routes.route('/words', methods=['POST'])
def recognize_words():
    """Recognize word gestures using sequence-based model"""
    if 'file' not in request.files:
        return jsonify({"status": "error", "message": "No file part"}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({"status": "error", "message": "No selected file"}), 400

    if word_model is None:
        return jsonify({"status": "error", "message": "Word model not loaded"}), 500

    try:
        # Get session ID from request or generate one
        session_id = request.form.get('session_id', 'default')
        reset_sequence = request.form.get('reset', 'false').lower() == 'true'

        # Reset sequence if requested
        if reset_sequence:
            clear_session_sequence(session_id)
            return jsonify({
                "status": "success",
                "message": "Sequence reset",
                "session_id": session_id
            })

        # Read the image file
        file_bytes = np.frombuffer(file.read(), np.uint8)
        frame = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
        
        if frame is None:
            return jsonify({"status": "error", "message": "Invalid image file"}), 400

        # Process frame with MediaPipe Holistic
        image, results = mediapipe_detection(frame, holistic)
        
        # Extract features
        features = get_feature_vector(results)
        
        # Get session sequence
        sequence = get_session_sequence(session_id)
        sequence.append(features)
        
        # Check if we have enough frames for prediction
        frames_collected = len(sequence)
        
        response_data = {
            "status": "success",
            "session_id": session_id,
            "frames_collected": frames_collected,
            "frames_required": word_sequence_length,
            "sequence_ready": frames_collected >= word_sequence_length,
            "type": "word"
        }

        # Make prediction if we have enough frames
        if frames_collected >= word_sequence_length:
            # Prepare sequence for prediction
            seq_array = np.array([list(sequence)], dtype=np.float32)
            
            # Make prediction
            predictions = word_model.predict(seq_array, verbose=0)[0]
            
            # Get top predictions
            top_indices = np.argsort(predictions)[::-1][:5]
            top_predictions = [
                {
                    "word": word_actions[i],
                    "confidence": float(predictions[i]),
                    "index": int(i)
                }
                for i in top_indices if predictions[i] > 0.01  # Only include predictions above 1%
            ]
            
            # Add detection status
            detections = {
                "pose": results.pose_landmarks is not None,
                "left_hand": results.left_hand_landmarks is not None,
                "right_hand": results.right_hand_landmarks is not None,
                "face": results.face_landmarks is not None
            }
            
            response_data.update({
                "predictions": top_predictions,
                "detections": detections,
                "top_prediction": top_predictions[0] if top_predictions else None
            })

        return jsonify(response_data)

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@touch_routes.route('/words/reset', methods=['POST'])
def reset_word_sequence():
    """Reset word recognition sequence for a session"""
    session_id = request.json.get('session_id', 'default') if request.is_json else 'default'
    clear_session_sequence(session_id)
    
    return jsonify({
        "status": "success",
        "message": "Word sequence reset",
        "session_id": session_id
    })

@touch_routes.route('/words/actions', methods=['GET'])
def get_word_actions():
    """Get list of available words for recognition"""
    return jsonify({
        "status": "success",
        "actions": word_actions,
        "count": len(word_actions)
    })

@touch_routes.route('/words/status', methods=['GET'])
def get_word_status():
    """Get word recognition status for a session"""
    session_id = request.args.get('session_id', 'default')
    sequence = get_session_sequence(session_id)
    
    return jsonify({
        "status": "success",
        "session_id": session_id,
        "frames_collected": len(sequence),
        "frames_required": word_sequence_length,
        "ready_for_prediction": len(sequence) >= word_sequence_length
    })

@touch_routes.route('/gesture/health', methods=['GET'])
def health_check():
    """Health check endpoint for all gesture recognition models"""
    return jsonify({
        "status": "healthy",
        "models": {
            "alphabet": True,
            "number": number_model is not None,
            "word": word_model is not None
        },
        "word_actions_count": len(word_actions),
        "number_labels_count": len(number_labels),
        "timestamp": time.time()
    })

def detect_and_crop_hand(frame, min_detection_confidence=0.5):
    """Detect hand using MediaPipe and crop the hand region with margin"""
    try:
        import mediapipe as mp
    except ImportError:
        return False, None

    # Tunables
    MARGIN_FRAC = 0.35  # extra margin around the hand bbox
    MIN_PIX = 80        # minimum bbox size in pixels
    
    mp_hands = mp.solutions.hands
    hands = mp_hands.Hands(
        static_image_mode=True,
        max_num_hands=2,
        min_detection_confidence=min_detection_confidence,
        min_tracking_confidence=0.5
    )

    h, w = frame.shape[:2]
    
    # Process the frame
    results = hands.process(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
    hands.close()  # Close the hands processor immediately after use
    
    if not results.multi_hand_landmarks:
        return False, None

    # Choose the largest hand bbox
    best_box = None
    best_area = -1
    for hand_lms in results.multi_hand_landmarks:
        xs = [lm.x for lm in hand_lms.landmark]
        ys = [lm.y for lm in hand_lms.landmark]
        x1 = int(min(xs) * w); y1 = int(min(ys) * h)
        x2 = int(max(xs) * w); y2 = int(max(ys) * h)
        bw = max(1, x2 - x1); bh = max(1, y2 - y1)
        area = bw * bh
        if area > best_area:
            best_area = area
            best_box = (x1, y1, x2, y2)

    if best_box is None:
        return False, None

    x1, y1, x2, y2 = best_box
    bw = x2 - x1; bh = y2 - y1
    
    # Check minimum size
    if bw < MIN_PIX or bh < MIN_PIX:
        return False, None

    # Make square crop with margin
    cx = (x1 + x2) // 2
    cy = (y1 + y2) // 2
    half = int(0.5 * max(bw, bh) * (1 + MARGIN_FRAC))
    sx1 = max(0, cx - half); sy1 = max(0, cy - half)
    sx2 = min(w, cx + half); sy2 = min(h, cy + half)

    # Extract ROI
    roi = frame[sy1:sy2, sx1:sx2]
    if roi.size == 0:
        return False, None

    return True, roi

def preprocess_for_number_model(image, img_size=(64, 64)):
    """Preprocess the cropped hand image for the number model"""
    # Convert BGR to RGB
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    # Resize to match model input size
    image_resized = cv2.resize(image_rgb, img_size, interpolation=cv2.INTER_AREA)
    
    # Normalize pixel values
    image_normalized = image_resized.astype("float32") / 255.0
    
    # Add batch dimension
    image_batch = np.expand_dims(image_normalized, axis=0)
    
    return image_batch

def create_touch_routes(app):
    """Register the touch routes with the Flask app"""
    app.register_blueprint(touch_routes, url_prefix='/gesture')