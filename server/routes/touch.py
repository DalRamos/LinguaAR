from flask import Blueprint, jsonify, request
import cv2
import mediapipe as mp
import numpy as np
import pickle
import os
import threading
from collections import deque, Counter
import time

# Initialize Blueprint
touch_routes = Blueprint('touch_routes', __name__)

# Load gesture recognition model
script_dir = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(script_dir, '..', 'Model', 'model.p')

try:
    model_dict = pickle.load(open(model_path, 'rb'))
    model = model_dict['model']
    print("✅ Gesture recognition model loaded successfully")
except Exception as e:
    print(f"❌ Error loading model: {e}")
    model = None

# Initialize MediaPipe with optimized settings for speed
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=1,
    min_detection_confidence=0.6,  # Slightly lower for faster detection
    min_tracking_confidence=0.4    # Lower for faster tracking
)

# Labels for gesture recognition
labels_dict = {
    0: 'A', 1: 'B', 2: 'C', 3: 'D', 4: 'E', 5: 'F', 6: 'G', 7: 'H', 8: 'I', 9: 'J',
    10: 'K', 11: 'L', 12: 'M', 13: 'N', 14: 'O', 15: 'P', 16: 'Q', 17: 'R', 18: 'S',
    19: 'T', 20: 'U', 21: 'V', 22: 'W', 23: 'X', 24: 'Y', 25: 'Z'
}

# Global variables for streaming
stream_clients = {}
stream_lock = threading.Lock()

class StreamClient:
    def __init__(self):
        self.prediction_buffer = deque(maxlen=2)  # Smaller buffer for faster response
        self.last_prediction = ""
        self.confidence = 0.0
        self.active = True
        self.last_active = time.time()
        self.frame_count = 0

def process_frame_ultra_fast(frame):
    """ULTRA FAST frame processing - optimized for maximum speed"""
    if model is None:
        return {
            "predicted_character": "",
            "confidence": 0.0,
            "hand_detected": False
        }

    data_aux = []
    x_ = []
    y_ = []

    # FAST RGB conversion
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(frame_rgb)

    if results.multi_hand_landmarks:
        hand_landmarks = results.multi_hand_landmarks[0]
        landmarks = hand_landmarks.landmark
        
        # Fast landmark extraction
        for i in range(len(landmarks)):
            x = landmarks[i].x
            y = landmarks[i].y
            x_.append(x)
            y_.append(landmarks[i].y)

        min_x, max_x = min(x_), max(x_)
        min_y, max_y = min(y_), max(y_)

        # Fast normalization
        for i in range(len(landmarks)):
            data_aux.append(landmarks[i].x - min_x)
            data_aux.append(landmarks[i].y - min_y)

        if len(data_aux) == 42:
            try:
                # Get probabilities for all classes
                prediction_proba = model.predict_proba([np.asarray(data_aux)])[0]
                
                # Find the highest probability and its index
                max_prob_index = np.argmax(prediction_proba)
                max_prob = prediction_proba[max_prob_index]
                
                # Only return if confidence is high enough
                if max_prob > 0.6:  # Threshold for reliable prediction
                    predicted_character = labels_dict[max_prob_index]
                    
                    return {
                        "predicted_character": predicted_character,
                        "confidence": max_prob,
                        "hand_detected": True
                    }
                else:
                    return {
                        "predicted_character": "",
                        "confidence": max_prob,
                        "hand_detected": True
                    }
                    
            except Exception:
                pass

    return {
        "predicted_character": "",
        "confidence": 0.0,
        "hand_detected": False
    }

# Streaming endpoints - OPTIMIZED FOR SPEED
@touch_routes.route('/stream/start', methods=['POST'])
def start_stream():
    """Start a new streaming session"""
    try:
        data = request.get_json()
        client_id = data.get('client_id', f'client_{int(time.time())}')
        
        with stream_lock:
            stream_clients[client_id] = StreamClient()
        
        return jsonify({
            "status": "success", 
            "client_id": client_id,
            "message": "Stream started successfully"
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@touch_routes.route('/stream/frame/<client_id>', methods=['POST'])
def stream_frame(client_id):
    """ULTRA FAST frame processing for streaming"""
    start_time = time.time()
    
    if client_id not in stream_clients:
        return jsonify({"status": "error", "message": "Client not found"}), 404

    try:
        if 'frame' not in request.files:
            return jsonify({"status": "error", "message": "No frame data"}), 400

        file = request.files['frame']
        file_bytes = np.frombuffer(file.read(), np.uint8)
        frame = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

        if frame is None:
            return jsonify({"status": "error", "message": "Invalid frame data"}), 400

        client = stream_clients[client_id]
        client.frame_count += 1
        client.last_active = time.time()
        
        # ULTRA FAST processing
        prediction_data = process_frame_ultra_fast(frame)
        
        # Fast buffer update with highest probability character
        if prediction_data["hand_detected"] and prediction_data["predicted_character"]:
            # Only add to buffer if confidence is high
            if prediction_data["confidence"] > 0.7:
                client.prediction_buffer.append(prediction_data["predicted_character"])
            
            # Use the latest high-confidence prediction (faster than majority voting)
            if client.prediction_buffer:
                client.last_prediction = client.prediction_buffer[-1]
                client.confidence = prediction_data["confidence"]
        else:
            # Fast clear
            client.last_prediction = ""
            client.confidence = 0.0

        response_data = {
            "status": "success",
            "predicted_character": client.last_prediction,
            "confidence": client.confidence,
            "hand_detected": prediction_data["hand_detected"],
            "processing_time": round(time.time() - start_time, 3)
        }

        return jsonify(response_data)

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@touch_routes.route('/stream/stop/<client_id>', methods=['POST'])
def stop_stream(client_id):
    """Stop streaming session"""
    try:
        with stream_lock:
            if client_id in stream_clients:
                del stream_clients[client_id]
            else:
                return jsonify({"status": "error", "message": "Client not found"}), 404
        
        return jsonify({
            "status": "success", 
            "message": "Stream stopped"
        })
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

@touch_routes.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        "status": "success",
        "service": "gesture-recognition",
        "model_loaded": model is not None,
        "stream_clients": len(stream_clients),
        "timestamp": time.time()
    })

# Cleanup inactive clients
def cleanup_clients():
    """Background thread to clean up inactive clients"""
    while True:
        time.sleep(30)
        current_time = time.time()
        
        with stream_lock:
            inactive_clients = [
                client_id for client_id, client in stream_clients.items()
                if current_time - client.last_active > 60
            ]
            for client_id in inactive_clients:
                del stream_clients[client_id]

# Start cleanup thread
cleanup_thread = threading.Thread(target=cleanup_clients, daemon=True)
cleanup_thread.start()

def create_touch_routes(app):
    app.register_blueprint(touch_routes, url_prefix='/gesture')