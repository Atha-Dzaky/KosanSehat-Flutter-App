// lib/screens/menu_detail_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:kosankenyang_rebuild/screens/restaurant_map_page.dart';
import 'package:latlong2/latlong.dart';
import 'package:kosankenyang_rebuild/services/recommendation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuDetailPage extends StatefulWidget {
  final Map<String, dynamic> menuData;
  const MenuDetailPage({super.key, required this.menuData});

  @override
  State<MenuDetailPage> createState() => _MenuDetailPageState();
}

class _MenuDetailPageState extends State<MenuDetailPage> {
  final RecommendationService _recommendationService = RecommendationService();
  final TextEditingController _reviewController = TextEditingController();
  double _currentRating = 0.0;
  double _averageRating = 0.0;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;
  String? _userEmail;
  String? _userName;
  bool _isUserDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializePageData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _initializePageData() async {
    await _loadUserDataFromPrefs();
    await _loadReviews();
  }

  Future<void> _loadUserDataFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if(mounted) {
      setState(() {
        _userEmail = prefs.getString('user_email');
        _userName = prefs.getString('user_name');
        _isUserDataLoaded = true;
      });
    }
  }

  Future<void> _loadReviews() async {
    final menuName = widget.menuData['Nama'] ?? '';
    if (menuName.isEmpty) {
      if(mounted) setState(() => _isLoadingReviews = false);
      return;
    }

    try {
      final response = await _recommendationService.getMenuReviews(menuName);
      if (mounted && response['status'] == 'success') {
        setState(() {
          _averageRating = (response['average_rating'] as num?)?.toDouble() ?? 0.0;
          _reviews = (response['reviews'] as List?)?.cast<Map<String, dynamic>>() ?? [];

          final existingUserReview = _reviews.firstWhereOrNull((review) => review['user_name'] == _userName);
          if (existingUserReview != null) {
            _currentRating = (existingUserReview['rating'] as num?)?.toDouble() ?? 0.0;
            _reviewController.text = existingUserReview['review'] ?? '';
          }
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
    } finally {
      if(mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _submitReview() async {
    if (!_isUserDataLoaded || _userEmail == null) {
      Get.snackbar('Peringatan', 'Harap login untuk mengirim ulasan.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_currentRating == 0.0) {
      Get.snackbar('Peringatan', 'Mohon berikan rating (bintang) terlebih dahulu.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    setState(() { _isLoadingReviews = true; });

    final menuName = widget.menuData['Nama'] ?? '';
    final bool success = await _recommendationService.submitRatingReview(
      userEmail: _userEmail!,
      menuName: menuName,
      rating: _currentRating,
      reviewText: _reviewController.text,
      userName: _userName,
    );

    if (success) {
      Get.snackbar('Berhasil', 'Ulasan Anda berhasil dikirim!', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      await _loadReviews();
    } else {
      Get.snackbar('Gagal', 'Gagal mengirim ulasan. Coba lagi.', snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
    if(mounted) setState(() { _isLoadingReviews = false; });
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.menuData['URL Gambar'] ?? '';
    final menuName = widget.menuData['Nama'] ?? 'Nama Menu Tidak Diketahui';
    final warungName = widget.menuData['nama_restoran'] ?? 'Warung Tidak Diketahui';
    final price = (widget.menuData['Harga'] as num?)?.toInt() ?? 0;
    final description = widget.menuData['Deskripsi'] ?? 'Tidak ada deskripsi.';
    final calories = (widget.menuData['kalori'] as num?)?.toDouble();
    final sugar = (widget.menuData['gula_gram'] as num?)?.toDouble();
    final saturatedFat = (widget.menuData['lemak_jenuh_gram'] as num?)?.toDouble();
    final sodium = (widget.menuData['sodium_mg'] as num?)?.toDouble();
    final distanceKm = (widget.menuData['jarak_km'] as num?)?.toDouble();
    final restaurantLat = (widget.menuData['latitude'] as num?)?.toDouble();
    final restaurantLon = (widget.menuData['longitude'] as num?)?.toDouble();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(menuName, style: const TextStyle(color: Colors.white)),
        backgroundColor: orangeColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: imageUrl.isNotEmpty && imageUrl != 'Tidak ada gambar'
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey[400])))
                  : Center(child: Icon(Icons.fastfood, size: 80, color: Colors.grey[400])),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(menuName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Text(warungName, style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text('Rp ${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: orangeColor)),
                  if (distanceKm != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.directions_walk, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 4),
                          Text('${distanceKm.toStringAsFixed(1)} km', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  const Divider(height: 30, thickness: 1),
                  const Text('Deskripsi:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description.isEmpty || description == 'Tidak ada deskripsi' ? 'Tidak ada deskripsi tersedia untuk menu ini.' : description, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                  const Divider(height: 30, thickness: 1),
                  const Text('Informasi Gizi Perkiraan:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildNutritionRow('Kalori', calories, 'kcal'),
                  _buildNutritionRow('Gula', sugar, 'gram'),
                  _buildNutritionRow('Lemak Jenuh', saturatedFat, 'gram'),
                  _buildNutritionRow('Sodium', sodium, 'mg'),
                  if (restaurantLat != null && restaurantLon != null) ...[
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.to(() => RestaurantMapPage(
                            initialLocation: LatLng(restaurantLat, restaurantLon),
                            initialZoom: 16.0,
                            restaurantName: warungName,
                          ));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: orangeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.map, color: Colors.white),
                        label: const Text('Lihat di Peta', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ),
                  ],
                  const Divider(height: 30, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rating Pengguna:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      _isLoadingReviews
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: orangeColor))
                          : Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          Text(_averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(' (${_reviews.length} ulasan)', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text('Berikan Rating Anda:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) => IconButton(
                      icon: Icon(index < _currentRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                      onPressed: () => setState(() => _currentRating = (index + 1).toDouble()),
                    ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text('Tulis Ulasan Anda:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewController, maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enak, porsi pas...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: orangeColor)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: (_isLoadingReviews || !_isUserDataLoaded || _userEmail == null) ? null : _submitReview,
                      style: ElevatedButton.styleFrom(backgroundColor: orangeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isLoadingReviews ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Ulasan', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  const Text('Ulasan Lain:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _reviews.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Belum ada ulasan untuk menu ini. Jadilah yang pertama!')))
                      : ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final reviewRating = (review['rating'] as num?)?.toDouble() ?? 0.0;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(review['user_name'] ?? 'Anonim', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: List.generate(5, (starIndex) => Icon(starIndex < reviewRating ? Icons.star : Icons.star_border, color: Colors.amber, size: 18)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(review['review'] ?? ''),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, double? value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontSize: 16)),
          Text(value != null ? '${value.toStringAsFixed(1)} $unit' : 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}