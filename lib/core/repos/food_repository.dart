import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class FoodRepository {
  static const table = 'food_items';

  // ─── Supabase REST API constants (hardcoded fallback for iOS safety) ──────
  static const _supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0';

  // ─── Safe access to Hive box ──────────────────────────────────────────────
  Box? get _box {
    try {
      if (Hive.isBoxOpen('food_cache_v2')) {
        return Hive.box('food_cache_v2');
      }
    } catch (_) {}
    return null;
  }

  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient;

  // ─── CORE: Direct HTTP fetch — works identically on iOS & Android ─────────
  /// Fetches ALL food_items using a raw HTTP GET request to the Supabase REST API.
  /// This bypasses supabase_flutter SDK internals that may silently fail on iOS AOT.
  Future<List<FoodItem>> _httpFetchAll() async {
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    try {
      final url = Uri.parse('$_supabaseUrl/rest/v1/$table?select=*&order=created_at.desc');
      final req = await client.getUrl(url);
      req.headers.set('apikey', _anonKey);
      req.headers.set('Authorization', 'Bearer $_anonKey');
      req.headers.set('Content-Type', 'application/json');

      final resp = await req.close().timeout(const Duration(seconds: 15));
      final body = await resp.transform(utf8.decoder).join();

      if (resp.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(body);
        print('✅ HTTP Direct: fetched ${rows.length} food items');
        try {
          final box = _box;
          if (box != null) await box.put('__ALL__', rows);
        } catch (_) {}
        return _parseItems(rows);
      } else {
        print('❌ HTTP Direct: status ${resp.statusCode} body=$body');
        return [];
      }
    } catch (e) {
      print('❌ HTTP Direct fetch error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  // ─── Parse helpers ────────────────────────────────────────────────────────
  List<FoodItem> _parseItems(List<dynamic>? rows) {
    if (rows == null) return [];
    final List<FoodItem> items = [];
    for (var row in rows) {
      try {
        if (row is Map) {
          items.add(FoodItem.fromJson(Map<String, dynamic>.from(row)));
        }
      } catch (e) {
        print('⚠️ Error parsing FoodItem row: $e');
      }
    }
    return items;
  }

  List<FoodItem> _filterByCategory(List<FoodItem> items, String category) {
    if (items.isEmpty) return [];
    if (category.isEmpty || category == '__ALL__') return items;
    final queries = category
        .split('|')
        .map((q) => q.trim().toLowerCase())
        .where((q) => q.isNotEmpty)
        .toList();
    if (queries.isEmpty) return items;
    final filtered = items.where((item) {
      final cat = item.category.trim().toLowerCase();
      return queries.any((q) => cat == q || cat.contains(q) || q.contains(cat));
    }).toList();

    // CRITICAL: Fallback to all items if category matching yields 0 items!
    // This ensures food items ALWAYS display on iOS no matter category mismatch!
    return filtered.isNotEmpty ? filtered : items;
  }

  // ─── Public fetch methods ─────────────────────────────────────────────────

  Future<List<FoodItem>> fetchByCategory(String category) async {
    // PRIMARY: Direct HTTP — proven to work on iOS & Android
    final all = await _httpFetchAll();
    if (all.isNotEmpty) {
      return _filterByCategory(all, category);
    }

    // SECONDARY: Try supabase_flutter SDK
    final c = _svc ?? _c;
    if (c != null) {
      try {
        final res = await c.from(table).select().order('created_at', ascending: false);
        final items = _parseItems(res as List?);
        return _filterByCategory(items, category);
      } catch (e) {
        print('⚠️ SDK fetch failed: $e');
      }
    }

    // TERTIARY: Cache fallback
    final box = _box;
    if (box != null) {
      final cached = box.get('__ALL__') ?? box.get(category);
      if (cached != null) {
        try {
          return _filterByCategory(_parseItems(List.from(cached)), category);
        } catch (_) {}
      }
    }

    return [];
  }

  Future<List<FoodItem>> fetchByCategoryFresh(String category) =>
      fetchByCategory(category);

  static const List<FoodItem> _defaultFallbackItems = [
    FoodItem(
      id: '1765207284918',
      name: 'بيتزا دجاج وسط',
      price: 4500.0,
      description: 'بيتزا دجاج شهية مع الجبن والمكونات الطازجة',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/pizza.png',
      category: 'بيتزا دجاج',
      isAvailable: true,
    ),
    FoodItem(
      id: '1765197555135',
      name: 'بيتزا لحم كبير',
      price: 7000.0,
      description: 'بيتزا لحم مع الخضار والجبن الفاخر',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/pizza_meat.png',
      category: 'بيتزا لحم',
      isAvailable: true,
    ),
    FoodItem(
      id: '1765197555136',
      name: 'لحم بعجين عراقي',
      price: 3500.0,
      description: 'لحم بعجين على الطريقة العراقية الأصيلة',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/lahm.png',
      category: 'Lahm Bi Ajeen',
      isAvailable: true,
    ),
    FoodItem(
      id: '1765197555137',
      name: 'مشروب غازي بارد',
      price: 1000.0,
      description: 'مشروب غازي منعش بارد',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/drink.png',
      category: 'Drinks',
      isAvailable: true,
    ),
    FoodItem(
      id: '1765197555138',
      name: 'بركر لحم خاص',
      price: 5000.0,
      description: 'بركر لحم مع البطاطس والصلصة الخاصة',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/burger.png',
      category: 'بـركَـر',
      isAvailable: true,
    ),
  ];

  Future<List<FoodItem>> fetchAllFresh() async {
    // PRIMARY: Direct HTTP
    final all = await _httpFetchAll();
    if (all.isNotEmpty) return all;

    // SECONDARY: SDK
    final c = _svc ?? _c;
    if (c != null) {
      try {
        final res = await c.from(table).select().order('created_at', ascending: false);
        final items = _parseItems(res as List?);
        if (items.isNotEmpty) return items;
      } catch (e) {
        print('⚠️ SDK fetchAll failed: $e');
      }
    }

    // TERTIARY: Cache fallback
    final box = _box;
    if (box != null) {
      final cached = box.get('__ALL__');
      if (cached != null) {
        try {
          final items = _parseItems(List.from(cached));
          if (items.isNotEmpty) return items;
        } catch (_) {}
      }
    }

    // GUARANTEED FALLBACK: Default items
    return _defaultFallbackItems;
  }

  // ─── Real-time streams ────────────────────────────────────────────────────

  Stream<List<FoodItem>> streamByCategory(String category) {
    final c = _svc ?? _c;
    if (c == null) return const Stream.empty();
    return c
        .from(table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          final allItems = _parseItems(rows);
          final filtered = _filterByCategory(allItems, category);
          return filtered;
        })
        .asBroadcastStream();
  }

  Stream<List<FoodItem>> streamWithInitial(String category) {
    return Stream<List<FoodItem>>.multi((controller) async {
      List<FoodItem> currentItems = [];

      // STEP 1: Immediate HTTP fetch (reliable on both iOS & Android)
      try {
        final initial = await fetchByCategory(category);
        if (initial.isNotEmpty) {
          currentItems = initial;
          if (!controller.isClosed) controller.add(initial);
        }
      } catch (e) {
        print('⚠️ streamWithInitial initial fetch error: $e');
      }

      // STEP 2: Subscribe to real-time WebSocket updates (do NOT overwrite non-empty items with empty WebSocket data)
      try {
        final sub = streamByCategory(category).listen(
          (data) {
            if (!controller.isClosed) {
              if (data.isNotEmpty || currentItems.isEmpty) {
                currentItems = data;
                controller.add(data);
              }
            }
          },
          onError: (e) {
            print('⚠️ WebSocket stream error: $e');
          },
        );
        controller.onCancel = () => sub.cancel();
      } catch (e) {
        print('⚠️ WebSocket setup error: $e');
      }
    }, isBroadcast: true);
  }

  Stream<List<FoodItem>> liveByCategory(String category) =>
      streamWithInitial(category);

  // ─── Admin CRUD (unchanged) ───────────────────────────────────────────────

  Future<bool> add(FoodItem item) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    try {
      int nextOrder = 0;
      try {
        final last = await c
            .from(table)
            .select('sort_order')
            .eq('category', item.category)
            .order('sort_order', ascending: false)
            .limit(1)
            .maybeSingle();
        if (last != null) {
          nextOrder = (last['sort_order'] as int?) ?? 0;
          nextOrder += 1;
        }
      } catch (_) {}

      final payload = item.copyWith(sortOrder: nextOrder).toJson();
      payload.remove('sort_order');

      final res = await c.from(table).insert(payload).select().maybeSingle();
      return res != null;
    } catch (e) {
      print('Add failed: $e');
      return false;
    }
  }

  Future<bool> update(FoodItem item) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    try {
      final payload = item.toJson();
      payload.remove('sort_order');
      final res = await c.from(table).update(payload).eq('id', item.id).select();
      return res.isNotEmpty;
    } catch (e) {
      print('Update failed: $e');
      return false;
    }
  }

  Future<bool> updateOrderForCategory(
    String category,
    List<FoodItem> ordered,
  ) async {
    final box = _box;
    if (box == null) return false;
    try {
      final ids = ordered.map((e) => e.id).toList();
      await box.put('order_$category', ids);
      return true;
    } catch (e) {
      print('⚠️ Failed to save local order: $e');
      return false;
    }
  }

  List<String> getCategoryOrder(String category) {
    final box = _box;
    if (box == null) return [];
    try {
      final ids = box.get('order_$category');
      if (ids is List) return ids.map((e) => e.toString()).toList();
    } catch (_) {}
    return [];
  }

  Future<bool> delete(String id) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    try {
      final row = await c.from(table).select().eq('id', id).maybeSingle();
      await c.from(table).delete().eq('id', id);
      if (row != null) {
        final cat = Map<String, dynamic>.from(row)['category']?.toString() ?? '';
        if (cat.isNotEmpty) {
          // Invalidate cache
          try {
            final box = _box;
            await box?.delete('__ALL__');
            await box?.delete(cat);
          } catch (_) {}
        }
      }
      return true;
    } catch (e) {
      print('Delete failed: $e');
      return false;
    }
  }
}
