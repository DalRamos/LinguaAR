from bson import ObjectId
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from pymongo import MongoClient
import jwt
import datetime
import re
from routes.otp import otp_storage

# Blueprint definition
auth_bp = Blueprint('auth', __name__)

# Connect to MongoDB
client = MongoClient("mongodb+srv://LinguaAR:LinguaAR_password@cluster0.a4rwe.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
db = client['LinguaAR_db']
users_collection = db.users

def is_valid_password(password):
    """
    Validate password:
    - At least 1 uppercase letter
    - At least 1 number
    - At least 1 special character
    - Minimum 8 characters, maximum 12 characters
    """
    if len(password) < 8 or len(password) > 12:
        return False
    if not re.search(r'[A-Z]', password):
        return False
    if not re.search(r'[0-9]', password):
        return False
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False
    return True

# Register Route
@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    # Validate email and password
    if not email or not password:
        return jsonify({'message': 'Email and password are required'}), 400

    # Check if the email already exists in the database
    if users_collection.find_one({'email': email}):
        return jsonify({'message': 'User already exists'}), 400

    # Validate password requirements
    if not is_valid_password(password):
        return jsonify({'message': 'Password must contain at least 1 uppercase letter, 1 number, 1 special character, and be 8-12 characters long'}), 400

    # Hash the password and save the user
    hashed_password = generate_password_hash(password, method='pbkdf2:sha256')
    users_collection.insert_one({
        'email': email, 
        'password': hashed_password,
        'disability': None,  # Set to None initially
        'has_set_disability': False  # Mark as first-time user
    })
    return jsonify({'message': 'User registered successfully'}), 201

# Login Route
@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'message': 'Email and password are required'}), 400

    user = users_collection.find_one({'email': email})
    if not user or not check_password_hash(user['password'], password):
        return jsonify({'message': 'Invalid email or password'}), 400
    
    disability = user.get('disability', None)


    # ✅ Fix: Include _id in JWT payload
    token = jwt.encode({
        '_id': str(user['_id']),  
        'email': email,
        'disability': disability,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    }, '79e026c5eaee509133e45e5004d457b0500cbbdc62c50b5f539497fdbd14e0d3', algorithm='HS256')

    return jsonify({
    'message': 'Login successful',
    'token': token,
    'email': email,
    'disability': disability
}), 200
# Reset Password Route
@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')
    new_password = data.get('new_password')

    # Validate input
    if not email or not otp or not new_password:
        return jsonify({'message': 'Email, OTP, and new password are required'}), 400

    # Verify OTP (imported from otp.py)
    stored_otp = otp_storage.get(email)
    if not stored_otp or stored_otp != otp:
        return jsonify({'message': 'Invalid OTP'}), 400

    # Validate new password
    if not is_valid_password(new_password):
        return jsonify({'message': 'Password must contain at least 1 uppercase letter, 1 number, 1 special character, and be 8-12 characters long'}), 400

    # Hash the new password and update the user's password in the database
    hashed_password = generate_password_hash(new_password, method='pbkdf2:sha256')
    users_collection.update_one({'email': email}, {'$set': {'password': hashed_password}})

    # Clear the OTP from storage after successful reset
    otp_storage.pop(email, None)

    return jsonify({'message': 'Password reset successfully'}), 200

@auth_bp.route('/reset-email', methods=['POST'])
def reset_email():
    data = request.get_json()
    email = data.get('email')
    otp = data.get('otp')
    new_email = data.get('new_email')

    # Validate input
    if not email or not otp or not new_email:
        return jsonify({'message': 'Email, OTP, and new password are required'}), 400

    # Verify OTP (imported from otp.py)
    stored_otp = otp_storage.get(email)
    if not stored_otp or stored_otp != otp:
        return jsonify({'message': 'Invalid OTP'}), 400

    if not email.endswith('@gmail.com'):
        return jsonify({'message': 'Only Gmail accounts are allowed'}), 400

    # Clear the OTP from storage after successful reset
    otp_storage.pop(email, None)

    return jsonify({'message': 'email change successfully'}), 200


@auth_bp.route('/update-disability', methods=['POST'])
def update_disability():
    data = request.get_json()
    token = request.headers.get('Authorization')
    new_disability = data.get('disability')  # Can be None
    
    # Validate input
    if not token:
        return jsonify({'message': 'Authorization token is required'}), 401
    
    try:
        # Verify JWT token
        decoded = jwt.decode(
            token.split()[1],  # Remove 'Bearer ' prefix
            '79e026c5eaee509133e45e5004d457b0500cbbdc62c50b5f539497fdbd14e0d3',
            algorithms=['HS256']
        )
        
        user_id = decoded['_id']
        
        # Update disability in database
        result = users_collection.update_one(
            {'_id': ObjectId(user_id)},
            {'$set': {'disability': new_disability}}
        )
        
        if result.modified_count == 1:
            return jsonify({
                'message': 'Disability updated successfully',
                'disability': new_disability
            }), 200
        else:
            return jsonify({'message': 'User not found or no changes made'}), 404
            
    except jwt.ExpiredSignatureError:
        return jsonify({'message': 'Token has expired'}), 401
    except jwt.InvalidTokenError:
        return jsonify({'message': 'Invalid token'}), 401
    except Exception as e:
        return jsonify({'message': f'Error updating disability: {str(e)}'}), 500



# Function to register routes with the app
def create_auth_routes(app):
    app.register_blueprint(auth_bp, url_prefix='/auth')