// lib/screens/onboarding/food_preferences_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:kosankenyang_rebuild/screens/budget_page.dart';

class FoodPreferencesPage extends StatefulWidget {
  final double targetCalories;
  final Map<String, dynamic> physicalData;

  const FoodPreferencesPage({
    super.key,
    required this.targetCalories,
    required this.physicalData
  });

  @override
  State<FoodPreferencesPage> createState() => _FoodPreferencesPageState();
}

class _FoodPreferencesPageState extends State<FoodPreferencesPage> {
  final List<String> _selectedPreferences = [];
  final List<String> _selectedAllergies = [];

  final List<String> _availablePreferences = ['Pedas', 'Manis', 'Gurih', 'Asam', 'Asin', 'Nasi', 'Mie', 'Sate', 'Sup', 'Gorengan', 'Masakan Padang', 'Masakan Jawa', 'Western Food', 'Chinese Food', 'Seafood'];
  final List<String> _availableAllergies = ['Kacang', 'Susu', 'Telur', 'Gluten', 'Seafood', 'Kedelai'];

  void _continueToBudgetPage() {
    Map<String, dynamic> collectedData = {
      ...widget.physicalData,
      'target_calories': widget.targetCalories,
      'preferences': _selectedPreferences,
      'allergies': _selectedAllergies,
    };

    Get.to(() => BudgetPage(
      isFromOnboarding: true,
      onboardingData: collectedData,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Preferensi Makanan Anda'),
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih rasa atau jenis makanan favorit Anda:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0, runSpacing: 4.0,
              children: _availablePreferences.map((preference) {
                final isSelected = _selectedPreferences.contains(preference);
                return FilterChip(
                  label: Text(preference), selected: isSelected,
                  onSelected: (selected) => setState(() => selected ? _selectedPreferences.add(preference) : _selectedPreferences.remove(preference)),
                  selectedColor: orangeColor.withOpacity(0.3), checkmarkColor: orangeColor,
                  labelStyle: TextStyle(color: isSelected ? orangeColor : Colors.black87),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? orangeColor : Colors.grey.shade300)),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            const Text('Apakah Anda memiliki alergi atau pantangan?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0, runSpacing: 4.0,
              children: _availableAllergies.map((allergy) {
                final isSelected = _selectedAllergies.contains(allergy);
                return FilterChip(
                  label: Text(allergy), selected: isSelected,
                  onSelected: (selected) => setState(() => selected ? _selectedAllergies.add(allergy) : _selectedAllergies.remove(allergy)),
                  selectedColor: orangeColor.withOpacity(0.3), checkmarkColor: orangeColor,
                  labelStyle: TextStyle(color: isSelected ? orangeColor : Colors.black87),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? orangeColor : Colors.grey.shade300)),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _continueToBudgetPage,
                style: ElevatedButton.styleFrom(backgroundColor: orangeColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Lanjut ke Anggaran', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}