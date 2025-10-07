from bson import ObjectId
from flask import Blueprint, request, jsonify
import jwt
from pymongo import MongoClient
from functools import wraps

# Blueprint definition
disability_bp = Blueprint('disability', __name__)

# Connect to MongoDB (use the same connection as auth_routes)
client = MongoClient("mongodb+srv://LinguaAR:LinguaAR_password@cluster0.a4rwe.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
db = client['LinguaAR_db']
users_collection = db.users

# Token verification decorator
def token_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        token = request.headers.get('Authorization')
        
        if not token:
            return jsonify({'message': 'Token is missing'}), 401
        
        try:
            token = token.replace('Bearer ', '')
            decoded = jwt.decode(
                token, 
                '79e026c5eaee509133e45e5004d457b0500cbbdc62c50b5f539497fdbd14e0d3',
                algorithms=['HS256']
            )
            current_user = users_collection.find_one({'_id': ObjectId(decoded['_id'])})
            if not current_user:
                return jsonify({'message': 'User not found'}), 404
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Invalid token'}), 401
        except Exception as e:
            return jsonify({'message': f'Token error: {str(e)}'}), 401
            
        return f(current_user, *args, **kwargs)
    return decorated_function

# Set disability endpoint
@disability_bp.route('/set', methods=['POST'])
@token_required
def set_disability(current_user):
    data = request.get_json()
    disability = data.get('disability')
    
    # Update user's disability and mark as set
    users_collection.update_one(
        {'_id': current_user['_id']},
        {'$set': {
            'disability': disability, 
            'has_set_disability': True
        }}
    )
    
    return jsonify({
        'message': 'Disability set successfully',
        'disability': disability
    }), 200

# Get disability endpoint
@disability_bp.route('/get', methods=['GET'])
@token_required
def get_disability(current_user):
    disability = current_user.get('disability')
    has_set_disability = current_user.get('has_set_disability', False)
    
    return jsonify({
        'disability': disability,
        'has_set_disability': has_set_disability
    }), 200

# Check first time endpoint
@disability_bp.route('/check-first-time', methods=['GET'])
@token_required
def check_first_time(current_user):
    has_set_disability = current_user.get('has_set_disability', False)
    
    return jsonify({
        'is_first_time': not has_set_disability,
        'has_set_disability': has_set_disability
    }), 200

# Get disability options endpoint
@disability_bp.route('/options', methods=['GET'])
def get_disability_options():
    options = [
        {'value': 'none', 'label': 'None'},
        {'value': 'deaf', 'label': 'Deaf'},
        {'value': 'hard_of_hearing', 'label': 'Hard of Hearing'},
        {'value': 'mute', 'label': 'Mute'},
        {'value': 'speech_impaired', 'label': 'Speech Impaired'},
        {'value': 'other', 'label': 'Other'}
    ]
    
    return jsonify({'options': options}), 200

# Update disability endpoint
@disability_bp.route('/update', methods=['POST'])
@token_required
def update_disability(current_user):
    data = request.get_json()
    disability = data.get('disability')
    
    users_collection.update_one(
        {'_id': current_user['_id']},
        {'$set': {
            'disability': disability,
            'has_set_disability': True
        }}
    )
    
    return jsonify({
        'message': 'Disability updated successfully',
        'disability': disability
    }), 200

# Function to register routes with the app
def create_disability_routes(app):
    app.register_blueprint(disability_bp, url_prefix='/api/disability')