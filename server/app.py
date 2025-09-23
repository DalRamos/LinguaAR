from flask import Flask
from routes.auth_routes import create_auth_routes
from routes.gesture_routes import create_gesture_routes
from routes.speech_recognition_routes import create_speech_recognition_routes
from routes.videos_routes import create_cloudinary_routes
from flask_cors import CORS
from routes.otp import create_otp_routes
from routes.touch import create_touch_routes
from routes.favotites import create_favorites_routes
from routes.lesson_flow_routes import create_lesson_flow_routes

def create_app():
    app = Flask(__name__)


    app.config['SECRET_KEY'] = '79e026c5eaee509133e45e5004d457b0500cbbdc62c50b5f539497fdbd14e0d3'

    # Register routes
    create_auth_routes(app)
    create_gesture_routes(app)
    create_speech_recognition_routes(app)  
    create_cloudinary_routes(app)
    create_otp_routes(app)
    create_touch_routes(app)
    create_favorites_routes(app)




    return app

app = create_app()
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)