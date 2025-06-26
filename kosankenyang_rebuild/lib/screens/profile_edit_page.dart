// lib/screens/profile_edit_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:kosankenyang_rebuild/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});
  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();

  bool _isLoading = true;
  String? _userEmail;
  String? _gender;
  String? _activityLevel;
  List<String> _selectedPreferences = [];
  List<String> _selectedAllergies = [];

  final List<String> _availablePreferences = ['Pedas', 'Manis', 'Gurih', 'Asam', 'Asin', 'Nasi', 'Mie', 'Sate', 'Sup', 'Gorengan', 'Masakan Padang', 'Masakan Jawa', 'Western Food', 'Chinese Food', 'Seafood'];
  final List<String> _availableAllergies = ['Kacang', 'Susu', 'Telur', 'Gluten', 'Seafood', 'Kedelai'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userEmail = prefs.getString('user_email');
        _nameController.text = prefs.getString('user_name') ?? '';

        _weightController.text = prefs.getDouble('user_weight')?.toStringAsFixed(0) ?? '';
        _heightController.text = prefs.getDouble('user_height')?.toStringAsFixed(0) ?? '';
        _ageController.text = prefs.getInt('user_age')?.toString() ?? '';
        _gender = prefs.getString('user_gender');
        _activityLevel = prefs.getString('user_activity_level');
        _selectedPreferences = prefs.getStringList('user_preferences') ?? [];
        _selectedAllergies = prefs.getStringList('user_allergies') ?? [];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateProfile() async {
    final isPhysicalDataFilled = _gender != null &&
        _activityLevel != null &&
        _weightController.text.isNotEmpty &&
        _heightController.text.isNotEmpty &&
        _ageController.text.isNotEmpty;

    if (_nameController.text.isEmpty) {
      Get.snackbar('Data tidak valid', 'Nama tidak boleh kosong.');
      return;
    }
    if (_userEmail == null) return;

    setState(() => _isLoading = true);

    Map<String, dynamic> profileData = {
      'nama': _nameController.text,
      'preferences': _selectedPreferences,
      'allergies': _selectedAllergies,
    };

    if (isPhysicalDataFilled) {
      profileData.addAll({
        'gender': _gender,
        'weight': double.tryParse(_weightController.text),
        'height': double.tryParse(_heightController.text),
        'age': int.tryParse(_ageController.text),
        'activity_level': _activityLevel,
      });
    }

    bool success = await _authService.updateProfile(_userEmail!, profileData);
    setState(() => _isLoading = false);

    if (success) {
      Get.snackbar('Berhasil', 'Profil Anda telah diperbarui!', backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
      Get.back();
    } else {
      Get.snackbar('Gagal', 'Gagal memperbarui profil. Silakan coba lagi.', backgroundColor: Colors.red, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Edit Profil & Preferensi', style: TextStyle(color: Colors.white)),
        backgroundColor: orangeColor,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Get.back()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: orangeColor))
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildSectionTitle('Informasi Dasar'),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama'), validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null),
            const SizedBox(height: 16),
            TextFormField(initialValue: _userEmail, readOnly: true, decoration: InputDecoration(labelText: 'Email (Tidak bisa diubah)', fillColor: Colors.grey[200], filled: true)),
            const Divider(height: 40, thickness: 1),
            _buildSectionTitle('Atribut Fisik (Isi untuk kalkulasi ulang kalori)'),
            _buildDropdown('Jenis Kelamin', ['Male', 'Female'], _gender, (val) => setState(() => _gender = val)),
            const SizedBox(height: 16),
            TextFormField(controller: _weightController, decoration: const InputDecoration(labelText: 'Berat Badan (kg)'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextFormField(controller: _heightController, decoration: const InputDecoration(labelText: 'Tinggi Badan (cm)'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextFormField(controller: _ageController, decoration: const InputDecoration(labelText: 'Usia'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildDropdown('Tingkat Aktivitas', ['Sedentary', 'Light', 'Moderate', 'Active'], _activityLevel, (val) => setState(() => _activityLevel = val)),
            const Divider(height: 40, thickness: 1),
            _buildSectionTitle('Preferensi Makanan'),
            Wrap(spacing: 8.0, runSpacing: 4.0, children: _availablePreferences.map((p) => FilterChip(
              label: Text(p), selected: _selectedPreferences.contains(p),
              onSelected: (s) => setState(() => s ? _selectedPreferences.add(p) : _selectedPreferences.remove(p)),
              selectedColor: orangeColor.withOpacity(0.2),
            )).toList()),
            const Divider(height: 40, thickness: 1),
            _buildSectionTitle('Alergi & Pantangan'),
            Wrap(spacing: 8.0, runSpacing: 4.0, children: _availableAllergies.map((a) => FilterChip(
              label: Text(a), selected: _selectedAllergies.contains(a),
              onSelected: (s) => setState(() => s ? _selectedAllergies.add(a) : _selectedAllergies.remove(a)),
              selectedColor: orangeColor.withOpacity(0.2),
            )).toList()),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(backgroundColor: orangeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor)),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value, onChanged: onChanged,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      items: items.map<DropdownMenuItem<String>>((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
    );
  }
}