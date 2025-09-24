from flask import Blueprint, request, jsonify
from pymongo import MongoClient
from bson import ObjectId
import datetime

# Create blueprint
lesson_bp = Blueprint("lesson", __name__)

# Connect to MongoDB
client = MongoClient("mongodb+srv://LinguaAR:LinguaAR_password@cluster0.a4rwe.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
db = client['LinguaAR_db']

# 🔹 Define the collection
lessonfow_collection = db["lessonfow"]

# ✅ Check lesson completion - FIXED VERSION
@lesson_bp.route("/lessons/status", methods=["GET"])
def check_completion():
    try:
        user_id = request.args.get('userId')
        category = request.args.get('category')
        
        if not user_id or not category:
            return jsonify({"error": "Missing userId or category"}), 400

        print(f"🔍 Checking completion for user: {user_id}, category: {category}")  # Debug log

        # Fix: Use proper ObjectId conversion
        completion = lessonfow_collection.find_one({
            "userId": ObjectId(user_id),
            "category": category
        })

        print(f"📊 MongoDB result: {completion}")  # Debug log
        
        # Return the actual completion status from database
        if completion:
            return jsonify({
                "completed": True,
                "completedAt": completion.get('completedAt').isoformat() if completion.get('completedAt') else None,
                "message": "Lesson completed"
            })
        else:
            return jsonify({
                "completed": False,
                "message": "Lesson not completed"
            })
            
    except Exception as e:
        print(f"❌ Error in check_completion: {e}")  # Debug log
        return jsonify({"error": str(e)}), 500

# ✅ Save lesson completion - FIXED VERSION
@lesson_bp.route("/lessons/complete", methods=["POST"])
def complete_lesson():
    data = request.get_json()
    user_id = data.get("userId")
    category = data.get("category")

    if not user_id or not category:
        return jsonify({"error": "Missing userId or category"}), 400

    try:
        print(f"💾 Completing lesson for user: {user_id}, category: {category}")  # Debug log

        # Check if lesson already completed
        existing = lessonfow_collection.find_one({
            "userId": ObjectId(user_id),
            "category": category
        })

        if existing:
            print("✅ Lesson already completed")  # Debug log
            return jsonify({
                "message": "Already completed", 
                "completed": True
            }), 200

        # Insert new completion record
        result = lessonfow_collection.insert_one({
            "userId": ObjectId(user_id),
            "category": category,
            "completedAt": datetime.datetime.utcnow(),
            "completed": True  # Explicitly set completed to True
        })

        print(f"✅ Lesson completion saved with ID: {result.inserted_id}")  # Debug log

        return jsonify({
            "message": "Lesson completion saved", 
            "completed": True
        }), 201
        
    except Exception as e:
        print(f"❌ Error in complete_lesson: {e}")  # Debug log
        return jsonify({"error": str(e)}), 500

def create_lesson_flow_routes(app):
    app.register_blueprint(lesson_bp, url_prefix='/lessonflow')