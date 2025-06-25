# app/routes/auth_routes.py

from flask import Blueprint, request, jsonify
from app.models import db, User
import uuid
import json

def create_auth_blueprint():
    auth_bp = Blueprint('auth_bp', __name__)

    @auth_bp.route('/register', methods=['POST'])
    def register_user():
        data = request.json; email = data.get('email'); password = data.get('password'); nama_pengguna = data.get('nama', '') 
        if not email or not password: return jsonify({'status': 'error', 'message': 'Email dan password dibutuhkan'}), 400
        if User.query.filter_by(email=email).first(): return jsonify({'status': 'error', 'message': 'Email sudah terdaftar'}), 400
        new_user = User(email=email, nama=nama_pengguna); new_user.set_password(password)
        db.session.add(new_user); db.session.commit()
        return jsonify({'status': 'success', 'message': 'Registrasi berhasil'}), 201

    @auth_bp.route('/login', methods=['POST'])
    def login_user():
        data = request.json; email = data.get('email'); password = data.get('password')
        if not email or not password: return jsonify({'status': 'error', 'message': 'Email dan password dibutuhkan'}), 400
        user = User.query.filter_by(email=email).first()
        if not user or not user.check_password(password): return jsonify({'status': 'error', 'message': 'Email atau password salah'}), 401
        token = str(uuid.uuid4())
        return jsonify({'status': 'success', 'message': 'Login berhasil!', 'token': token, 'user': user.to_dict()}), 200

    @auth_bp.route('/update-profile', methods=['POST'])
    def update_profile():
        data = request.json
        email = data.get('email')
        if not email: return jsonify({'status': 'error', 'message': 'Email dibutuhkan'}), 400
        user = User.query.filter_by(email=email).first()
        if not user: return jsonify({'status': 'error', 'message': 'Pengguna tidak ditemukan'}), 404
        
        if 'nama' in data: user.nama = data['nama']
        if 'gender' in data: user.gender = data['gender']
        if 'weight' in data: user.weight = data['weight']
        if 'height' in data: user.height = data['height']
        if 'age' in data: user.age = data['age']
        if 'activity_level' in data: user.activity_level = data['activity_level']
        if 'setup_completed' in data: user.setup_completed = data['setup_completed']
        if 'daily_budget' in data: user.daily_budget = data['daily_budget']
        if 'monthly_budget' in data: user.monthly_budget = data['monthly_budget']
        if 'preferences' in data: user.preferences = json.dumps(data['preferences'])
        if 'allergies' in data: user.allergies = json.dumps(data['allergies'])

        if all([user.gender, user.weight, user.height, user.age, user.activity_level]):
            bmr = 88.362 + (13.397 * user.weight) + (4.799 * user.height) - (5.677 * user.age) if user.gender == 'Male' else 447.593 + (9.247 * user.weight) + (3.098 * user.height) - (4.330 * user.age)
            multiplier = {'Sedentary': 1.2, 'Light': 1.375, 'Moderate': 1.55, 'Active': 1.725}.get(user.activity_level, 1.2)
            user.target_calories = bmr * multiplier
        
        db.session.commit()
        
        return jsonify({'status': 'success', 'message': 'Profil berhasil diupdate', 'user': user.to_dict()}), 200

    return auth_bp