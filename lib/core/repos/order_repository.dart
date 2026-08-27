import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class OrderRepository {
  static const ordersTable = 'orders';
  static const orderItemsTable = 'order_items';
  static const recordsTable = 'order_records';

  SupabaseClient? get _c => SupabaseManager.client;

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

    // --- Primary: Standard Supabase SDK ---
    final primary = _c;
    if (primary != null) {
      try {
        await primary.from(ordersTable).insert(fullOrderData);
        orderInserted = true;
        print('✅ Order inserted with full data');
      } catch (e1) {
        print('⚠️ Full insert failed: $e1, retrying minimal data...');
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
          print('✅ Order inserted with minimal data fallback');
        } catch (_) {}
      }
    }

    // --- Fallback: Direct HTTPS REST (Standard secure TLS, Anon Key) ---
    if (!orderInserted) {
      final client = HttpClient();
      try {
        final url = SupabaseConfig.supabaseUrl;
        final anonKey = SupabaseConfig.supabaseAnonKey;

        final req = await client.postUrl(Uri.parse('$url/rest/v1/$ordersTable'));
        req.headers.set('apikey', anonKey);
        req.headers.set('Authorization', 'Bearer $anonKey');
        req.headers.set('Content-Type', 'application/json; charset=utf-8');
        req.headers.set('Prefer', 'return=representation');
        req.add(utf8.encode(jsonEncode(fullOrderData)));

        final resp = await req.close();
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          orderInserted = true;
          print('✅ Direct REST order insertion SUCCESS (${resp.statusCode})');
        } else {
          final minReq = await client.postUrl(Uri.parse('$url/rest/v1/$ordersTable'));
          minReq.headers.set('apikey', anonKey);
          minReq.headers.set('Authorization', 'Bearer $anonKey');
          minReq.headers.set('Content-Type', 'application/json; charset=utf-8');
          minReq.headers.set('Prefer', 'return=representation');
          minReq.add(utf8.encode(jsonEncode({
            'id': orderId,
            'customer_name': customerName,
            'phone': phone,
            'address': finalAddress,
            'status': 'pending',
            'total_price': totalPrice,
            'created_at': now,
          })));
          final minResp = await minReq.close();
          if (minResp.statusCode >= 200 && minResp.statusCode < 300) {
            orderInserted = true;
            print('✅ Minimal REST order insertion SUCCESS');
          }
        }
      } catch (httpErr) {
        print('❌ Direct HTTP error: $httpErr');
      } finally {
        client.close();
      }
    }

    if (!orderInserted) {
      print('❌ All order insert mechanisms failed for order $orderId');
      return null;
    }

    // --- INSERT ORDER ITEMS ---
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

      bool itemsInserted = false;
      if (primary != null) {
        try {
          await primary.from(orderItemsTable).insert(itemsData);
          itemsInserted = true;
          print('✅ Order items inserted via SDK');
        } catch (_) {}
      }

      if (!itemsInserted) {
        final client = HttpClient();
        try {
          final url = SupabaseConfig.supabaseUrl;
          final anonKey = SupabaseConfig.supabaseAnonKey;

          final req = await client.postUrl(Uri.parse('$url/rest/v1/$orderItemsTable'));
          req.headers.set('apikey', anonKey);
          req.headers.set('Authorization', 'Bearer $anonKey');
          req.headers.set('Content-Type', 'application/json; charset=utf-8');
          req.headers.set('Prefer', 'return=representation');
          req.add(utf8.encode(jsonEncode(itemsData)));
          final resp = await req.close();
          if (resp.statusCode >= 200 && resp.statusCode < 300) {
            print('✅ Order items inserted via Direct REST');
          }
        } catch (_) {} finally {
          client.close();
        }
      }
    }

    print('🎉 Order $orderId created successfully!');
    return orderId;
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

  Future<Order?> getActiveOrderForPhone(String phone) async {
    final c = _c;
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

  Stream<List<Order>> streamCustomerOrders(String phone, {
    Duration poll = const Duration(seconds: 4),
  }) {
    final c = _c;
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
    final primary = _c;
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
        await primary.from(ordersTable).update(minData).eq('id', orderId);
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
          final fallbackItems = items.map((e) => {
            'order_id': orderId,
            'food_id': null,
            'name': e.item.name,
            'price': e.item.price,
            'quantity': e.quantity,
          }).toList();
          await primary.from(orderItemsTable).insert(fallbackItems);
        }
      }
      return true;
    } catch (e) {
      print('updateOrder error: $e');
      return false;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    final c = _c;
    if (c == null) return;
    try {
      await c.from(orderItemsTable).delete().eq('order_id', orderId);
      await c.from(ordersTable).delete().eq('id', orderId);
    } catch (_) {}
  }
}
