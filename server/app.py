# server/app.py
import os
from flask import Flask, jsonify
from flask_cors import CORS

# Feature flags so we don't import heavy deps by default
ENABLE_GESTURE = os.environ.get("ENABLE_GESTURE", "0") == "1"
ENABLE_SPEECH  = os.environ.get("ENABLE_SPEECH",  "0") == "1"

def create_app():
    app = Flask(__name__)

    # Secrets / config from env
    app.config["79e026c5eaee509133e45e5004d457b0500cbbdc62c50b5f539497fdbd14e0d3"] = os.environ.get("JWT_SECRET", "dev_secret_only_for_local")

    # CORS allow-list (set CORS_ALLOWED_ORIGINS="https://your-site.com,http://localhost:5173")
    allowed = [o.strip() for o in os.environ.get("CORS_ALLOWED_ORIGINS", "").split(",") if o.strip()]
    CORS(app, origins=allowed or "*", supports_credentials=True)

    # ---- Register lightweight routes (always on) ----
    from routes.auth_routes import create_auth_routes
    from routes.videos_routes import create_cloudinary_routes
    from routes.otp import create_otp_routes
    from routes.favotites import create_favorites_routes  # file should be favorites.py

    create_auth_routes(app)
    create_cloudinary_routes(app)
    create_otp_routes(app)
    create_favorites_routes(app)

    # ---- Conditionally register heavy routes ----
    if ENABLE_GESTURE:
        from routes.gesture_routes import create_gesture_routes
        create_gesture_routes(app)

    if ENABLE_SPEECH:
        from routes.speech_recognition_routes import create_speech_recognition_routes
        create_speech_recognition_routes(app)

    # ---- Health & error handlers ----
    @app.get("/")
    def health():
        return {
            "status": "ok",
            "service": "api",
            "ml_enabled": {"gesture": ENABLE_GESTURE, "speech": ENABLE_SPEECH}
        }

    @app.errorhandler(404)
    def not_found(_):
        return jsonify(error="Not Found"), 404

    @app.errorhandler(500)
    def server_error(e):
        # Avoid leaking internals; logs will still capture traceback
        return jsonify(error="Internal Server Error"), 500

    return app

# Gunicorn entrypoint
app = create_app()

if __name__ == "__main__":
    # Local dev only; Render/Gunicorn will ignore this
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 5000)))