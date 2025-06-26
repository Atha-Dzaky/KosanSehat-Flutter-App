// lib/screens/expense_report_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kosankenyang_rebuild/controllers/expense_report_controller.dart'; // Impor controller baru
import 'package:kosankenyang_rebuild/utils/app_colors.dart';
import 'package:intl/intl.dart';

class ExpenseReportPage extends StatelessWidget {
  const ExpenseReportPage({super.key});

  String _formatCurrency(double? amount) {
    if (amount == null) return 'N/A';
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {

    final ExpenseReportController controller = Get.put(ExpenseReportController());

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        title: const Text('Laporan Pengeluaran', style: TextStyle(color: Colors.white)),
        backgroundColor: orangeColor,
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: orangeColor));
        }
        if (controller.errorMessage.isNotEmpty) {
          return Center(child: Text("Error: ${controller.errorMessage.value}"));
        }


        final report = controller.reportData;
        final expenses = (report['expenses'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text('Anggaran Anda:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Harian: ${_formatCurrency((report['daily_budget'] as num?)?.toDouble())}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  Text('Total Pengeluaran (${report['period'] ?? '...'}):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(_formatCurrency((report['total_spent'] as num?)?.toDouble()), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: orangeColor)),
                  SizedBox(height: 10),
                  if (report['period'] == 'daily' && report['daily_budget'] != null)
                    Text('Sisa Anggaran Harian: ${_formatCurrency((report['remaining_daily_budget'] as num?)?.toDouble())}',
                        style: TextStyle(fontSize: 16, color: (report['remaining_daily_budget'] as num? ?? 0) < 0 ? Colors.red : Colors.green)),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: controller.selectedPeriod.value,
                    decoration: InputDecoration(
                      labelText: 'Periode Laporan',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Harian')),
                      DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                      DropdownMenuItem(value: 'all', child: Text('Keseluruhan')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        controller.changePeriod(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text('Riwayat Pengeluaran:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: expenses.isEmpty
                  ? Center(child: Text('Belum ada pengeluaran dicatat untuk periode ini.'))
                  : ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  final timestampString = expense['timestamp'] as String?;
                  final timestamp = timestampString != null ? DateTime.parse(timestampString) : null;
                  final formattedDate = timestamp != null ? DateFormat('dd MMM, HH:mm').format(timestamp) : '...';

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Icon(Icons.shopping_cart, color: orangeColor),
                      title: Text(expense['description'] ?? 'Pembelian'),
                      subtitle: Text('${expense['menu_name'] ?? ''} - $formattedDate'),
                      trailing: Text(_formatCurrency((expense['amount'] as num?)?.toDouble()),
                          style: TextStyle(fontWeight: FontWeight.bold, color: orangeColor)),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => controller.loadReportData(),
        child: Icon(Icons.refresh),
        backgroundColor: orangeColor,
      ),
    );
  }
}