# app/routes/meal_plan_routes.py

from flask import Blueprint, request, jsonify, current_app
from app.models import db, User, MealPlan
import json
from datetime import datetime
import pandas as pd

saved_meal_plans = {}

def create_meal_plan_blueprint():
    meal_plan_bp = Blueprint('meal_plan_bp', __name__)

    @meal_plan_bp.route('/get-meal-plan', methods=['GET'])
    def get_meal_plan_endpoint():
        user_email = request.args.get('user_email')
        plan_date_str = request.args.get('plan_date')
        if not all([user_email, plan_date_str]):
            return jsonify({"status": "error", "message": "Parameter user_email dan plan_date dibutuhkan."}), 400
        
        user = User.query.filter_by(email=user_email).first()
        if not user: return jsonify({"status": "error", "message": "Pengguna tidak ditemukan."}), 404
        
        try:
            plan_date = datetime.strptime(plan_date_str, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({"status": "error", "message": "Format tanggal tidak valid (YYYY-MM-DD)."}), 400

        existing_plan = MealPlan.query.filter_by(user_id=user.id, plan_date=plan_date).first()

        if existing_plan:
            return jsonify({"status": "success", "meal_plan": json.loads(existing_plan.plan_data)}), 200
        else:
            return jsonify({"status": "error", "message": "Meal plan tidak ditemukan untuk tanggal ini."}), 404

    @meal_plan_bp.route('/generate-meal-plan', methods=['POST'])
    def generate_meal_plan_endpoint():
        data = request.json
        user_email = data.get('user_email')
        plan_date_str = data.get('plan_date', datetime.now().strftime('%Y-%m-%d'))
        if not user_email: return jsonify({"status": "error", "message": "Email pengguna dibutuhkan."}), 400

        user = User.query.filter_by(email=user_email).first()
        if not user: return jsonify({"status": "error", "message": "Pengguna tidak ditemukan."}), 404
        
        target_calories = user.target_calories
        daily_budget = user.daily_budget
        preferences = json.loads(user.preferences) if user.preferences else []
        allergies = json.loads(user.allergies) if user.allergies else []

        if not all([target_calories, daily_budget]):
            return jsonify({"status": "error", "message": "Target kalori dan budget harian harus diatur di profil."}), 400

        meal_planner_engine = current_app.config['MEAL_PLANNER_ENGINE']
        
        try:
            plan = meal_planner_engine.create_daily_meal_plan(
                target_kalori_harian=target_calories, preferensi=preferences,
                alergi=allergies, budget_harian=daily_budget
            )
            
            for meal_type, meal_list in plan.items():
                if isinstance(meal_list, list) and meal_list:
                    temp_df = pd.DataFrame(meal_list)
                    cleaned_df = temp_df.where(pd.notna(temp_df), None)
                    plan[meal_type] = cleaned_df.to_dict(orient='records')
            
            plan_date = datetime.strptime(plan_date_str, '%Y-%m-%d').date()
            
            MealPlan.query.filter_by(user_id=user.id, plan_date=plan_date).delete()
            new_plan = MealPlan(user_id=user.id, plan_date=plan_date, plan_data=json.dumps(plan))
            db.session.add(new_plan)
            db.session.commit()

            return jsonify({"status": "success", "message": "Meal plan berhasil dibuat.", "meal_plan": plan}), 201
        
        except Exception as e:
            print(f"ERROR saat membuat meal plan: {e}")
            return jsonify({"status": "error", "message": "Gagal membuat meal plan."}), 500

    return meal_plan_bp