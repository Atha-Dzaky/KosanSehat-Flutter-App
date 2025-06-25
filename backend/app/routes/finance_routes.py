# app/routes/finance_routes.py

from flask import Blueprint, request, jsonify
from app.models import db, User, Expense
from datetime import datetime, date
import json

def create_finance_blueprint():
    finance_bp = Blueprint('finance_bp', __name__)

    @finance_bp.route('/set_budget', methods=['POST'])
    def set_budget():
        data = request.json
        user_email = data.get('user_email')
        daily_budget = data.get('daily_budget')
        monthly_budget = data.get('monthly_budget')
        if not user_email: return jsonify({"status": "error", "message": "Email pengguna dibutuhkan."}), 400
        user = User.query.filter_by(email=user_email).first()
        if not user: return jsonify({"status": "error", "message": "Pengguna tidak ditemukan."}), 404
        if daily_budget is not None: user.daily_budget = daily_budget if isinstance(daily_budget, (int, float)) and daily_budget >= 0 else None
        if monthly_budget is not None: user.monthly_budget = monthly_budget if isinstance(monthly_budget, (int, float)) and monthly_budget >= 0 else None
        db.session.commit()
        return jsonify({"status": "success", "message": "Anggaran berhasil diatur."}), 200

    @finance_bp.route('/record_expense', methods=['POST'])
    def record_expense():
        data = request.json
        user_email = data.get('user_email')
        amount = data.get('amount')
        if not all([user_email, amount is not None]): return jsonify({"status": "error", "message": "Email dan jumlah dibutuhkan."}), 400
        user = User.query.filter_by(email=user_email).first()
        if not user: return jsonify({"status": "error", "message": "Pengguna tidak ditemukan."}), 404
        if not isinstance(amount, (int, float)) or amount <= 0: return jsonify({"status": "error", "message": "Jumlah pengeluaran harus angka positif."}), 400
        
        new_expense = Expense(
            amount=amount,
            description=data.get('description', 'Pembelian makanan'),
            timestamp=datetime.utcnow(),
            author=user,
            plan_details=json.dumps(data.get('plan_details')) if data.get('plan_details') else None
        )
        db.session.add(new_expense)
        db.session.commit()
        
        print(f"Pengeluaran baru untuk {user_email} sebesar {amount} telah disimpan ke DB.")
        return jsonify({"status": "success", "message": "Pengeluaran berhasil dicatat."}), 201

    @finance_bp.route('/get_expense_report', methods=['GET'])
    def get_expense_report():
        user_email = request.args.get('user_email')
        period = request.args.get('period', 'daily')
        user = User.query.filter_by(email=user_email).first()
        if not user: return jsonify({"status": "error", "message": "Pengguna tidak ditemukan di DB."}), 404
        
        query = Expense.query.filter_by(user_id=user.id)
        today_utc = datetime.utcnow().date()
        if period == 'daily':
            query = query.filter(db.func.date(Expense.timestamp) == today_utc)
        elif period == 'monthly':
            query = query.filter(db.func.extract('month', Expense.timestamp) == today_utc.month, db.func.extract('year', Expense.timestamp) == today_utc.year)
        
        all_expenses_in_period = query.order_by(Expense.timestamp.desc()).all()
        
        filtered_expenses_list = [{"amount": e.amount, "description": e.description, "timestamp": e.timestamp.isoformat(), "plan_details": json.loads(e.plan_details) if e.plan_details else None} for e in all_expenses_in_period]
        
        total_spent_in_period = sum(e['amount'] for e in filtered_expenses_list)
        
        daily_budget, monthly_budget = user.daily_budget, user.monthly_budget
        remaining_daily_budget, remaining_monthly_budget = None, None

        if daily_budget is not None:
            all_today_expenses = Expense.query.filter_by(user_id=user.id).filter(db.func.date(Expense.timestamp) == today_utc).all()
            spent_today = sum(e.amount for e in all_today_expenses)
            remaining_daily_budget = daily_budget - spent_today
        if monthly_budget is not None:
            all_month_expenses = Expense.query.filter_by(user_id=user.id).filter(db.func.extract('year', Expense.timestamp) == today_utc.year, db.func.extract('month', Expense.timestamp) == today_utc.month).all()
            spent_this_month = sum(e.amount for e in all_month_expenses)
            remaining_monthly_budget = monthly_budget - spent_this_month
            
        print(f"Laporan pengeluaran untuk {user_email} ({period}): Total={total_spent_in_period}")
        return jsonify({
            "status": "success", "period": period, "total_spent": total_spent_in_period,
            "daily_budget": daily_budget, "monthly_budget": monthly_budget,
            "remaining_daily_budget": remaining_daily_budget, "remaining_monthly_budget": remaining_monthly_budget,
            "expenses": filtered_expenses_list
        }), 200

    return finance_bp