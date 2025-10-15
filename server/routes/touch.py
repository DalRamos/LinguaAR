from flask import Blueprint, jsonify, request
import os
import pickle
import cv2
import mediapipe as mp
import numpy as np
import tensorflow as tf
from tensorflow import keras
import json
import base64
from collections import deque, Counter

# Initialize the Blueprint for gesture routes
touch_routes = Blueprint('touch_routes', __name__)

# =============================================================================
# ORIGINAL GESTURE RECOGNITION SETUP
# =============================================================================

# Load the gesture recognition model
script_dir = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(script_dir, '..', 'Model', 'model.p')
model_dict = pickle.load(open(model_path, 'rb'))
gesture_model = model_dict['model']

# Initialize MediaPipe Hands for gesture recognition
mp_hands = mp.solutions.hands
gesture_hands = mp_hands.Hands(static_image_mode=True, min_detection_confidence=0.3)

# Labels for gesture recognition
labels_dict = {
    0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J',
    10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S',
    19: 'T', 20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z'
}

# =============================================================================
# NUMBER RECOGNITION SETUP
# =============================================================================

# Global variables for number model
number_model = None
number_labels = []
number_hands = None

# =============================================================================
# WORD RECOGNITION SETUP (NEW)
# =============================================================================

# Global variables for word model
word_model = None
word_labels = []
word_hands = None
word_holistic = None

# Configuration for number and word recognition
IMG_SIZE = (64, 64)
CONF_THRESH = 0.60

def load_number_model():
    """Load the number recognition model and labels"""
    global number_model, number_labels, number_hands
    
    try:
        # FIXED PATH: Go up one level from routes to server, then to model folder
        model_dir = os.path.join(script_dir, '..', 'model')
        model_dir = os.path.normpath(model_dir)  # Normalize the path
        
        number_model_path = os.path.join(model_dir, 'number.keras')
        number_labels_path = os.path.join(model_dir, 'number.json')
        
        print(f"🔍 Looking for number model at: {number_model_path}")
        print(f"🔍 Looking for number labels at: {number_labels_path}")
        
        # Check if files exist
        if not os.path.exists(number_model_path):
            raise FileNotFoundError(f"Model file not found: {number_model_path}")
        if not os.path.exists(number_labels_path):
            raise FileNotFoundError(f"Labels file not found: {number_labels_path}")
        
        # Load model
        number_model = keras.models.load_model(number_model_path)
        print("✅ Number model loaded successfully")
        
        # Load labels
        with open(number_labels_path, 'r', encoding='utf-8') as f:
            number_labels = json.load(f)
        print(f"✅ Number labels loaded: {number_labels}")
        
        # Initialize MediaPipe Hands for number recognition
        number_hands = mp_hands.Hands(
            static_image_mode=True,
            max_num_hands=2,
            min_detection_confidence=0.3
        )
        print("✅ MediaPipe Hands initialized for number recognition (static mode)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error loading number model: {e}")
        return False

