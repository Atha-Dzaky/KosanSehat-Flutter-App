// lib/controllers/meal_plan_controller.dart (LENGKAP DIPERBAIKI)

import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/services/recommendation_service.dart';
import 'package:kosankenyang_rebuild/controllers/auth_controller.dart'; // <-- IMPORT BARU
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class MealPlanController extends GetxController {
  final RecommendationService _recommendationService = RecommendationService();
  final AuthController _authController = Get.find<AuthController>();

  var isLoading = true.obs;
  var mealPlan = <String, dynamic>{}.obs;
  var errorMessage = ''.obs;
  var isPlanLoaded = false;

  void initialFetch() {
    if (!isPlanLoaded) {
      fetchOrCreateMealPlan();
    }
  }

  Future<void> fetchOrCreateMealPlan() async {
    try {
      isLoading(true);
      errorMessage('');
      final userEmail = _authController.userEmail.value;
      if (userEmail.isEmpty) {
        throw Exception("Sesi pengguna tidak valid. Silakan login kembali.");
      }
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      Map<String, dynamic>? existingPlan = await _recommendationService.getMealPlan(userEmail, today);
      if (existingPlan != null) {
        mealPlan.value = existingPlan;
      } else {
        final result = await _recommendationService.generateMealPlan(userEmail, today);
        if (result['status'] == 'success') {
          mealPlan.value = result['meal_plan'];
        } else {
          throw Exception(result['message'] ?? 'Gagal memuat data meal plan.');
        }
      }
      isPlanLoaded = true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading(false);
    }
  }

  Future<void> regenerateMealPlan() async {
    try {
      isLoading(true);
      errorMessage('');
      final userEmail = _authController.userEmail.value;
      if (userEmail.isEmpty) throw Exception("Sesi pengguna tidak valid.");
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await _recommendationService.generateMealPlan(userEmail, today);
      if (result['status'] == 'success') {
        mealPlan.value = result['meal_plan'];
        Get.snackbar("Berhasil", "Rencana makan baru telah dibuat!", snackPosition: SnackPosition.BOTTOM);
      } else {
        throw Exception(result['message'] ?? 'Gagal membuat data meal plan.');
      }
    } catch(e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading(false);
    }
  }

  Future<void> recordMealPlanAsExpense() async {
    if (mealPlan.isEmpty) { Get.snackbar("Peringatan", "Tidak ada rencana makan untuk dicatat."); return; }
    double totalHarga = 0;
    mealPlan.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        for (var item in value) {
          totalHarga += (item['Harga'] as num?)?.toDouble() ?? 0.0;
        }
      }
    });
    if (totalHarga <= 0) { Get.snackbar("Peringatan", "Total harga adalah nol, tidak ada yang dicatat."); return; }
    final userEmail = _authController.userEmail.value;
    if (userEmail.isEmpty) { Get.snackbar("Error", "Sesi tidak valid."); return; }

    Get.defaultDialog(
        title: "Konfirmasi Pengeluaran",
        middleText: "Anda akan mencatat pengeluaran sebesar Rp ${totalHarga.toStringAsFixed(0)} untuk meal plan hari ini. Lanjutkan?",
        textConfirm: "Ya, Catat", textCancel: "Batal", confirmTextColor: Colors.white,
        onConfirm: () async {
          Get.back();
          bool success = await _recommendationService.recordExpense(
              userEmail: userEmail,
              amount: totalHarga,
              description: "Pengeluaran dari Rencana Makan Harian",
              planDetails: mealPlan.value
          );
          if (success) {
            Get.snackbar("Berhasil", "Pengeluaran berhasil dicatat!", backgroundColor: Colors.green, colorText: Colors.white);
          } else {
            Get.snackbar("Gagal", "Gagal mencatat pengeluaran.", backgroundColor: Colors.red, colorText: Colors.white);
          }
        }
    );
  }
}