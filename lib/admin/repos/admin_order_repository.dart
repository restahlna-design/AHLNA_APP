import 'dart:io';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_notifier/local_notifier.dart';
import '../../models/order.dart';
import '../../models/food_item.dart';
import '../../core/supabase_client.dart';

class AdminOrderRepository {
  static const ordersTable = 'orders';
  static const orderItemsTable = 'order_items';
  static const recordsTable = 'order_records';

  SupabaseClient? get _c => SupabaseManager.client;

  String? _extractType(String? address) {
    if (address == null) return null;
    final m = RegExp(r"\[(.*?)\]").firstMatch(address);
    return m?.group(1);
  }

  List<Order> _parseOrders(List res) {
    final list = res.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    
    return list.map((o) {
      final items =
          (o['order_items'] as List?)?.map((it) {
            final m = Map<String, dynamic>.from(it);
            return OrderItem(
              item: FoodItem(
                id: m['food_id']?.toString() ?? m['name']?.toString() ?? '',
                name: m['name'] ?? m['item_name'] ?? '',
                price: (m['price'] as num?)?.toDouble() ?? 0,
                description: '',
                imageUrl: '',
                category: 'Unknown',
                isAvailable: true,
              ),
              quantity: m['quantity'] ?? 1,
            );
          }).toList() ??
          [];

      final rawAddress = o['address']?.toString() ?? '';
      String? note = o['note']?.toString() ?? o['notes']?.toString();
      if (note == null || note.trim().isEmpty) {
        final mNote = RegExp(r"\[NOTE:(.*?)\]").firstMatch(rawAddress) ??
                     RegExp(r"\[ملاحظة:(.*?)\]").firstMatch(rawAddress);
        if (mNote != null) {
          note = mNote.group(1)?.trim();
        }
      }

      String cleanAddress = rawAddress
          .replaceAll(RegExp(r"\[NOTE:(.*?)\]"), '')
          .replaceAll(RegExp(r"\[ملاحظة:(.*?)\]"), '')
          .replaceAll(RegExp(r"\[EDITED\]"), '')
          .replaceAll(RegExp(r"\[تعديل[^\]]*\]"), '')
          .replaceAll(RegExp(r"GPS\([-\d\.]+,[-\d\.]+\)"), '')
          .replaceAll(RegExp(r"\[(delivery|takeaway|dinein|توصيل|سفري|صالة)\]"), '')
          .trim();

      final type = o['order_type']?.toString() ?? _extractType(rawAddress);
      double? lat = (o['customer_lat'] as num?)?.toDouble();
      double? long = (o['customer_long'] as num?)?.toDouble();
      if (lat == null || long == null) {
        final m = RegExp(r"GPS\(([-\d\.]+),([-\d\.]+)\)").firstMatch(rawAddress);
        if (m != null) {
          lat = double.tryParse(m.group(1)!);
          long = double.tryParse(m.group(2)!);
        }
      }

      final bool isOrderEdited = (o['is_edited'] == true) || 
                                 rawAddress.contains('[EDITED]') || 
                                 rawAddress.contains('[تعديل') || 
                                 rawAddress.contains('تعديل لطلب');

      return Order(
        id: o['id']?.toString() ?? '',
        customerName: o['customer_name'] ?? '',
        phone: o['phone'] ?? '',
        address: cleanAddress.isNotEmpty ? cleanAddress : 'بدون عنوان',
        orderType: type,
        status: (o['status'] == 'cooking')
            ? OrderStatus.cooking
            : (o['status'] == 'completed')
            ? OrderStatus.completed
            : OrderStatus.pending,
        items: items,
        customerLat: lat,
        customerLong: long,
        isEdited: isOrderEdited,
        note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      );
    }).toList();
  }

  Future<List<Order>> fetchActiveOrders() async {
    final c = _c;
    if (c == null) return [];
    try {
      final res = await c
          .from(ordersTable)
          .select('*, order_items(*)')
          .neq('status', 'completed')
          .order('created_at');
      final orders = _parseOrders(res as List);
      return orders;
    } catch (e) {
      print('⚠️ fetchActiveOrders error: $e');
      return [];
    }
  }

