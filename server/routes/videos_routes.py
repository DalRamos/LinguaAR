from flask import Blueprint, jsonify, request
import cloudinary
import cloudinary.uploader
from cloudinary.utils import cloudinary_url
from flask_cors import CORS

# Initialize the Blueprint for Cloudinary routes
cloudinary_routes = Blueprint('cloudinary_routes', __name__)

# Cloudinary configuration
cloudinary.config(
    cloud_name="dqthtm7gt",
    api_key="162623391494816",
    api_secret="2ZtUY-4-IK4IWMHZUVJWd6veqUY",  # Replace with your actual API secret
    secure=True
)

# Enable CORS for these route
CORS(cloudinary_routes)

@cloudinary_routes.route('/get_gif', methods=['GET'])
def get_gif():
    public_id = request.args.get('public_id')
    url = request.args.get('url')

    if public_id:
        # Generate Cloudinary URL for existing public_id
        gif_url, _ = cloudinary_url(public_id, fetch_format="gif", quality="auto")

        if not gif_url:
            return jsonify({"status": "error", "message": "Invalid public_id or file not found"}), 404

        return jsonify({"status": "success", "gif_url": gif_url})

    if url:
        try:
            # Upload the image from the URL and return its secure URL
            upload_result = cloudinary.uploader.upload(url, resource_type="image", fetch_format="gif")
            return jsonify({"status": "success", "gif_url": upload_result["secure_url"]})
        except Exception as e:
            return jsonify({"status": "error", "message": str(e)}), 500

    return jsonify({"status": "error", "message": "Please provide either 'public_id' or 'url'"}), 400

def create_cloudinary_routes(app):
    app.register_blueprint(cloudinary_routes, url_prefix='/cloudinary')