// lib/controllers/auth_controller.dart

import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/screens/auth_page.dart';
import 'package:kosankenyang_rebuild/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();

  var isLoggedIn = false.obs;
  var userEmail = ''.obs;
  var userName = ''.obs;
  var token = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('user_token');
    if (storedToken != null && storedToken.isNotEmpty) {
      isLoggedIn.value = true;
      userEmail.value = prefs.getString('user_email') ?? '';
      userName.value = prefs.getString('user_name') ?? '';
      token.value = storedToken;
    } else {
      isLoggedIn.value = false;
    }
  }

  void userDidLogin(Map<String, dynamic> responseData) {
    final userData = responseData['user'] as Map<String, dynamic>;
    token.value = responseData['token'] as String;
    userEmail.value = userData['email'] as String;
    userName.value = userData['nama'] as String;
    isLoggedIn.value = true;
  }

  Future<void> logout() async {
    await _authService.logout();
    isLoggedIn.value = false;
    userEmail.value = '';
    userName.value = '';
    token.value = '';
    Get.offAll(() => const AuthPage());
  }
}