  Stream<List<Order>> liveActiveOrders({
    Duration poll = const Duration(seconds: 4),
  }) {
    final c = _c;
    if (c == null) return const Stream.empty();
    return Stream<List<Order>>.multi((controller) async {
      final initial = await fetchActiveOrders();
      controller.add(initial);
      final channel = c.channel('admin_orders_live_${DateTime.now().millisecondsSinceEpoch}');
      
      void emit() async {
        final list = await fetchActiveOrders();
        controller.add(list);
      }

      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: ordersTable,
        callback: (payload) {
          emit();
          _showNotification(payload, isUpdate: false);
        },
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: ordersTable,
        callback: (payload) {
          emit();
          _showNotification(payload, isUpdate: true);
        },
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: ordersTable,
        callback: (_) => emit(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: orderItemsTable,
        callback: (_) => emit(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: orderItemsTable,
        callback: (_) => emit(),
      );
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: orderItemsTable,
        callback: (_) => emit(),
      );
      channel.subscribe();
      final ticker = Stream.periodic(poll).listen((_) => emit());
      controller.onCancel = () async {
        await channel.unsubscribe();
        await ticker.cancel();
      };
    }, isBroadcast: true);
  }

  Future<void> setStatus(String orderId, String status) async {
    final c = _c;
    if (c == null) return;
    try {
      if (status == 'completed') {
        final orderData = await c
            .from(ordersTable)
            .select('*, order_items(*)')
            .eq('id', orderId)
            .single();
        
        final recordData = {
          'id': orderData['id'],
          'customer_name': orderData['customer_name'],
          'phone': orderData['phone'],
          'address': orderData['address'],
          'status': 'completed',
          'total_price': orderData['total_price'],
          'created_at': orderData['created_at'],
        };
        final ot = orderData['order_type'] ?? _extractType(orderData['address']?.toString());
        if (ot != null) {
          try {
            await c.from(recordsTable).insert({...recordData, 'order_type': ot});
          } catch (_) {
            await c.from(recordsTable).insert(recordData);
          }
        } else {
          await c.from(recordsTable).insert(recordData);
        }
        
        await c.from(orderItemsTable).delete().eq('order_id', orderId);
        await c.from(ordersTable).delete().eq('id', orderId);
      } else {
        await c.from(ordersTable).update({'status': status}).eq('id', orderId);
      }
    } catch (e) {
      print('setStatus error: $e');
    }
  }

  Future<void> deleteOrder(String orderId) async {
    final c = _c;
    if (c == null) return;
    try {
      await c.from(orderItemsTable).delete().eq('order_id', orderId);
      await c.from(ordersTable).delete().eq('id', orderId);
    } catch (e) {
      print('deleteOrder error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchRecords() async {
    final c = _c;
    if (c == null) return [];
    try {
      final res = await c.from(recordsTable).select().order('created_at');
      return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('fetchRecords error: $e');
      return [];
    }
  }

  void _showNotification(PostgresChangePayload payload, {bool isUpdate = false}) {
    // Play immediate alert sound on desktop and mobile
    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    if (!Platform.isWindows) return;

    final newRecord = payload.newRecord;
    if (newRecord.isEmpty) return;

    final customerName = newRecord['customer_name'] ?? 'زبون';
    final price = newRecord['total_price']?.toString() ?? '0';

    final title = isUpdate ? "تعديل على الطلب! 🔄" : "طلب جديد! 🔔";
    final body = isUpdate 
        ? "تم تعديل طلب $customerName (المبلغ: $price د.ع)"
        : "وصل طلب بقيمة $price د.ع من $customerName";

    final notification = LocalNotification(
      identifier: newRecord['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      actions: [
        LocalNotificationAction(
          text: 'فتح التطبيق',
        ),
      ],
    );

    notification.onClick = () {
      print('Notification clicked');
    };

    notification.show();
  }
}
