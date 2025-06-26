// lib/controllers/expense_report_controller.dart

import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/services/recommendation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseReportController extends GetxController {
  final RecommendationService _recommendationService = RecommendationService();

  var isLoading = true.obs;
  var selectedPeriod = 'daily'.obs;
  var reportData = <String, dynamic>{}.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadReportData(); // Muat data saat pertama kali controller dibuat
  }

  void changePeriod(String newPeriod) {
    selectedPeriod.value = newPeriod;
    loadReportData(); // Muat ulang data saat periode berubah
  }

  Future<void> loadReportData() async {
    try {
      isLoading(true);
      errorMessage('');
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email');

      if (userEmail == null) {
        throw Exception("Sesi pengguna tidak valid.");
      }

      final data = await _recommendationService.getExpenseReport(
        userEmail: userEmail,
        period: selectedPeriod.value,
      );

      if (data['status'] == 'success') {
        reportData.value = data;
      } else {
        throw Exception(data['message'] ?? 'Gagal memuat laporan.');
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading(false);
    }
  }
}