def load_word_model():
    """Load the word recognition model and labels"""
    global word_model, word_labels, word_hands, word_holistic
    
    try:
        # FIXED PATH: Go up one level from routes to server, then to model folder
        model_dir = os.path.join(script_dir, '..', 'model')
        model_dir = os.path.normpath(model_dir)
        
        word_model_path = os.path.join(model_dir, 'word98.h5')
        word_labels_path = os.path.join(model_dir, 'actions_order.txt')
        
        print(f"🔍 Looking for word model at: {word_model_path}")
        print(f"🔍 Looking for word labels at: {word_labels_path}")
        
        # Check if files exist
        if not os.path.exists(word_model_path):
            raise FileNotFoundError(f"Word model file not found: {word_model_path}")
        if not os.path.exists(word_labels_path):
            raise FileNotFoundError(f"Word labels file not found: {word_labels_path}")
        
        # Load model
        word_model = keras.models.load_model(word_model_path)
        print("✅ Word model loaded successfully")
        
        # Load labels
        with open(word_labels_path, 'r', encoding='utf-8') as f:
            word_labels = [line.strip() for line in f.readlines() if line.strip()]
        print(f"✅ Word labels loaded: {word_labels}")
        
        # Initialize MediaPipe Holistic for word recognition (sequence-based)
        word_holistic = mp.solutions.holistic.Holistic(
            static_image_mode=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        print("✅ MediaPipe Holistic initialized for word recognition")
        
        return True
        
    except Exception as e:
        print(f"❌ Error loading word model: {e}")
        return False

def preprocess_number_image(image_data):
    """Convert base64 image data to processed tensor for number recognition"""
    try:
        # Decode base64 image
        image_bytes = base64.b64decode(image_data)
        np_arr = np.frombuffer(image_bytes, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        
        if frame is None:
            return None, "Failed to decode image"
            
        # Flip horizontally (mirror effect like webcam)
        frame = cv2.flip(frame, 1)
        H, W, _ = frame.shape
        
        # Detect hands using static image mode
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = number_hands.process(frame_rgb)
        
        if not results.multi_hand_landmarks:
            return None, "No hand detected"
        
        # Find the largest hand bbox
        best_box = None
        best_area = -1
        for hand_landmarks in results.multi_hand_landmarks:
            xs = [lm.x for lm in hand_landmarks.landmark]
            ys = [lm.y for lm in hand_landmarks.landmark]
            x1 = int(min(xs) * W); y1 = int(min(ys) * H)
            x2 = int(max(xs) * W); y2 = int(max(ys) * H)
            bw = max(1, x2 - x1); bh = max(1, y2 - y1)
            area = bw * bh
            if area > best_area:
                best_area = area
                best_box = (x1, y1, x2, y2)

        if not best_box:
            return None, "No valid hand bounding box"

        x1, y1, x2, y2 = best_box
        
        # Create square crop with margin
        cx = (x1 + x2) // 2
        cy = (y1 + y2) // 2
        half = int(0.5 * max(x2-x1, y2-y1) * 1.2)  # 20% margin
        sx1 = max(0, cx - half); sy1 = max(0, cy - half)
        sx2 = min(W, cx + half); sy2 = min(H, cy + half)
        
        roi = frame[sy1:sy2, sx1:sx2]
        if roi.size == 0:
            return None, "Invalid crop region"
        
        # Preprocess for CNN model
        roi_rgb = cv2.cvtColor(roi, cv2.COLOR_BGR2RGB)
        roi_resz = cv2.resize(roi_rgb, IMG_SIZE, interpolation=cv2.INTER_AREA)
        roi_norm = roi_resz.astype("float32") / 255.0
        inp = np.expand_dims(roi_norm, axis=0)
        
        return inp, None
        
    except Exception as e:
        return None, f"Processing error: {str(e)}"

def extract_holistic_features(results, include_face=True):
    """Extract features from MediaPipe Holistic results for word recognition"""
    # Pose landmarks (33 points × 4 features: x, y, z, visibility)
    pose = results.pose_landmarks.landmark if results.pose_landmarks else []
    pose_feats = []
    for i in range(33):
        if i < len(pose):
            lm = pose[i]
            pose_feats.extend([lm.x, lm.y, lm.z, lm.visibility])
        else:
            pose_feats.extend([0.0, 0.0, 0.0, 0.0])

    # Face landmarks (468 points × 3 features: x, y, z)
    face = results.face_landmarks.landmark if results.face_landmarks else []
    face_feats = []
    for i in range(468):
        if i < len(face):
            lm = face[i]
            face_feats.extend([lm.x, lm.y, lm.z])
        else:
            face_feats.extend([0.0, 0.0, 0.0])

    # Hand landmarks (21 points × 3 features each hand)
    lh = results.left_hand_landmarks.landmark if results.left_hand_landmarks else []
    lh_feats = []
    for i in range(21):
        if i < len(lh):
            lm = lh[i]
            lh_feats.extend([lm.x, lm.y, lm.z])
        else:
            lh_feats.extend([0.0, 0.0, 0.0])

    rh = results.right_hand_landmarks.landmark if results.right_hand_landmarks else []
    rh_feats = []
    for i in range(21):
        if i < len(rh):
            lm = rh[i]
            rh_feats.extend([lm.x, lm.y, lm.z])
        else:
            rh_feats.extend([0.0, 0.0, 0.0])

    # Relative wrist-to-shoulder deltas (6 values)
    if results.pose_landmarks and len(pose) >= 17:
        ls = pose[11]  # Left shoulder
        rs = pose[12]  # Right shoulder
        lw = pose[15]  # Left wrist
        rw = pose[16]  # Right wrist
        
        lw_dx = lw.x - ls.x
        lw_dy = lw.y - ls.y
        lw_dz = lw.z - ls.z
        rw_dx = rw.x - rs.x
        rw_dy = rw.y - rs.y
        rw_dz = rw.z - rs.z
        rel_feats = [lw_dx, lw_dy, lw_dz, rw_dx, rw_dy, rw_dz]
    else:
        rel_feats = [0.0] * 6

    features = pose_feats + face_feats + lh_feats + rh_feats + rel_feats
    
    # Ensure correct dimension for the model (1668 features)
    expected_dim = 1668
    if len(features) < expected_dim:
        features.extend([0.0] * (expected_dim - len(features)))
    elif len(features) > expected_dim:
        features = features[:expected_dim]
    
    return np.array(features, dtype=np.float32)

def preprocess_word_image(image_data):
    """Convert base64 image data to processed features for word recognition"""
    try:
        # Decode base64 image
        image_bytes = base64.b64decode(image_data)
        np_arr = np.frombuffer(image_bytes, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        
        if frame is None:
            return None, "Failed to decode image"
            
        # Flip horizontally (mirror effect like webcam)
        frame = cv2.flip(frame, 1)
        
        # Process with MediaPipe Holistic
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = word_holistic.process(frame_rgb)
        
        # Extract features
        features = extract_holistic_features(results)
        
        # Reshape for LSTM model: (1, 30, 1668) - single frame as sequence
        # For real-time, you'd collect multiple frames, but for single image we use one frame repeated
        sequence = np.stack([features] * 30, axis=0)  # Repeat single frame 30 times
        sequence = np.expand_dims(sequence, axis=0)   # Add batch dimension
        
        return sequence, None
        
    except Exception as e:
        return None, f"Word processing error: {str(e)}"

# =============================================================================
# ROUTES
# =============================================================================

@touch_routes.route('/hands', methods=['POST'])
def recognize_gesture():
    """Original gesture recognition endpoint"""
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
        results = gesture_hands.process(frame_rgb)

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
            prediction = gesture_model.predict([np.asarray(data_aux)])
            predicted_character = labels_dict[int(prediction[0])]

            return jsonify({
                "status": "success",
                "predicted_character": predicted_character,
                "bounding_box": [x1, y1, x2, y2]
            })
        else:
            return jsonify({"status": "error", "message": "No hand detected"}), 404

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@touch_routes.route('/number', methods=['POST'])
def predict_number():
    """Number recognition endpoint"""
    
    try:
        # Check if model is loaded
        if number_model is None:
            return jsonify({
                'success': False,
                'error': 'Number model not loaded',
                'prediction': None,
                'confidence': 0.0
            }), 500
        
        # Get image data from request
        data = request.get_json()
        if not data or 'image' not in data:
            return jsonify({
                'success': False,
                'error': 'No image data provided',
                'prediction': None,
                'confidence': 0.0
            }), 400
        
        # Preprocess image
        processed_image, error_msg = preprocess_number_image(data['image'])
        if error_msg:
            return jsonify({
                'success': False,
                'error': error_msg,
                'prediction': None,
                'confidence': 0.0
            }), 400
        
        # Make prediction
        probs = number_model.predict(processed_image, verbose=0)[0]
        idx = int(np.argmax(probs))
        confidence = float(np.max(probs))
        prediction = number_labels[idx] if idx < len(number_labels) else str(idx)
        
        # Apply confidence threshold
        final_prediction = None
        if confidence >= CONF_THRESH:
            final_prediction = prediction
        
        return jsonify({
            'success': True,
            'error': None,
            'prediction': final_prediction,
            'confidence': confidence,
            'raw_prediction': prediction
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Prediction error: {str(e)}',
            'prediction': None,
            'confidence': 0.0
        }), 500

@touch_routes.route('/word', methods=['POST'])
def predict_word():
    """Word recognition endpoint"""
    
    try:
        # Check if model is loaded
        if word_model is None:
            return jsonify({
                'success': False,
                'error': 'Word model not loaded',
                'prediction': None,
                'confidence': 0.0
            }), 500
        
        # Get image data from request
        data = request.get_json()
        if not data or 'image' not in data:
            return jsonify({
                'success': False,
                'error': 'No image data provided',
                'prediction': None,
                'confidence': 0.0
            }), 400
        
        # Preprocess image for word recognition
        processed_sequence, error_msg = preprocess_word_image(data['image'])
        if error_msg:
            return jsonify({
                'success': False,
                'error': error_msg,
                'prediction': None,
                'confidence': 0.0
            }), 400
        
        # Make prediction
        probs = word_model.predict(processed_sequence, verbose=0)[0]
        idx = int(np.argmax(probs))
        confidence = float(np.max(probs))
        prediction = word_labels[idx] if idx < len(word_labels) else str(idx)
        
        # Apply confidence threshold
        final_prediction = None
        if confidence >= CONF_THRESH:
            final_prediction = prediction
        
        return jsonify({
            'success': True,
            'error': None,
            'prediction': final_prediction,
            'confidence': confidence,
            'raw_prediction': prediction
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': f'Word prediction error: {str(e)}',
            'prediction': None,
            'confidence': 0.0
        }), 500

@touch_routes.route('/number/health', methods=['GET'])
def number_health_check():
    """Health check endpoint for number recognition"""
    model_status = "loaded" if number_model is not None else "not loaded"
    labels_status = f"loaded ({len(number_labels)} labels)" if number_labels else "not loaded"
    
    return jsonify({
        'status': 'healthy',
        'model': model_status,
        'labels': labels_status,
        'mode': 'static_image'
    })

@touch_routes.route('/word/health', methods=['GET'])
def word_health_check():
    """Health check endpoint for word recognition"""
    model_status = "loaded" if word_model is not None else "not loaded"
    labels_status = f"loaded ({len(word_labels)} labels)" if word_labels else "not loaded"
    
    return jsonify({
        'status': 'healthy',
        'model': model_status,
        'labels': labels_status,
        'mode': 'holistic_sequence'
    })

@touch_routes.route('/number/info', methods=['GET'])
def number_model_info():
    """Get number model information"""
    if number_model is None:
        return jsonify({'error': 'Number model not loaded'}), 400
    
    return jsonify({
        'model_name': 'number.keras',
        'input_shape': number_model.input_shape,
        'output_shape': number_model.output_shape,
        'labels': number_labels,
        'config': {
            'image_size': IMG_SIZE,
            'confidence_threshold': CONF_THRESH,
            'mediapipe_mode': 'static_image'
        }
    })

@touch_routes.route('/word/info', methods=['GET'])
def word_model_info():
    """Get word model information"""
    if word_model is None:
        return jsonify({'error': 'Word model not loaded'}), 400
    
    return jsonify({
        'model_name': 'word98.h5',
        'input_shape': word_model.input_shape,
        'output_shape': word_model.output_shape,
        'labels': word_labels,
        'config': {
            'feature_dim': 1668,
            'sequence_length': 30,
            'confidence_threshold': CONF_THRESH,
            'mediapipe_mode': 'holistic'
        }
    })

@touch_routes.route('/gesture/info', methods=['GET'])
def gesture_model_info():
    """Get gesture model information"""
    return jsonify({
        'model_name': 'model.p',
        'labels': labels_dict,
        'model_type': 'Traditional ML',
        'mediapipe_mode': 'static_image'
    })

# =============================================================================
# INITIALIZATION
# =============================================================================

def create_touch_routes(app):
    """Register the blueprint and initialize models"""
    app.register_blueprint(touch_routes, url_prefix='/gesture')
    
    # Initialize models when routes are created
    print("🚀 Initializing Touch Routes...")
    load_number_model()
    load_word_model()

# Initialize models when module is imported
print("🔧 Initializing Touch Module...")