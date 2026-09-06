import 'package:flutter/material.dart';
import '../../core/repos/notifications_repository.dart';
import '../../models/notification_model.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _repo = NotificationsRepository();
  final _titleController = TextEditingController(text: 'إشعار من الإدارة');
  final _messageController = TextEditingController();
  bool _isSending = false;
  int? _deletingId;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final message = _messageController.text.trim();
    final title = _titleController.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'يرجى كتابة نص الإشعار أولاً',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final success = await _repo.sendNotification(
      message,
      title: title.isEmpty ? 'إشعار من الإدارة' : title,
    );

    setState(() => _isSending = false);

    if (!mounted) return;

    if (success) {
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'تم إرسال الإشعار بنجاح إلى جميع الزبائن',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF23AA49),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'حدث خطأ أثناء إرسال الإشعار، يرجى المحاولة مرة أخرى',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _confirmDelete(NotificationModel notification) async {
    final theme = Theme.of(context);
    final accentBronze = theme.primaryColor;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161F33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: accentBronze.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text(
              'تأكيد حذف الإشعار',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف هذا الإشعار نهائياً؟\nسيتم حذفه تلقائياً من تطبيق الزبائن فوراً.\n\nالنص: "${notification.message}"',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            height: 1.5,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'حذف نهائي',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _deletingId = notification.id);
      final ok = await _repo.deleteNotification(notification.id);
      setState(() => _deletingId = null);

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم حذف الإشعار بنجاح',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: const Color(0xFF23AA49),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'فشل حذف الإشعار',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _formatArabicDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'م' : 'ص';
    final min = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min $period';

    if (diff.inSeconds < 60) {
      return 'الآن ($timeStr)';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة ($timeStr)';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      return 'اليوم - $timeStr';
    } else if (diff.inDays < 2 && dt.day == now.subtract(const Duration(days: 1)).day) {
      return 'أمس - $timeStr';
    } else {
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} - $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentBronze = theme.primaryColor;
    final secondaryNavy = theme.colorScheme.surface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compose section
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: _buildComposeCard(secondaryNavy, accentBronze),
                ),
              ),
              const SizedBox(width: 20),
              // History list section
              Expanded(
                flex: 6,
                child: _buildHistorySection(secondaryNavy, accentBronze),
              ),
            ],
          );
        } else {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildComposeCard(secondaryNavy, accentBronze),
                const SizedBox(height: 20),
                SizedBox(
                  height: 550,
                  child: _buildHistorySection(secondaryNavy, accentBronze),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildComposeCard(Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.campaign_rounded, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إرسال إشعار عام',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'سيظهر الإشعار لجميع الزبائن في صفحة الإشعارات',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12.5,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 20),

          // Title field
          const Text(
            'عنوان الإشعار',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF161F33),
              hintText: 'مثال: عرض خاص، تنبيه هام...',
              hintStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
              prefixIcon: Icon(Icons.title_rounded, color: accentColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Message field
          const Text(
            'نص رسالة الإشعار *',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 5,
            minLines: 4,
            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white, height: 1.4),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF161F33),
              hintText: 'اكتب نص الإشعار هنا...\nمثال: زبائننا الكرام، يسرنا إعلامكم بتوفر أطباق جديدة وعروض حصرية اليوم!',
              hintStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Send button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendNotification,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _isSending ? 'جارٍ الإرسال...' : 'إرسال الإشعار الآن',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: const Color(0xFF161F33),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(Color bgColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_rounded, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'سجل الإشعارات المرسلة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: _repo.streamNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: accentColor),
                  );
                }

                final list = snapshot.data ?? [];

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_rounded,
                          size: 48,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'لم يتم إرسال أي إشعارات بعد',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isDeleting = _deletingId == item.id;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F33),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withValues(alpha: 0.15),
                            ),
                            child: Icon(
                              Icons.mark_chat_unread_rounded,
                              size: 20,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatArabicDateTime(item.createdAt),
                                      style: const TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: 11.5,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.message,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 13.5,
                                    height: 1.4,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Delete button
                          IconButton(
                            onPressed: isDeleting ? null : () => _confirmDelete(item),
                            tooltip: 'حذف الإشعار',
                            icon: isDeleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                                  )
                                : const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
