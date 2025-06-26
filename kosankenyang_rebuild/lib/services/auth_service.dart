// lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/controllers/auth_controller.dart';

class AuthService {
  static const String _baseUrl = 'https://ZakyAtha.pythonanywhere.com';
  //static const String _baseUrl = 'http://10.0.2.2:8080';

  Future<bool> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await _saveUserData(responseData); // Panggil fungsi helper untuk sinkronisasi
        Get.find<AuthController>().userDidLogin(responseData);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String lokasiKos) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final response = await http.post(
        url, headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nama': name, 'email': email, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfile(String email, Map<String, dynamic> profileData) async {
    final url = Uri.parse('$_baseUrl/update-profile');
    try {
      final Map<String, dynamic> body = {'email': email, ...profileData};
      final response = await http.post(
        url, headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        print('Profil berhasil diupdate di backend.');
        final responseData = jsonDecode(response.body);
        // Panggil fungsi helper untuk sinkronisasi data lengkap setelah update
        await _saveUserData(responseData);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // --- FUNGSI HELPER BARU UNTUK SINKRONISASI DATA LENGKAP ---
  Future<void> _saveUserData(Map<String, dynamic> responseData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = responseData['token'] as String?;
    final userData = responseData['user'] as Map<String, dynamic>;

    if (token != null) await prefs.setString('user_token', token);

    await prefs.setString('user_email', userData['email'] ?? '');
    await prefs.setString('user_name', userData['nama'] ?? '');
    await prefs.setBool('setup_completed', userData['setup_completed'] ?? false);

    // Sinkronisasi data fisik
    if (userData['gender'] is String) await prefs.setString('user_gender', userData['gender']);
    if (userData['activity_level'] is String) await prefs.setString('user_activity_level', userData['activity_level']);
    if (userData['weight'] is num) await prefs.setDouble('user_weight', (userData['weight'] as num).toDouble());
    if (userData['height'] is num) await prefs.setDouble('user_height', (userData['height'] as num).toDouble());
    if (userData['age'] is num) await prefs.setInt('user_age', (userData['age'] as num).toInt());

    // Sinkronisasi preferensi
    if (userData['target_calories'] is num) await prefs.setDouble('target_calories', (userData['target_calories'] as num).toDouble());
    if (userData['daily_budget'] is num) await prefs.setDouble('daily_budget', (userData['daily_budget'] as num).toDouble());
    if (userData['monthly_budget'] is num) await prefs.setDouble('monthly_budget', (userData['monthly_budget'] as num).toDouble());

    // Pastikan data list disimpan dengan benar
    if (userData['preferences'] is List) await prefs.setStringList('user_preferences', (userData['preferences'] as List).cast<String>());
    if (userData['allergies'] is List) await prefs.setStringList('user_allergies', (userData['allergies'] as List).cast<String>());

    print("✅ AuthService: Data pengguna lengkap berhasil disinkronkan ke SharedPreferences.");
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}