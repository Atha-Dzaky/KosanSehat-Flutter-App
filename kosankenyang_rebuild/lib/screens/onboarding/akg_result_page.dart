// lib/screens/onboarding/akg_result_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:kosankenyang_rebuild/screens/onboarding/food_preferences_page.dart';

class AkgResultPage extends StatelessWidget {
  final double calories;
  final Map<String, dynamic> physicalData;

  const AkgResultPage({
    super.key,
    required this.calories,
    required this.physicalData,
  });

  void _continueToNextOnboardingStep() {
    Get.offAll(() => FoodPreferencesPage(
      targetCalories: calories,
      physicalData: physicalData,
    ));
  }

  @override
  Widget build(BuildContext context) {
    double carbs = (calories * 0.40) / 4;
    double protein = (calories * 0.30) / 4;
    double fat = (calories * 0.30) / 9;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Hasil Kebutuhan Kalori Anda'),
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Kebutuhan Kalori Harian Anda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              calories.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: orangeColor),
            ),
            const Text(
              'kkal / hari',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            _buildMacroInfo('Karbohidrat', '${carbs.toStringAsFixed(0)} gram'),
            _buildMacroInfo('Protein', '${protein.toStringAsFixed(0)} gram'),
            _buildMacroInfo('Lemak', '${fat.toStringAsFixed(0)} gram'),
            const Spacer(),
            ElevatedButton(
              onPressed: _continueToNextOnboardingStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Lanjut ke Preferensi Makanan', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 10),
            const Text(
              '*) Perkiraan ini berdasarkan rumus Mifflin-St Jeor. Kebutuhan individu dapat bervariasi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}