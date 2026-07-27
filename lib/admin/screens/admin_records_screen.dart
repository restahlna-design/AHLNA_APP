import 'package:flutter/material.dart';
import '../core/admin_data.dart';
import '../../core/repos/order_repository.dart';

class AdminRecordsScreen extends StatefulWidget {
  const AdminRecordsScreen({super.key});

  @override
  State<AdminRecordsScreen> createState() => _AdminRecordsScreenState();
}

class _AdminRecordsScreenState extends State<AdminRecordsScreen> {
  final data = AdminData();
  final repo = OrderRepository();
  List<Map<String, dynamic>> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await repo.fetchRecords();
    if (mounted) {
      setState(() {
        records = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // تعريف الألوان
    const primaryGreen = Color(0xFF23AA49);

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "لا توجد سجلات سابقة",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    // ✅ استخدام LayoutBuilder لجعل التصميم متجاوباً
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // إذا كانت الشاشة عريضة (أكبر من 600) اعرض جدولاً
          if (constraints.maxWidth > 600) {
            return _buildDesktopTable(primaryGreen);
          }
          // وإلا اعرض قائمة للموبايل
          else {
            return _buildMobileList(primaryGreen);
          }
        },
      ),
    );
  }

  // 🖥️ تصميم الجدول للشاشات الكبيرة
  Widget _buildDesktopTable(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            color.withValues(alpha: 0.1),
          ),
          dataRowHeight: 70,
          columns: const [
            DataColumn(
              label: Text(
                'رقم الطلب',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'التاريخ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'المبلغ الإجمالي',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الحالة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: records.map((o) {
            final price = (o['total_price'] as num?)?.toDouble() ?? 0.0;
            final date = o['created_at'] != null
                ? DateTime.parse(
                    o['created_at'].toString(),
                  ).toString().split('.')[0]
                : '-';
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    '#${o['id'].toString().substring(0, 8)}...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(date, style: const TextStyle(color: Colors.grey)),
                ),
                DataCell(
                  Text(
                    '${price % 1 == 0 ? price.toInt() : price} IQD',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(_buildStatusBadge(o['status'] ?? 'completed')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // 📱 تصميم القائمة للموبايل
  Widget _buildMobileList(Color color) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final o = records[index];
        final price = (o['total_price'] as num?)?.toDouble() ?? 0.0;
        final date = o['created_at'] != null
            ? DateTime.parse(
                o['created_at'].toString(),
              ).toString().split('.')[0]
            : '-';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.receipt_long, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلب #${o['id'].toString().substring(0, 5)}..',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${price % 1 == 0 ? price.toInt() : price} IQD',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(o['status'] ?? 'completed', isSmall: true),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, {bool isSmall = false}) {
    Color bg;
    Color text;
    String label;

    if (status == 'cancelled') {
      bg = Colors.red.shade50;
      text = Colors.red;
      label = 'ملغي';
    } else {
      bg = Colors.green.shade50;
      text = Colors.green;
      label = 'مكتمل';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
