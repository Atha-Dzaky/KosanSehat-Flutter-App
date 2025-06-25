# app/models.py (100% LENGKAP DENGAN SEMUA KOLOM)

from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import json
from datetime import datetime

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'user'

    id = db.Column(db.Integer, primary_key=True)
    nama = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    setup_completed = db.Column(db.Boolean, default=False)
    
    gender = db.Column(db.String(10), nullable=True)
    weight = db.Column(db.Float, nullable=True)
    height = db.Column(db.Float, nullable=True)
    age = db.Column(db.Integer, nullable=True)
    activity_level = db.Column(db.String(50), nullable=True)
    
    target_calories = db.Column(db.Float, nullable=True)
    daily_budget = db.Column(db.Float, nullable=True)
    monthly_budget = db.Column(db.Float, nullable=True)
    preferences = db.Column(db.Text, nullable=True) 
    allergies = db.Column(db.Text, nullable=True)

    reviews = db.relationship('Review', backref='author', lazy='dynamic')
    expenses = db.relationship('Expense', backref='author', lazy='dynamic')
    meal_plans = db.relationship('MealPlan', backref='user', lazy='dynamic')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password, method='pbkdf2:sha256:600000')

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            'id': self.id,
            'nama': self.nama,
            'email': self.email,
            'setup_completed': self.setup_completed,
            'gender': self.gender,
            'weight': self.weight,
            'height': self.height,
            'age': self.age,
            'activity_level': self.activity_level,
            'target_calories': self.target_calories,
            'daily_budget': self.daily_budget,
            'monthly_budget': self.monthly_budget,
            'preferences': json.loads(self.preferences) if self.preferences else [],
            'allergies': json.loads(self.allergies) if self.allergies else [],
        }

class Review(db.Model):
    __tablename__ = 'review'
    id = db.Column(db.Integer, primary_key=True)
    menu_name = db.Column(db.String(150), nullable=False, index=True)
    rating = db.Column(db.Float, nullable=False)
    review_text = db.Column(db.Text, nullable=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)

class Expense(db.Model):
    __tablename__ = 'expense'
    id = db.Column(db.Integer, primary_key=True)
    amount = db.Column(db.Float, nullable=False)
    description = db.Column(db.String(200), nullable=False)
    timestamp = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    plan_details = db.Column(db.Text, nullable=True)

class MealPlan(db.Model):
    __tablename__ = 'meal_plan'
    id = db.Column(db.Integer, primary_key=True)
    plan_date = db.Column(db.Date, nullable=False, index=True)
    plan_data = db.Column(db.Text, nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, index=True)