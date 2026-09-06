import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/cart.dart';
import '../core/storage.dart';
import '../core/repos/order_repository.dart';
import '../models/order.dart';
import '../core/profile.dart';

class CartScreen extends StatefulWidget {
  final Order? editingOrder;
  const CartScreen({super.key, this.editingOrder});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  String? _customerNote;

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to fetch global context controller if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final cart = CartProvider.of(context);
        final order = widget.editingOrder ?? cart.editingOrder;
        if (order != null && order.note != null) {
          setState(() {
            _customerNote = order.note;
          });
        }
      }
    });
  }

  void _showNoteDialog(BuildContext context) {
    final controller = TextEditingController(text: _customerNote ?? '');
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: cs.primary, size: 28),
            const SizedBox(width: 8),
            const Text(
              'ملاحظة للطلب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اكتب ملاحظتك الخاصة بالطلب (مثال: بدون صوص، زيادة فلفل...):',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'اكتب الملاحظة هنا...',
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: cs.outline)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _customerNote = controller.text.trim();
              });
              Navigator.pop(ctx);
              _showToastNotification(
                context,
                (_customerNote != null && _customerNote!.isNotEmpty)
                    ? 'تم حفظ الملاحظة ✓'
                    : 'تم إزالة الملاحظة',
                isError: false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showToastNotification(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: ToastWidget(
            message: message,
            isError: isError,
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartProvider.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('السلة'),
        actions: [
          TextButton(
            onPressed: cart.items.isEmpty ? null : cart.clear,
            child: const Text('تفريغ'),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: cart,
        builder: (context, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('السلة فارغة'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.item.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 56,
                              height: 56,
                              color: Colors.black26,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        title: Text(item.item.name),
                        subtitle: Text(
                          '${item.item.price % 1 == 0 ? item.item.price.toInt() : item.item.price} IQD',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => cart.removeOne(item.item.id),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (!item.item.isAvailable) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نفاذ الكمية'),
                                    ),
                                  );
                                  return;
                                }
                                cart.add(item.item);
                              },
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            IconButton(
                              onPressed: () => cart.removeAll(item.item.id),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'الإجمالي الكلي',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            '${cart.totalPrice % 1 == 0 ? cart.totalPrice.toInt() : cart.totalPrice} IQD',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: cs.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // أيقونة الملاحظة (القلم) بحجم مناسب بجانب زر إتمام الطلب
                          InkWell(
                            onTap: () => _showNoteDialog(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 55,
                              height: 55,
                              decoration: BoxDecoration(
                                color: (_customerNote != null && _customerNote!.isNotEmpty)
                                    ? cs.primary.withValues(alpha: 0.15)
                                    : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: (_customerNote != null && _customerNote!.isNotEmpty)
                                      ? cs.primary
                                      : cs.outline.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    color: (_customerNote != null && _customerNote!.isNotEmpty)
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    size: 28,
                                  ),
                                  if (_customerNote != null && _customerNote!.isNotEmpty)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: cs.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 55,
                              child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  final profile = ProfileProvider.of(context);
                                  if (profile.name.isEmpty ||
                                      profile.phone.isEmpty ||
                                      profile.address.isEmpty) {
                                    final local = await Storage.loadProfile();
                                    profile.set(
                                      name: local['name'],
                                      phone: local['phone'],
                                      address: local['address'],
                                    );
                                  }

                                  // ----------------------------------------------------
                                  //  🔥 بداية نافذة الاختيار الجديدة (Premium Design) 🔥
                                  // ----------------------------------------------------
                                  final type = await showDialog<String>(
                                    context: context,
                                    builder: (context) {
                                      final theme = Theme.of(context);
                                      String? selected;
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return Dialog(
                                            backgroundColor: Colors
                                                .transparent, // شفاف لنرسم نحن الخلفية
                                            insetPadding: const EdgeInsets.all(
                                              16,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: theme
                                                    .scaffoldBackgroundColor,
                                                borderRadius:
                                                    BorderRadius.circular(28),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 10),
                                                  ),
                                                ],
                                              ),
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    20,
                                                    24,
                                                    20,
                                                    20,
                                                  ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'شلون تحب تستلم طلبك؟',
                                                    style: theme
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 24),

                                                  // خيار سفري
                                                  _buildPremiumCard(
                                                    context,
                                                    title: 'سفري (Takeaway)',
                                                    value: 'takeaway',
                                                    groupValue: selected,
                                                    icon: Icons
                                                        .shopping_bag_rounded,
                                                    onChanged: (v) => setState(
                                                      () => selected = v,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),

                                                  // خيار صالة
                                                  _buildPremiumCard(
                                                    context,
                                                    title:
                                                        'داخل المطعم (Dine-in)',
                                                    value: 'dinein',
                                                    groupValue: selected,
                                                    icon:
                                                        Icons.table_bar_rounded,
                                                    onChanged: (v) => setState(
                                                      () => selected = v,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),

                                                  // خيار دليفري
                                                  _buildPremiumCard(
                                                    context,
                                                    title: 'توصيل (Delivery)',
                                                    value: 'delivery',
                                                    groupValue: selected,
                                                    icon: Icons
                                                        .delivery_dining_rounded,
                                                    onChanged: (v) => setState(
                                                      () => selected = v,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 30),

                                                  // أزرار التحكم
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                context,
                                                              ),
                                                          style: TextButton.styleFrom(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 16,
                                                                ),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    14,
                                                                  ),
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'إلغاء',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        flex: 2,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                selected != null
                                                                ? theme
                                                                      .primaryColor
                                                                : Colors
                                                                      .grey[300],
                                                            foregroundColor:
                                                                Colors.white,
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 16,
                                                                ),
                                                            elevation:
                                                                selected != null
                                                                ? 8
                                                                : 0,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    14,
                                                                  ),
                                                            ),
                                                          ),
                                                          onPressed:
                                                              selected == null
                                                              ? null
                                                              : () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      selected,
                                                                    ),
                                                          child: const Text(
                                                            'تأكيد الطلب',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                  // ----------------------------------------------------
                                  // نهاية التصميم الجديد
                                  // ----------------------------------------------------

                                  if (type == null) return;

                                  double? lat;
                                  double? long;

                                  // ----------------------------------------------------
                                  // 💎 معالجة طلب الدليفري وطلب إذن الموقع الجغرافي الفاخر 💎
                                  // ----------------------------------------------------
                                  if (type == 'delivery') {
                                    final consent = await _showLuxuryLocationConsentDialog(context);
                                    if (consent == null) {
                                      // المستخدم ألغى النافذة، نوقف عملية الطلب
                                      return;
                                    }

                                    if (consent == true) {
                                      // المستخدم وافق على تحديد الموقع تلقائياً
                                      setState(() => _isLoading = true);

                                      // 1. التحقق من تشغيل خدمة الموقع (GPS Hardware)
                                      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                      if (!serviceEnabled) {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                          _showToastNotification(
                                            context,
                                            'يرجى تشغيل خدمة الموقع (GPS) في هاتفك أو المتابعة بالعنوان المكتوب',
                                            isError: true,
                                          );
                                        }
                                        return;
                                      }

                                      // 2. التحقق من إذن الموقع وطلبه رسمياً
                                      var permission = await Geolocator.checkPermission();
                                      if (permission == LocationPermission.denied) {
                                        permission = await Geolocator.requestPermission();
                                      }
                                      if (permission == LocationPermission.deniedForever) {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                          _showToastNotification(
                                            context,
                                            'يرجى تفعيل إذن الموقع للتطبيق من إعدادات الهاتف',
                                            isError: true,
                                          );
                                          await Geolocator.openAppSettings();
                                        }
                                        return;
                                      }
                                      if (permission == LocationPermission.denied) {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                          _showToastNotification(
                                            context,
                                            'تم رفض إذن الموقع، يمكنك المتابعة بالعنوان المكتوب',
                                            isError: true,
                                          );
                                        }
                                        return;
                                      }

                                      // 3. محاولة جلب آخر موقع مسجل أولاً
                                      try {
                                        final lastPos = await Geolocator.getLastKnownPosition();
                                        if (lastPos != null) {
                                          lat = lastPos.latitude;
                                          long = lastPos.longitude;
                                        }
                                      } catch (_) {}

                                      // 4. جلب الموقع الدقيق الحالي
                                      try {
                                        final pos = await Geolocator.getCurrentPosition(
                                          desiredAccuracy: LocationAccuracy.high,
                                          timeLimit: const Duration(seconds: 8),
                                        );
                                        lat = pos.latitude;
                                        long = pos.longitude;
                                      } catch (_) {
                                        if (lat == null || long == null) {
                                          try {
                                            final pos2 = await Geolocator.getCurrentPosition(
                                              desiredAccuracy: LocationAccuracy.medium,
                                              timeLimit: const Duration(seconds: 5),
                                            );
                                            lat = pos2.latitude;
                                            long = pos2.longitude;
                                          } catch (_) {}
                                        }
                                      }
                                    } else {
                                      // اختار المتابعة بالعنوان المكتوب فقط (متوافق 100% مع أبل)
                                      setState(() => _isLoading = true);
                                    }
                                  } else {
                                    // سفري أو صالة: لا يتطلب موقع جغرافي نهائياً
                                    setState(() => _isLoading = true);
                                  }

                                  try {
                                    final repo = OrderRepository();
                                    final items = cart.items
                                        .map(
                                          (ci) => OrderItem(
                                            item: ci.item,
                                            quantity: ci.quantity,
                                          ),
                                        )
                                        .toList();
                                    final name = profile.name.isNotEmpty
                                        ? profile.name
                                        : 'زبون';
                                    final phone = profile.phone.isNotEmpty
                                        ? profile.phone
                                        : '0770';
                                    final address = profile.address.isNotEmpty
                                        ? profile.address
                                        : 'بدون';
                                    String? orderId;

                                      Order? targetOrder = widget.editingOrder ?? cart.editingOrder;

                                     if (targetOrder != null) {
                                       final success = await repo.updateOrder(
                                         orderId: targetOrder.id,
                                         customerName: name,
                                         phone: phone,
                                         address: address,
                                         orderType: type,
                                         items: items,
                                         customerLat: lat,
                                         customerLong: long,
                                         note: _customerNote,
                                       );
                                       if (success) {
                                         orderId = targetOrder.id;
                                       } else {
                                         // Fallback if RLS or DB prevents UPDATE on mobile
                                         print('⚠️ updateOrder returned false; falling back to creating updated order');
                                         final shortId = targetOrder.id.length > 5 ? targetOrder.id.substring(0, 5) : targetOrder.id;
                                         orderId = await repo.createOrder(
                                           customerName: name,
                                           phone: phone,
                                           address: '[تعديل لطلب #$shortId] $address',
                                           orderType: type,
                                           items: items,
                                           customerLat: lat,
                                           customerLong: long,
                                           note: _customerNote,
                                         );
                                         if (orderId != null) {
                                           try { repo.deleteOrder(targetOrder.id); } catch (_) {}
                                         }
                                       }
                                     } else {
                                       orderId = await repo.createOrder(
                                         customerName: name,
                                         phone: phone,
                                         address: address,
                                         orderType: type,
                                         items: items,
                                         customerLat: lat,
                                         customerLong: long,
                                         note: _customerNote,
                                       );
                                     }

                                    if (orderId == null) {
                                      if (mounted) {
                                        _showToastNotification(
                                          context,
                                          'تعذر إرسال الطلب',
                                          isError: true,
                                        );
                                      }
                                      return;
                                    }

                                     cart.clear();
                                     if (mounted) {
                                       Navigator.pop(context);
                                     }
                                  } catch (e, stackTrace) {
                                    print('ERROR IN SUBMIT: $e');
                                    print(stackTrace);
                                    if (mounted) {
                                      _showToastNotification(
                                        context,
                                        'تعذر إرسال الطلب: $e',
                                        isError: true,
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'إتمام الطلب',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  },
),
);
}

  // 💎 نافذة موافقة الموقع الجغرافي الفاخرة (Luxury Location Consent Sheet) 💎
  Future<bool?> _showLuxuryLocationConsentDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border(
              top: BorderSide(
                color: cs.primary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب العلوي الأنيق
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // الأيقونة الفاخرة مع هالة ضوئية دائرية
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          cs.primary.withValues(alpha: 0.25),
                          cs.primary.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primary,
                          cs.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // العنوان الفخم بخط Tajawal
              Text(
                'تحديد موقع التوصيل بدقة',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                  fontFamily: 'Tajawal',
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // النص التوضيحي المعتمد لدى مراجعي أبل
              Text(
                'لتوصيل وجبتك ساخنة وبأسرع وقت إلى مكانك، نحتاج إلى إذن تحديد موقعك الجغرافي لتوجيه مندوب التوصيل مباشرة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.55,
                  color: cs.onSurface.withValues(alpha: 0.75),
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 20),

              // بطاقة المزايا الزجاجية الراقية
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.navigation_rounded, size: 16, color: cs.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'توجيه المندوب فوراً دون الحاجة للاتصال المتكرر للاستدلال',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, size: 16, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'خصوصيتك محفوظة بالكامل؛ يُستخدم الموقع لمرة واحدة لهذا الطلب فقط',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // زر الموافقة الرئيسي الفخم
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: cs.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.my_location_rounded, size: 20, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'موافق، تحديد موقعي تلقائياً (GPS)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // زر المتابعة بالعنوان المكتوب (ميزة تفضيلية تمنع رفض أبل)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.onSurface.withValues(alpha: 0.8),
                    side: BorderSide(
                      color: cs.outline.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_outlined, size: 18, color: cs.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      const Text(
                        'المتابعة بالعنوان المكتوب فقط',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 ودجت البطاقة الفاخرة (Premium Card) 🔥
  Widget _buildPremiumCard(
    BuildContext context, {
    required String title,
    required String value,
    required String? groupValue,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;
    final primaryColor = theme.primaryColor;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // الأيقونة داخل دائرة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 16),
            // النص
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
            // علامة الاختيار
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade400,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const ToastWidget({
    super.key,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: widget.isError ? Colors.redAccent : Colors.green,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.isError ? Icons.error_outline : Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
