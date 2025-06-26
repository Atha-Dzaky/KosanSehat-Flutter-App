// lib/screens/meal_plan_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/controllers/meal_plan_controller.dart';
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:kosankenyang_rebuild/screens/menu_detail_page.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({super.key});
  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final MealPlanController controller = Get.put(MealPlanController());
  double _targetCalories = 2000.0;
  double _dailyBudget = 60000.0;

  @override
  void initState() {
    super.initState();
    _loadUserTargets();
    controller.initialFetch();
  }

  Future<void> _loadUserTargets() async {
    final prefs = await SharedPreferences.getInstance();
    if(mounted) {
      setState(() {
        _targetCalories = prefs.getDouble('target_calories') ?? 2000.0;
        _dailyBudget = prefs.getDouble('daily_budget') ?? 60000.0;
      });
    }
  }

  double _calculateTotalHarga(Map<String, dynamic> mealPlan) {
    double total = 0;
    mealPlan.forEach((key, value) {
      if (value is List) for (var item in value) total += (item['Harga'] as num?)?.toDouble() ?? 0.0;
    });
    return total;
  }

  double _calculateTotalCalories(Map<String, dynamic> mealPlan) {
    double total = 0;
    mealPlan.forEach((key, value) {
      if (value is List) for (var item in value) total += (item['kalori'] as num?)?.toDouble() ?? 0.0;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: orangeColor));
        }
        if (controller.errorMessage.isNotEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text("Error: ${controller.errorMessage.value}")));
        }
        if (controller.mealPlan.isEmpty || ((controller.mealPlan['sarapan'] as List).isEmpty && (controller.mealPlan['makan_siang'] as List).isEmpty && (controller.mealPlan['makan_malam'] as List).isEmpty)) {
          return const Center(child: Text("Belum ada rencana makan. Tekan refresh."));
        }

        final totalKalori = _calculateTotalCalories(controller.mealPlan);
        final totalHarga = _calculateTotalHarga(controller.mealPlan);
        final percent = (totalKalori / _targetCalories).clamp(0.0, 1.0);
        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return RefreshIndicator(
          onRefresh: () async => controller.regenerateMealPlan(),
          color: orangeColor,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            children: [
              CircularPercentIndicator(
                radius: 110.0,
                lineWidth: 20.0,
                percent: percent,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${totalKalori.toStringAsFixed(0)}", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                    Text("dari ${_targetCalories.toStringAsFixed(0)} kkal", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: orangeColor,
                backgroundColor: Colors.grey.shade300,
                animation: true,
                animationDuration: 1200,
                footer: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    "Budget: ${currencyFormatter.format(totalHarga)} / ${currencyFormatter.format(_dailyBudget)}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildMealSection('🍳 Sarapan', controller.mealPlan['sarapan']),
              _buildMealSection('☀️ Makan Siang', controller.mealPlan['makan_siang']),
              _buildMealSection('🌙 Makan Malam', controller.mealPlan['makan_malam']),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  controller.recordMealPlanAsExpense();
                },
                icon: const Icon(Icons.receipt_long, color: Colors.white),
                label: const Text("Catat sebagai Pengeluaran", style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Warna hijau untuk aksi positif
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.regenerateMealPlan(),
        backgroundColor: orangeColor,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildMealSection(String title, List<dynamic>? mealItems) {
    if (mealItems == null || mealItems.isEmpty) return const SizedBox.shrink();
    double totalKaloriSesi = 0;
    for (var item in mealItems) {
      totalKaloriSesi += (item['kalori'] as num?)?.toDouble() ?? 0.0;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text("${totalKaloriSesi.toStringAsFixed(0)} kkal", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 8),
          ...mealItems.map((item) => _buildMenuItem(item)).toList(),
          const Divider(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    final imageUrl = item['URL Gambar'] ?? '';
    final menuName = item['Nama'] ?? 'Nama Tidak Ada';
    final restoName = item['nama_restoran'] ?? 'Restoran Tidak Ada';
    final kalori = (item['kalori'] as num?)?.toDouble() ?? 0.0;
    final harga = (item['Harga'] as num?)?.toDouble() ?? 0.0;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () => Get.to(() => MenuDetailPage(menuData: item)),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey[200], child: const Icon(Icons.restaurant, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(menuName, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(restoName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ])),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${kalori.toStringAsFixed(0)} kkal', style: const TextStyle(color: orangeColor, fontWeight: FontWeight.bold)),
                Text('Rp ${harga.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}