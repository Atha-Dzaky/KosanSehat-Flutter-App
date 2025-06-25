# app/routes/recommendation_routes.py

from flask import Blueprint, request, jsonify, current_app
from geopy.distance import geodesic
import pandas as pd
import json #

def create_recommendation_blueprint(users_db, restaurants_data):
    reco_bp = Blueprint('reco_bp', __name__)

    @reco_bp.route('/recommendations/nearby', methods=['GET'])
    def get_nearby_recommendations():
        user_lat_str = request.args.get('latitude')
        user_lon_str = request.args.get('longitude')

        if not user_lat_str or not user_lon_str:
            return jsonify({"status": "error", "message": "Parameter latitude dan longitude dibutuhkan."}), 400
        
        try:
            user_lat = float(user_lat_str)
            user_lon = float(user_lon_str)
        except (ValueError, TypeError):
            return jsonify({"status": "error", "message": "Latitude dan longitude harus berupa angka."}), 400

        print(f"INFO: Menerima permintaan makanan terdekat untuk lokasi: {user_lat}, {user_lon}")
        
        try:
            meal_planner_engine = current_app.config['MEAL_PLANNER_ENGINE']
            df_all_food = meal_planner_engine.df.copy()

            def calculate_distance(row):
                resto_lat = row.get('latitude')
                resto_lon = row.get('longitude')
                if pd.notna(resto_lat) and pd.notna(resto_lon):
                    return geodesic((user_lat, user_lon), (resto_lat, resto_lon)).km
                return float('inf')

            df_all_food['jarak_km'] = df_all_food.apply(calculate_distance, axis=1)
            nearby_foods_df = df_all_food.sort_values(by='jarak_km').head(20)
            
            json_string = nearby_foods_df.to_json(orient='records')
            nearby_foods_list = json.loads(json_string)

            print(f"INFO: Mengirim {len(nearby_foods_list)} rekomendasi makanan terdekat.")
            return jsonify(nearby_foods_list), 200

        except Exception as e:
            print(f"ERROR saat menghitung rekomendasi terdekat: {e}")
            return jsonify({"status": "error", "message": "Terjadi kesalahan internal saat memproses permintaan."}), 500

    @reco_bp.route('/recommendations', methods=['POST'])
    def get_ai_recommendations():
        print("INFO: Endpoint /recommendations dipanggil, tetapi saat ini tidak aktif.")
        return jsonify([]), 200

    @reco_bp.route('/cold_start_recommendations', methods=['POST'])
    def get_cold_start_recommendations():
        print("INFO: Endpoint /cold_start_recommendations dipanggil.")
        return jsonify([]), 200
    
    return reco_bp