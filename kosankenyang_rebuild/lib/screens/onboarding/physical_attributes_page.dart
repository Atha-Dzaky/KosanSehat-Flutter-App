// lib/screens/onboarding/physical_attributes_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/screens/onboarding/akg_result_page.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';

class PhysicalAttributesPage extends StatefulWidget {
  const PhysicalAttributesPage({super.key});

  @override
  State<PhysicalAttributesPage> createState() => _PhysicalAttributesPageState();
}

class _PhysicalAttributesPageState extends State<PhysicalAttributesPage> {
  final _formKey = GlobalKey<FormState>();
  String? _gender;
  String? _activityLevel;
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _calculateAndNavigate() {
    if (!_formKey.currentState!.validate()) {
      Get.snackbar('Data Tidak Lengkap', 'Mohon isi semua kolom untuk melanjutkan.');
      return;
    }

    double weight = double.parse(_weightController.text);
    double height = double.parse(_heightController.text);
    int age = int.parse(_ageController.text);

    double bmr;
    if (_gender == 'Male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    double activityMultiplier;
    switch (_activityLevel) {
      case 'Light':
        activityMultiplier = 1.375;
        break;
      case 'Moderate':
        activityMultiplier = 1.55;
        break;
      case 'Active':
        activityMultiplier = 1.725;
        break;
      default: // Sedentary
        activityMultiplier = 1.2;
    }

    double totalCalories = bmr * activityMultiplier;

    Map<String, dynamic> physicalData = {
      'gender': _gender,
      'weight': weight,
      'height': height,
      'age': age,
      'activity_level': _activityLevel,
    };

    Get.to(() => AkgResultPage(
      calories: totalCalories,
      physicalData: physicalData,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceritakan Tentang Diri Anda'),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: backgroundColor,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Atribut Fisik', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Informasi ini digunakan untuk menghitung kebutuhan kalori harian Anda.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              _buildDropdown('Jenis Kelamin', ['Male', 'Female'], _gender, (val) => setState(() => _gender = val)),
              const SizedBox(height: 16),
              _buildTextField('Berat Badan (kg)', _weightController, TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Tinggi Badan (cm)', _heightController, TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Usia', _ageController, TextInputType.number),
              const SizedBox(height: 16),
              _buildDropdown('Tingkat Aktivitas', ['Sedentary', 'Light', 'Moderate', 'Active'], _activityLevel, (val) => setState(() => _activityLevel = val)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _calculateAndNavigate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hitung Kalori', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: items.map<DropdownMenuItem<String>>((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      validator: (value) {
        if (value == null) {
          return '$label harus dipilih';
        }
        return null;
      },
    );
  }
}