from flask import Flask
from flask_cors import CORS
from routes.gesture_routes import create_gesture_routes
from routes.touch import create_touch_routes

def create_app():
    app = Flask(__name__)
    CORS(app)  # Allow cross-origin requests (useful for Flutter/React clients)

    # Register blueprints
    create_gesture_routes(app)
    create_touch_routes(app)

    # Root route for health check
    @app.route("/")
    def home():
        return "Gesture API is running. Use POST /gesture/detect"

    # Print URL map on startup to verify registered endpoints
    print("=== URL MAP ===")
    print(app.url_map)

    return app


app = create_app()

if __name__ == "__main__":
    # Run the server
    app.run(debug=True, host="0.0.0.0", port=5000)