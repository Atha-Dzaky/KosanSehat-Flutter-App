# app/routes/resto_routes.py

from flask import Blueprint, request, jsonify
from app.models import db, User, Review

def create_resto_blueprint(menu_reviews_db, restaurants_data_list, users_db):
    resto_bp = Blueprint('resto_bp', __name__)

    @resto_bp.route('/restaurants', methods=['GET'])
    def get_all_restaurants():
        if not restaurants_data_list:
            return jsonify({"status": "error", "message": "Data restoran tidak tersedia."}), 503
        return jsonify(restaurants_data_list)

    @resto_bp.route('/submit_rating_review', methods=['POST'])
    def submit_rating_review():
        data = request.json
        user_email = data.get('user_email')
        menu_name = data.get('menu_name')
        rating = data.get('rating')
        review_text = data.get('review_text', '')
        user_name_from_req = data.get('user_name')

        if not all([user_email, menu_name, rating is not None]):
            return jsonify({"status": "error", "message": "Email, nama menu, dan rating dibutuhkan."}), 400

        user = User.query.filter_by(email=user_email).first()
        if not user:
            return jsonify({"status": "error", "message": "Pengguna tidak terdaftar di database."}), 404
        
        existing_review = Review.query.filter_by(user_id=user.id, menu_name=menu_name).first()

        if existing_review:
            existing_review.rating = rating
            existing_review.review_text = review_text
        else:
            new_review = Review(menu_name=menu_name, rating=rating, review_text=review_text, author=user)
            db.session.add(new_review)
        
        db.session.commit()
        
        user_name_to_log = user_name_from_req or user.nama
        print(f"Ulasan baru/update untuk '{menu_name}' dari '{user_name_to_log}' ({user_email}): Rating {rating}")
        return jsonify({"status": "success", "message": "Rating dan ulasan berhasil disimpan."}), 201

    @resto_bp.route('/get_menu_reviews', methods=['GET'])
    def get_menu_reviews():
        menu_name = request.args.get('menu_name')
        if not menu_name:
            return jsonify({"status": "error", "message": "Nama menu dibutuhkan."}), 400
        
        reviews_from_db = Review.query.filter_by(menu_name=menu_name).all()
        
        average_rating = 0.0
        if reviews_from_db:
            total_rating = sum(r.rating for r in reviews_from_db)
            average_rating = total_rating / len(reviews_from_db)
        
        return_reviews = []
        for review in reviews_from_db:
            return_reviews.append({
                "user_name": review.author.nama, 
                "rating": review.rating,
                "review": review.review_text
            })

        print(f"Mengirim {len(return_reviews)} ulasan untuk '{menu_name}'. Rata-rata: {average_rating:.2f}")
        return jsonify({
            "status": "success",
            "menu_name": menu_name,
            "average_rating": average_rating,
            "reviews": return_reviews
        }), 200

    return resto_bp