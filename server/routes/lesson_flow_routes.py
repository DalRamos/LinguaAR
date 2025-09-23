from bson import ObjectId
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from pymongo import MongoClient
import jwt
import datetime
import re
from routes.otp import otp_storage

# Blueprint definition
lesson_bp = Blueprint('lesson_flow', __name__)

# Connect to MongoDB
client = MongoClient("mongodb+srv://LinguaAR:LinguaAR_password@cluster0.a4rwe.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0")
db = client['LinguaAR_db']
lessonfow_collection = db.lessonfow



def create_lesson_flow(app):
    app.register_blueprint(lesson_bp, url_prefix='/lessonflow')