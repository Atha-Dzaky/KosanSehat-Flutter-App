// lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/controllers/auth_controller.dart';
import 'package:kosankenyang_rebuild/screens/auth_page.dart';
import 'package:kosankenyang_rebuild/screens/home_page.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await Get.putAsync(() async => AuthController(), permanent: true);

    Timer(const Duration(seconds: 2), () {
      final authController = Get.find<AuthController>();

      if (authController.isLoggedIn.value) {
        Get.offAll(() => const HomePage());
      } else {
        Get.offAll(() => const AuthPage());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 500,
          height: 500,
        ),
      ),
    );
  }
}