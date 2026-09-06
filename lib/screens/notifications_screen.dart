import 'package:flutter/material.dart';
import '../core/repos/notifications_repository.dart';
import '../core/storage.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationsRepository();
  Set<int> _readIds = {};

  @override
  void initState() {
    super.initState();
    _loadReadState();
  }

  Future<void> _loadReadState() async {
    final ids = await Storage.loadReadNotificationIds();
    if (mounted) {
      setState(() {
        _readIds = ids;
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    if (_readIds.contains(id)) return;
    await Storage.markNotificationAsRead(id);
    if (mounted) {
      setState(() {
        _readIds.add(id);
      });
    }
  }

  Future<void> _markAllAsRead(List<NotificationModel> notifications) async {
    final allIds = notifications.map((n) => n.id).toList();
    await Storage.markAllNotificationsAsRead(allIds);
    if (mounted) {
      setState(() {
        _readIds.addAll(allIds);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم تحديد جميع الإشعارات كمقروءة',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: const Color(0xFF23AA49),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatArabicDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} دقيقة';
    } else if (diff.inHours < 24 && dt.day == now.day) {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final period = dt.hour >= 12 ? 'م' : 'ص';
      final min = dt.minute.toString().padLeft(2, '0');
      return 'اليوم في $hour:$min $period';
    } else if (diff.inDays < 2 && dt.day == now.subtract(const Duration(days: 1)).day) {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final period = dt.hour >= 12 ? 'م' : 'ص';
      final min = dt.minute.toString().padLeft(2, '0');
      return 'أمس في $hour:$min $period';
    } else {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final period = dt.hour >= 12 ? 'م' : 'ص';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} - $hour:$min $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text(
          'الإشعارات',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _repo.streamNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'لا توجد إشعارات حالياً',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ستصلك أحدث العروض والرسائل من الإدارة هنا',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final unreadCount = notifications.where((n) => !_readIds.contains(n.id)).length;

          return Column(
            children: [
              // Header bar with unread count & Mark all as read button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: unreadCount > 0
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        unreadCount > 0
                            ? '$unreadCount إشعار جديد'
                            : 'جميع الإشعارات مقروءة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: unreadCount > 0
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (unreadCount > 0)
                      InkWell(
                        onTap: () => _markAllAsRead(notifications),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.done_all_rounded,
                                size: 18,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'تحديد الكل كمقروء',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Notifications List
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90, top: 4),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final isRead = _readIds.contains(item.id);

                    return _buildNotificationCard(
                      item: item,
                      isRead: isRead,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required NotificationModel item,
    required bool isRead,
    required bool isDark,
    required Color primaryColor,
  }) {
    final cardBg = isDark
        ? (isRead ? const Color(0xFF1A1D24) : const Color(0xFF1E2530))
        : (isRead ? Colors.white : const Color(0xFFF3FAF5));

    final borderColor = isRead
        ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04))
        : const Color(0xFF10B981).withValues(alpha: isDark ? 0.4 : 0.3);

    return InkWell(
      onTap: () => _markAsRead(item.id),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isRead ? 1 : 1.5),
          boxShadow: [
            BoxShadow(
              color: isRead
                  ? Colors.black.withValues(alpha: isDark ? 0.2 : 0.03)
                  : const Color(0xFF10B981).withValues(alpha: isDark ? 0.12 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRead
                    ? (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100)
                    : const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
              ),
              child: Icon(
                isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                color: isRead
                    ? (isDark ? Colors.white54 : Colors.grey.shade600)
                    : const Color(0xFF10B981),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Notification Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title.isNotEmpty ? item.title : 'إشعار من الإدارة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (!isRead) ...[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13.5,
                      height: 1.4,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formatArabicDateTime(item.createdAt),
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11.5,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
