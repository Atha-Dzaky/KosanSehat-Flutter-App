// lib/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/screens/auth_page.dart';
import 'package:kosankenyang_rebuild/screens/restaurant_map_page.dart';
import 'package:kosankenyang_rebuild/screens/menu_detail_page.dart';
import 'package:kosankenyang_rebuild/services/auth_service.dart';
import 'package:kosankenyang_rebuild/services/recommendation_service.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kosankenyang_rebuild/screens/budget_page.dart';
import 'package:kosankenyang_rebuild/screens/expense_report_page.dart';
import 'package:kosankenyang_rebuild/screens/meal_plan_page.dart';
import 'package:kosankenyang_rebuild/screens/profile_edit_page.dart';

class HomePage extends StatefulWidget {
  final List<Map<String, dynamic>>? coldStartRecommendations;

  const HomePage({super.key, this.coldStartRecommendations});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final RecommendationService _recommendationService = RecommendationService();

  List<Map<String, dynamic>> _currentRecommendations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _userEmail;
  String? _userName;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    await _loadRecommendations();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userEmail = prefs.getString('user_email');
        _userName = prefs.getString('user_name');
      });
    }
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = ''; });

    try {
      List<Map<String, dynamic>> recommendations;
      if (widget.coldStartRecommendations != null && widget.coldStartRecommendations!.isNotEmpty) {
        print("INFO: Menampilkan rekomendasi dari Cold Start.");
        recommendations = widget.coldStartRecommendations!;
      }
      else {
        print("INFO: Tidak ada Cold Start Recs, memuat makanan terdekat...");
        recommendations = await _recommendationService.getNearbyRecommendations();
      }

      if (mounted) setState(() => _currentRecommendations = recommendations);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRecommendationsTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: orangeColor));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('Gagal Memuat Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadRecommendations,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: orangeColor),
                ),
              ],
            )
        ),
      );
    }

    if (_currentRecommendations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Tidak ada makanan yang ditemukan di sekitar Anda saat ini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      color: orangeColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _currentRecommendations.length,
        itemBuilder: (context, index) {
          final item = _currentRecommendations[index];
          final namaMenu = item['Nama'] ?? 'Nama Menu Tidak Diketahui';
          final namaWarung = item['nama_restoran'] ?? 'Warung Tidak Diketahui';
          final harga = (item['Harga'] as num?)?.toDouble() ?? 0;
          final jarakKm = (item['jarak_km'] as num?)?.toDouble();
          final imageUrl = item['URL Gambar'] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () {
                Get.to(() => MenuDetailPage(menuData: item));
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: imageUrl.isNotEmpty && imageUrl != 'Tidak ada gambar'
                            ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover, onError: (e,s){})
                            : null,
                      ),
                      child: imageUrl.isEmpty || imageUrl == 'Tidak ada gambar'
                          ? const Icon(Icons.fastfood, size: 40, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(namaMenu, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(namaWarung, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text('Rp ${harga.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: orangeColor)),
                        ],
                      ),
                    ),
                    if (jarakKm != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Column(
                          children: [
                            Icon(Icons.directions_walk, color: Colors.grey[600], size: 18),
                            Text('${jarakKm.toStringAsFixed(1)} km', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildRecommendationsTabContent(),
      const MealPlanPage(),
      const BudgetPage(),
      const ExpenseReportPage(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('KosanKenyang', style: TextStyle(color: Colors.white)),
        backgroundColor: orangeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: () => Get.to(() => const RestaurantMapPage()),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: orangeColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: orangeColor)),
                  const SizedBox(height: 10),
                  Text(_userName ?? 'Pengguna', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_userEmail ?? 'email@example.com', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profil'),
              onTap: () { Get.back(); Get.to(() => const ProfileEditPage()); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Keluar (Sign out)'),
              onTap: () async { Get.back(); await _authService.logout(); Get.offAll(() => const AuthPage()); },
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Meal Plan'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Anggaran'),
          BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Laporan'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: orangeColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
      ),
    );
  }
}