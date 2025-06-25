# app/__init__.py

from flask import Flask
import os
import json
from .ml_engine.meal_planner import MealPlanner
from .models import db

menu_reviews_db = {}
restaurants_data_list = []
users_db = {} 

def load_processed_restaurants(data_path):
    try:
        with open(data_path, 'r', encoding='utf-8') as f: raw_data = json.load(f)
        processed_restaurants = [{"id": i + 1, "nama_warung": r.get('nama_restoran'), "rating": r.get('rating'), "kategori": "Umum", "koordinat": {"latitude": r.get('latitude'), "longitude": r.get('longitude')}} for i, r in enumerate(raw_data)]
        return processed_restaurants
    except Exception as e:
        print(f"ERROR saat memuat data restoran untuk API: {e}"); return []

def create_app():
    app = Flask(__name__)

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(base_dir, 'kosankenyang.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    db.init_app(app)

    try:
        data_path = os.path.join(base_dir, 'data', 'dataset_restoran_sidoarjo_enriched.json')
        app.config['MEAL_PLANNER_ENGINE'] = MealPlanner(data_path=data_path)
        global restaurants_data_list
        restaurants_data_list = load_processed_restaurants(data_path)
    except Exception as e:
        print(f"FATAL ERROR: Gagal memuat Meal Planner Engine: {e}"); exit()

    with app.app_context():
        db.create_all() 

        from .routes.auth_routes import create_auth_blueprint
        from .routes.meal_plan_routes import create_meal_plan_blueprint
        from .routes.resto_routes import create_resto_blueprint
        from .routes.recommendation_routes import create_recommendation_blueprint
        from .routes.finance_routes import create_finance_blueprint

        auth_bp = create_auth_blueprint()
        meal_plan_bp = create_meal_plan_blueprint()
        finance_bp = create_finance_blueprint()
        
        resto_bp = create_resto_blueprint(menu_reviews_db, restaurants_data_list, users_db)
        reco_bp = create_recommendation_blueprint(users_db, restaurants_data_list)
        
        app.register_blueprint(auth_bp)
        app.register_blueprint(meal_plan_bp)
        app.register_blueprint(resto_bp)
        app.register_blueprint(reco_bp)
        app.register_blueprint(finance_bp)

    @app.route("/")
    def index():
        return "<h1>Backend Kosankenyang Aktif!</h1>"

    return app