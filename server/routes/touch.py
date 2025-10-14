from flask import Blueprint, jsonify, request
import os
import pickle
import cv2
import mediapipe as mp
import numpy as np
import json
import tensorflow as tf
from tensorflow import keras

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

# Load number model and labels
number_model = None
number_labels = []

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

# Initialize MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=True, min_detection_confidence=0.3)

# Labels for alphabet gesture recognition
labels_dict = {
    0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J',
    10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S',
    19: 'T', 20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z'
}

@touch_routes.route('/hands', methods=['POST'])
def recognize_gesture():
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
                "bounding_box": [x1, y1, x2, y2]
            })
        else:
            return jsonify({"status": "error", "message": "No hand detected"}), 404

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@touch_routes.route('/numbers', methods=['POST'])
def recognize_numbers():
    """
    New endpoint for number recognition using the static CNN model approach
    """
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

        # Use MediaPipe Hands for hand detection and cropping (from hybrid.py)
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
            "message": "Number recognized successfully"
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

def detect_and_crop_hand(frame, min_detection_confidence=0.5):
    """
    Detect hand using MediaPipe and crop the hand region with margin
    This is adapted from the hybrid.py realtime_webcam_static_only function
    """
    try:
        import mediapipe as mp
    except ImportError:
        return False, None

    # Tunables from hybrid.py
    MARGIN_FRAC = 0.35  # extra margin around the hand bbox
    MIN_PIX = 80        # minimum bbox size in pixels
    
    mp_hands = mp.solutions.hands
    hands = mp_hands.Hands(
        static_image_mode=True,  # Use static mode for single image
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
    """
    Preprocess the cropped hand image for the number model
    This matches the preprocessing in hybrid.py
    """
    # Convert BGR to RGB
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    
    # Resize to match model input size
    image_resized = cv2.resize(image_rgb, img_size, interpolation=cv2.INTER_AREA)
    
    # Normalize pixel values
    image_normalized = image_resized.astype("float32") / 255.0
    
    # Add batch dimension
    image_batch = np.expand_dims(image_normalized, axis=0)
    
    return image_batch

@touch_routes.route('/words', methods=['POST'])
def recognize_words():
    """
    Placeholder endpoint for word recognition
    You can implement this later when you have a word model
    """
    return jsonify({
        "status": "info", 
        "message": "Word recognition endpoint - to be implemented"
    }), 501

def create_touch_routes(app):
    app.register_blueprint(touch_routes, url_prefix='/gesture')