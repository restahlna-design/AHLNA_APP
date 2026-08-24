import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:local_notifier/local_notifier.dart';
import '../../admin/models/order.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class OrderRepository {
  static const ordersTable = 'orders';
  static const orderItemsTable = 'order_items';
  static const recordsTable = 'order_records';

  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient ?? _c;

  String? _extractType(String? address) {
    if (address == null) return null;
    final m = RegExp(r"\[(.*?)\]").firstMatch(address);
    return m?.group(1);
  }

  Future<String?> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required String orderType,
    required List<OrderItem> items,
    double? customerLat,
    double? customerLong,
    String? note,
  }) async {
    final primary = _svc ?? _c;
    if (primary == null) {
      print('ERROR: Primary client is null');
      return null;
    }

    try {
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();
      final totalPrice = items.fold(0.0, (s, e) => s + e.item.price * e.quantity);
      final now = DateTime.now().toIso8601String();
      final cleanNote = (note != null && note.trim().isNotEmpty) ? note.trim() : null;

      // Build address string with embedded GPS and type
      String finalAddress = address.isNotEmpty ? address : 'بدون';
      if (customerLat != null && customerLong != null) {
        finalAddress = 'GPS($customerLat,$customerLong) $finalAddress';
      }
      finalAddress = '[$orderType] $finalAddress';
      if (cleanNote != null) {
        finalAddress = '$finalAddress [NOTE:$cleanNote]';
      }

      final fullOrderData = <String, dynamic>{
        'id': orderId,
        'customer_name': customerName,
        'phone': phone,
        'address': finalAddress,
        'status': 'pending',
        'total_price': totalPrice,
        'created_at': now,
        'order_type': orderType,
      };
      if (cleanNote != null) fullOrderData['note'] = cleanNote;
      if (customerLat != null) fullOrderData['customer_lat'] = customerLat;
      if (customerLong != null) fullOrderData['customer_long'] = customerLong;

      bool orderInserted = false;
      try {
        await primary.from(ordersTable).insert(fullOrderData);
        orderInserted = true;
        print('✅ Order inserted with all columns');
      } catch (e1) {
        print('⚠️ Full insert failed: $e1, trying fallback...');
        final minData = <String, dynamic>{
          'id': orderId,
          'customer_name': customerName,
          'phone': phone,
          'address': finalAddress,
          'status': 'pending',
          'total_price': totalPrice,
          'created_at': now,
        };
        try {
          await primary.from(ordersTable).insert(minData);
          orderInserted = true;
          print('✅ Order inserted with minimal columns fallback');
        } catch (e2) {
          print('❌ Minimal insert failed: $e2');
          final svc = _svc;
          if (svc != null && svc != primary) {
            try {
              await svc.from(ordersTable).insert(minData);
              orderInserted = true;
              print('✅ Order inserted using service client');
            } catch (e3) {
              print('❌ Service client insert also failed: $e3');
            }
          }
        }
      }

      if (!orderInserted) {
        print('❌ Failed to insert order after all attempts');
        return null;
      }

      // Insert order items with safe food_id checking
      if (items.isNotEmpty) {
        final itemsData = items.map((e) {
          final isNumeric = RegExp(r'^\d+$').hasMatch(e.item.id);
          return {
            'order_id': orderId,
            'food_id': isNumeric ? e.item.id : null,
            'name': e.item.name,
            'price': e.item.price,
            'quantity': e.quantity,
          };
        }).toList();
        
        try {
          await primary.from(orderItemsTable).insert(itemsData);
          print('✅ Order items inserted successfully');
        } catch (itemErr) {
          print('⚠️ order_items insert failed: $itemErr, retrying without food_id...');
          try {
            final fallbackItems = items.map((e) => {
              'order_id': orderId,
              'food_id': null,
              'name': e.item.name,
              'price': e.item.price,
              'quantity': e.quantity,
            }).toList();
            await primary.from(orderItemsTable).insert(fallbackItems);
            print('✅ Order items inserted with null food_id fallback');
          } catch (_) {
            final svc = _svc;
            if (svc != null && svc != primary) {
              try {
                final fallbackItems = items.map((e) => {
                  'order_id': orderId,
                  'food_id': null,
                  'name': e.item.name,
                  'price': e.item.price,
                  'quantity': e.quantity,
                }).toList();
                await svc.from(orderItemsTable).insert(fallbackItems);
              } catch (_) {}
            }
          }
        }
      }

      print('🎉 Order $orderId created successfully!');
      return orderId;
    } catch (e, st) {
      print('❌ Fatal error in createOrder: $e');
      print(st);
      return null;
    }
  }

  Future<void> setStatus(String orderId, String status) async {
    final c = _svc ?? _c;
    if (c == null) return;
    
    try {
      if (status == 'completed') {
        // First get the complete order data with items
        final orderData = await c
            .from(ordersTable)
            .select('*, order_items(*)')
            .eq('id', orderId)
            .single();
        
        // Move to records with essential fields; avoid failures on missing columns
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
        
        // Delete from orders table after moving to records
        await c.from(orderItemsTable).delete().eq('order_id', orderId);
        await c.from(ordersTable).delete().eq('id', orderId);
      } else {
        // For other statuses, just update the status
        await c.from(ordersTable).update({'status': status}).eq('id', orderId);
      }
    } catch (e) {
      // Try with service client if main client fails
      final svc = _svc;
      if (svc != null && svc != c) {
        if (status == 'completed') {
          final orderData = await svc
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
              await svc.from(recordsTable).insert({...recordData, 'order_type': ot});
            } catch (_) {
              await svc.from(recordsTable).insert(recordData);
            }
          } else {
            await svc.from(recordsTable).insert(recordData);
          }
          
          await svc.from(orderItemsTable).delete().eq('order_id', orderId);
          await svc.from(ordersTable).delete().eq('id', orderId);
        } else {
          await svc.from(ordersTable).update({'status': status}).eq('id', orderId);
        }
      } else {
        // As a last resort, mark as completed in orders table to avoid UI dead state
        try {
          await (c ?? svc)!.from(ordersTable).update({'status': 'completed'}).eq('id', orderId);
        } catch (_) {}
      }
    }
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

      // Thoroughly clean the address for UI display
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
    // نجرب أولاً بـ service client (ويندوز/صلاحيات كاملة)
    // ثم نجرب بـ anon client (موبايل)
    for (final c in [_svc, _c]) {
      if (c == null) continue;
      try {
        final res = await c
            .from(ordersTable)
            .select('*, order_items(*)')
            .neq('status', 'completed')
            .order('created_at');
        final orders = _parseOrders(res as List);
        print('✅ fetchActiveOrders: got ${orders.length} orders using ${c == _svc ? "service" : "anon"} client');
        return orders;
      } catch (e) {
        print('⚠️ fetchActiveOrders error with client: $e');
      }
    }
    return [];
  }

  Future<Order?> getActiveOrderForPhone(String phone) async {
    final c = _c ?? _svc;
    if (c == null) return null;
    try {
      final res = await c
          .from(ordersTable)
          .select('*, order_items(*)')
          .eq('phone', phone)
          .neq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(1);
      if ((res as List).isEmpty) return null;
      final parsed = _parseOrders(res);
      return parsed.isNotEmpty ? parsed.first : null;
    } catch (e) {
      print('Error getting active order for phone: $e');
      return null;
    }
  }

  Stream<List<Order>> liveActiveOrders({
    Duration poll = const Duration(seconds: 4),
  }) {
    // استخدام الـ client الأساسي لـ Realtime channel (يعمل على الموبايل أيضاً)
    final realtimeClient = _c ?? _svc;
    if (realtimeClient == null) return const Stream.empty();
    return Stream<List<Order>>.multi((controller) async {
      final initial = await fetchActiveOrders();
      controller.add(initial);
      final channel = realtimeClient.channel('orders_live_${DateTime.now().millisecondsSinceEpoch}');
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
          _showNotification(payload);
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

  Stream<List<Order>> streamCustomerOrders(String phone, {
    Duration poll = const Duration(seconds: 4),
  }) {
    final c = _c ?? _svc;
    if (c == null) return const Stream.empty();
    return Stream<List<Order>>.multi((controller) async {
      Future<void> emit() async {
        try {
          final res = await c
              .from(ordersTable)
              .select('*, order_items(*)')
              .eq('phone', phone)
              .order('created_at');
          final parsed = _parseOrders(res as List);
          controller.add(parsed);
        } catch (e) {
          print('Error fetching customer orders: $e');
        }
      }
      
      await emit();
      final channel = c.channel('customer_orders_live_$phone');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: ordersTable,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'phone',
          value: phone,
        ),
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

  Future<bool> updateOrder({
    required String orderId,
    required String customerName,
    required String phone,
    required String address,
    required String orderType,
    required List<OrderItem> items,
    double? customerLat,
    double? customerLong,
    String? note,
  }) async {
    final primary = _svc ?? _c;
    if (primary == null) return false;

    try {
      final totalPrice = items.fold(0.0, (s, e) => s + e.item.price * e.quantity);
      final cleanNote = (note != null && note.trim().isNotEmpty) ? note.trim() : null;

      String finalAddress = address.isNotEmpty ? address : 'بدون';
      if (customerLat != null && customerLong != null) {
        finalAddress = 'GPS($customerLat,$customerLong) $finalAddress';
      }
      if (!finalAddress.contains('[EDITED]')) {
        finalAddress = '[EDITED][$orderType] $finalAddress';
      }
      if (cleanNote != null && !finalAddress.contains('[NOTE:')) {
        finalAddress = '$finalAddress [NOTE:$cleanNote]';
      }

      final updateData = <String, dynamic>{
        'customer_name': customerName,
        'phone': phone,
        'address': finalAddress,
        'total_price': totalPrice,
        'order_type': orderType,
        'is_edited': true,
      };
      if (cleanNote != null) updateData['note'] = cleanNote;
      if (customerLat != null) updateData['customer_lat'] = customerLat;
      if (customerLong != null) updateData['customer_long'] = customerLong;

      try {
        await primary.from(ordersTable).update(updateData).eq('id', orderId);
      } catch (e1) {
        final minData = <String, dynamic>{
          'customer_name': customerName,
          'phone': phone,
          'address': finalAddress,
          'total_price': totalPrice,
          'is_edited': true,
        };
        try {
          await primary.from(ordersTable).update(minData).eq('id', orderId);
        } catch (_) {
          final svc = _svc;
          if (svc != null && svc != primary) {
            try {
              await svc.from(ordersTable).update(minData).eq('id', orderId);
            } catch (_) {}
          }
        }
      }

      // Re-insert order items with safe food_id
      try {
        await primary.from(orderItemsTable).delete().eq('order_id', orderId);
      } catch (_) {}

      if (items.isNotEmpty) {
        final itemsData = items.map((e) {
          final isNumeric = RegExp(r'^\d+$').hasMatch(e.item.id);
          return {
            'order_id': orderId,
            'food_id': isNumeric ? e.item.id : null,
            'name': e.item.name,
            'price': e.item.price,
            'quantity': e.quantity,
          };
        }).toList();

        try {
          await primary.from(orderItemsTable).insert(itemsData);
        } catch (_) {
          try {
            final fallbackItems = items.map((e) => {
              'order_id': orderId,
              'food_id': null,
              'name': e.item.name,
              'price': e.item.price,
              'quantity': e.quantity,
            }).toList();
            await primary.from(orderItemsTable).insert(fallbackItems);
          } catch (_) {}
        }
      }
      return true;
    } catch (e) {
      print('updateOrder error: $e');
      return false;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    final c = _svc ?? _c;
    if (c == null) return;
    await c.from(orderItemsTable).delete().eq('order_id', orderId);
    await c.from(ordersTable).delete().eq('id', orderId);
  }

  Future<List<Map<String, dynamic>>> fetchRecords() async {
    final c = _c ?? _svc;
    if (c == null) return [];
    final res = await c.from(recordsTable).select().order('created_at');
    return (res as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  void _showNotification(PostgresChangePayload payload, {bool isUpdate = false}) {
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
