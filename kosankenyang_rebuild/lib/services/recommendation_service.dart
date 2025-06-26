// lib/services/recommendation_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class RecommendationService {
  static const String _baseUrl = 'https://ZakyAtha.pythonanywhere.com';
  //static const String _baseUrl = 'http://10.0.2.2:8080';

  Future<List<Map<String, dynamic>>> getNearbyRecommendations() async {
    Position? position = await getCurrentLocation();
    if (position == null) throw Exception('Lokasi tidak dapat diakses.');
    final url = Uri.parse('$_baseUrl/recommendations/nearby?latitude=${position.latitude}&longitude=${position.longitude}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(utf8.decode(response.bodyBytes)));
      throw Exception('Gagal memuat rekomendasi terdekat.');
    } catch (e) {
      throw Exception('Kesalahan jaringan: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getColdStartRecommendations({required double targetCalories, List<String> preferences = const [], List<String> allergies = const []}) async {
    Position? position = await getCurrentLocation();
    if (position == null) return [];
    final url = Uri.parse('$_baseUrl/cold_start_recommendations');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'latitude': position.latitude, 'longitude': position.longitude, 'target_calories': targetCalories, 'preferences': preferences, 'allergies': allergies,}));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (e) { print('Error getColdStartRecommendations: $e'); }
    return [];
  }

  Future<List<Map<String, dynamic>>> getAiRecommendations(String userEmail) async {
    final url = Uri.parse('$_baseUrl/recommendations');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_id': userEmail}));
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (e) { print('Error getAiRecommendations: $e'); }
    return [];
  }

  // --- FUNGSI MEAL PLAN ---
  Future<Map<String, dynamic>> generateMealPlan(String userEmail, String planDate) async {
    final url = Uri.parse('$_baseUrl/generate-meal-plan');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_email': userEmail, 'plan_date': planDate}));
      if (response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') return data;
        throw Exception(data['message'] ?? 'Gagal membuat meal plan.');
      }
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception('Gagal membuat meal plan: ${err['message'] ?? 'Error'}');
    } catch (e) {
      throw Exception('Kesalahan jaringan: $e');
    }
  }

  Future<Map<String, dynamic>?> getMealPlan(String userEmail, String planDate) async {
    final url = Uri.parse('$_baseUrl/get_meal_plan?user_email=${Uri.encodeComponent(userEmail)}&plan_date=${Uri.encodeComponent(planDate)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['status'] == 'success' ? data['meal_plan'] : null;
      }
      return null;
    } catch (e) { return null; }
  }

  // --- FUNGSI PENDUKUNG (Restoran, Review, Budget, Expense) ---
  Future<List<Map<String, dynamic>>> getAllRestaurants() async {
    final url = Uri.parse('$_baseUrl/restaurants');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (e) { print('Error getAllRestaurants: $e'); }
    return [];
  }

  Future<bool> submitRatingReview({required String userEmail, required String menuName, required double rating, String reviewText = '', String? userName}) async {
    final url = Uri.parse('$_baseUrl/submit_rating_review');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_email': userEmail, 'menu_name': menuName, 'rating': rating, 'review_text': reviewText, 'user_name': userName}));
      return response.statusCode == 201;
    } catch (e) { print('Error submitRatingReview: $e'); }
    return false;
  }

  Future<Map<String, dynamic>> getMenuReviews(String menuName) async {
    final url = Uri.parse('$_baseUrl/get_menu_reviews?menu_name=${Uri.encodeComponent(menuName)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) { print('Error getMenuReviews: $e'); }
    return {"status": "error", "reviews": []};
  }

  Future<bool> setBudget({required String userEmail, double? dailyBudget, double? monthlyBudget}) async {
    final url = Uri.parse('$_baseUrl/set_budget');
    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'user_email': userEmail, 'daily_budget': dailyBudget, 'monthly_budget': monthlyBudget}));
      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (dailyBudget != null) await prefs.setDouble('daily_budget', dailyBudget); else await prefs.remove('daily_budget');
        if (monthlyBudget != null) await prefs.setDouble('monthly_budget', monthlyBudget); else await prefs.remove('monthly_budget');
        return true;
      }
    } catch (e) { print('Error setBudget: $e'); }
    return false;
  }

  Future<bool> recordExpense({required String userEmail, required double amount, String description = 'Pembelian makanan', Map<String, dynamic>? planDetails}) async {
    final url = Uri.parse('$_baseUrl/record_expense');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_email': userEmail, 'amount': amount, 'description': description, 'plan_details': planDetails}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error recordExpense: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getExpenseReport({required String userEmail, String period = 'daily'}) async {
    final url = Uri.parse('$_baseUrl/get_expense_report?user_email=${Uri.encodeComponent(userEmail)}&period=${Uri.encodeComponent(period)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) { print('Error getExpenseReport: $e'); }
    return {"status": "error", "expenses": []};
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) { return null; }
  }
}