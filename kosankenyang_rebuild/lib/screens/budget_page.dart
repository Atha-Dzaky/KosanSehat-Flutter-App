// lib/screens/budget_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:kosankenyang_rebuild/services/auth_service.dart';
import 'package:kosankenyang_rebuild/screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue();
    }

    final number = int.tryParse(newText);
    if (number == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###', 'id_ID');
    String newString = formatter.format(number).replaceAll(',', '.');

    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

class BudgetPage extends StatefulWidget {
  final bool isFromOnboarding;
  final Map<String, dynamic>? onboardingData;

  const BudgetPage({super.key, this.isFromOnboarding = false, this.onboardingData});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final TextEditingController _dailyBudgetController = TextEditingController();
  final TextEditingController _monthlyBudgetController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dailyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userEmail = prefs.getString('user_email');
    if (!widget.isFromOnboarding) {
      double? dailyBudget = prefs.getDouble('daily_budget');
      double? monthlyBudget = prefs.getDouble('monthly_budget');
      final formatter = NumberFormat('#,###', 'id_ID');
      if (dailyBudget != null) _dailyBudgetController.text = formatter.format(dailyBudget).replaceAll(',', '.');
      if (monthlyBudget != null) _monthlyBudgetController.text = formatter.format(monthlyBudget).replaceAll(',', '.');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _completeOnboardingAndSave() async {
    if (_userEmail == null) return;
    if (_dailyBudgetController.text.isEmpty) {
      Get.snackbar('Peringatan', 'Anggaran harian wajib diisi.');
      return;
    }
    setState(() => _isLoading = true);

    final String dailyText = _dailyBudgetController.text.replaceAll('.', '');
    final String monthlyText = _monthlyBudgetController.text.replaceAll('.', '');
    double? dailyBudget = double.tryParse(dailyText);
    double? monthlyBudget = monthlyText.isNotEmpty ? double.tryParse(monthlyText) : null;

    Map<String, dynamic> finalProfileData = {
      'daily_budget': dailyBudget,
      'monthly_budget': monthlyBudget,
    };

    if (widget.isFromOnboarding && widget.onboardingData != null) {
      finalProfileData.addAll(widget.onboardingData!);
      finalProfileData['setup_completed'] = true;
    }

    bool success = await _authService.updateProfile(_userEmail!, finalProfileData);

    if (success) {
      Get.snackbar('Selamat!', 'Profil Anda berhasil disimpan!', backgroundColor: Colors.green, colorText: Colors.white);
      Get.offAll(() => const HomePage());
    } else {
      Get.snackbar('Gagal', 'Gagal menyimpan profil. Coba lagi.', backgroundColor: Colors.red, colorText: Colors.white);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.isFromOnboarding ? 'Langkah Terakhir: Anggaran' : 'Pengaturan Anggaran', style: const TextStyle(color: Colors.white)),
        backgroundColor: orangeColor,
        automaticallyImplyLeading: !widget.isFromOnboarding,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: orangeColor))
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Anggaran Harian Anda:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _dailyBudgetController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()], decoration: InputDecoration(hintText: 'Misal: 50.000', prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: orangeColor)))),
            const SizedBox(height: 20),
            const Text('Anggaran Bulanan Anda (Opsional):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _monthlyBudgetController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()], decoration: InputDecoration(hintText: 'Misal: 1.500.000', prefixText: 'Rp ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: orangeColor)))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeOnboardingAndSave,
                style: ElevatedButton.styleFrom(backgroundColor: orangeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(widget.isFromOnboarding ? 'Selesai & Mulai' : 'Simpan Perubahan', style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const Spacer(),
            const Center(child: Text('Catatan: Anggaran harian akan digunakan untuk rekomendasi meal plan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}