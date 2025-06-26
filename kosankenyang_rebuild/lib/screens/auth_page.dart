import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/screens/home_page.dart';
import 'package:kosankenyang_rebuild/services/auth_service.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding/physical_attributes_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _isLoading = false.obs;
  bool _obscurePassword = true;

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    _isLoading.value = true;
    bool isLoggedIn = await _authService.login(
      _signInEmailController.text,
      _signInPasswordController.text,
    );
    _isLoading.value = false;

    if (isLoggedIn) {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      bool setupCompleted = prefs.getBool('setup_completed') ?? false;

      if (!setupCompleted) {
        Get.offAll(() => const PhysicalAttributesPage());
      } else {
        Get.offAll(() => const HomePage());
      }
    } else {
      Get.snackbar('Login Gagal', 'Email atau password salah.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _handleRegister() async {
    if (_signUpNameController.text.isEmpty || _signUpEmailController.text.isEmpty || _signUpPasswordController.text.isEmpty) {
      Get.snackbar('Peringatan', 'Semua kolom harus diisi.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    _isLoading.value = true;
    bool isRegistered = await _authService.register(
      _signUpNameController.text,
      _signUpEmailController.text,
      _signUpPasswordController.text,
      '',
    );
    _isLoading.value = false;

    if (isRegistered) {
      Get.snackbar('Registrasi Berhasil', 'Silakan login dengan akun baru Anda.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      _tabController.animateTo(0);
    } else {
      Get.snackbar('Registrasi Gagal', 'Terjadi kesalahan. Mungkin email sudah terdaftar.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Image.asset('assets/images/logo.png', height: 300),
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: orangeColor,
                  indicatorWeight: 3,
                  labelColor: orangeColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Sign in'),
                    Tab(text: 'Sign up'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSignInForm(),
                    _buildSignUpForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _signInEmailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                suffixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: orangeColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _signInPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••••••',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: orangeColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => _isLoading.value && _tabController.index == 0
                  ? const Center(child: CircularProgressIndicator(color: orangeColor))
                  : ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              )
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _signUpNameController,
              decoration: InputDecoration(
                hintText: 'Enter your name',
                suffixIcon: Icon(Icons.person_outline, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: orangeColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _signUpEmailController,
              decoration: InputDecoration(
                hintText: 'Enter your email',
                suffixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: orangeColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _signUpPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••••••',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: orangeColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(() => _isLoading.value && _tabController.index == 1
                  ? const Center(child: CircularProgressIndicator(color: orangeColor))
                  : ElevatedButton(
                onPressed: _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sign up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              )
              ),
            ),
          ],
        ),
      ),
    );
  }
}