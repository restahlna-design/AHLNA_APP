import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class FoodRepository {
  static const table = 'food_items';

  // Safe access to Hive box
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

  List<FoodItem> _parseItems(List<dynamic>? rows) {
    if (rows == null) return [];
    final List<FoodItem> items = [];
    for (var row in rows) {
      try {
        if (row is Map) {
          items.add(FoodItem.fromJson(Map<String, dynamic>.from(row)));
        }
      } catch (e) {
        print('⚠️ Error parsing FoodItem row on iOS/Android: $e | row: $row');
      }
    }
    return items;
  }

  List<FoodItem> _filterByCategory(List<FoodItem> items, String category) {
    if (category.isEmpty || category == '__ALL__') return items;
    final queries = category
        .split('|')
        .map((q) => q.trim().toLowerCase())
        .where((q) => q.isNotEmpty)
        .toList();
    if (queries.isEmpty) return items;
    return items.where((item) {
      final cat = item.category.trim().toLowerCase();
      return queries.any((q) => cat == q || cat.contains(q) || q.contains(cat));
    }).toList();
  }

  Future<List<FoodItem>> fetchByCategory(String category) async {
    final c = _svc ?? _c;

    // 1. ALWAYS try direct live database fetch first for real-time accuracy!
    if (c != null) {
      try {
        return await _fetchAndCache(c, category);
      } catch (e) {
        print('⚠️ Live fetch failed for $category: $e, checking cache...');
      }
    }

    // 2. Fallback to cache ONLY if offline or live query failed
    final box = _box;
    if (box != null) {
      final cachedData = box.get('__ALL__') ?? box.get(category);
      if (cachedData != null) {
        try {
          final List<dynamic> decoded = cachedData;
          final items = _parseItems(decoded);
          return _filterByCategory(items, category);
        } catch (e) {
          print('⚠️ Error parsing cache for $category: $e');
        }
      }
    }

    return [];
  }

  Future<List<FoodItem>> fetchByCategoryFresh(String category) async {
    final c = _svc ?? _c;
    if (c == null) {
      return await fetchByCategory(category);
    }
    try {
      return await _fetchAndCache(c, category);
    } catch (e) {
      print('⚠️ fetchByCategoryFresh error: $e');
      return await fetchByCategory(category);
    }
  }

  Future<List<FoodItem>> fetchAllFresh() async {
    final svc = _svc;
    final anon = _c;
    List<dynamic>? res;

    // 1. Try Service Client first (Admin privileges)
    if (svc != null) {
      try {
        print('🔄 Fetching all items via Service Client...');
        res = await svc.from(table).select().order('created_at', ascending: false);
        print('✅ Service Client success: ${res?.length ?? 0} items');
      } catch (e) {
        print('⚠️ Service client failed to fetch all items: $e');
      }
    }

    // 2. Fallback to Anon Client (Public data)
    if (res == null && anon != null) {
      try {
        print('🔄 Fetching all items via Anon Client...');
        res = await anon.from(table).select().order('created_at', ascending: false);
        print('✅ Anon Client success: ${res?.length ?? 0} items');
      } catch (e) {
        print('❌ Anon client failed to fetch all items: $e');
      }
    }

    // 3. Process Result & Update Cache
    if (res != null) {
      final box = _box;
      if (box != null) {
        await box.put('__ALL__', res);
      }
      return _parseItems(res);
    }

    // 4. Fallback to Cache if Network Failed
    print('⚠️ Network failed, falling back to cache for __ALL__');
    final box = _box;
    if (box != null) {
      final cached = box.get('__ALL__');
      if (cached != null) {
        try {
          final List<dynamic> decoded = cached;
          return _parseItems(decoded);
        } catch (e) {
          print('❌ Cache parse error: $e');
        }
      }
    }

    return [];
  }

  Future<void> _updateCacheInBackground(
    SupabaseClient? c,
    String category,
  ) async {
    if (c == null) return;
    try {
      await _fetchAndCache(c, category);
    } catch (_) {}
  }

  Future<List<FoodItem>> _fetchAndCache(
    SupabaseClient c,
    String category,
  ) async {
    print('🔍 Truly fetching ALL live items from database for category: $category');
    final res = await c
        .from(table)
        .select()
        .order('created_at', ascending: false);

    final box = _box;
    if (box != null) {
      await box.put('__ALL__', res);
    }

    final allItems = _parseItems(res as List?);
    final filtered = _filterByCategory(allItems, category);
    if (box != null && category.isNotEmpty && category != '__ALL__') {
      await box.put(category, filtered.map((e) => e.toJson()).toList());
    }
    print('✅ Truly fetched and matched ${filtered.length} live items for $category out of ${allItems.length} total items in DB');
    return filtered;
  }

  Stream<List<FoodItem>> streamByCategory(String category) {
    final c = _svc ?? _c;
    if (c == null) return const Stream.empty();
    return c
        .from(table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) {
          final box = _box;
          if (box != null) {
            box.put('__ALL__', rows);
          }
          final allItems = _parseItems(rows);
          final filtered = _filterByCategory(allItems, category);
          if (box != null && category.isNotEmpty && category != '__ALL__') {
            box.put(category, filtered.map((e) => e.toJson()).toList());
          }
          return filtered;
        })
        .asBroadcastStream();
  }

  Stream<List<FoodItem>> streamWithInitial(String category) {
    return Stream<List<FoodItem>>.multi((controller) async {
      // 1. Emit cached data immediately to avoid loading flash
      final box = _box;
      if (box != null) {
        final cachedData = box.get('__ALL__') ?? box.get(category);
        if (cachedData != null) {
          try {
            final List<dynamic> decoded = cachedData;
            final items = _parseItems(decoded);
            final filtered = _filterByCategory(items, category);
            if (filtered.isNotEmpty) {
              controller.add(filtered);
            }
          } catch (_) {}
        }
      }

      // 2. Fetch LIVE REAL-TIME fresh data directly from Supabase DB and emit immediately!
      try {
        final initial = await fetchByCategoryFresh(category);
        controller.add(initial);
      } catch (_) {}

      // 3. Listen to real-time WebSockets updates from Supabase DB
      final sub = streamByCategory(
        category,
      ).listen(controller.add, onError: controller.addError);
      controller.onCancel = () => sub.cancel();
    }, isBroadcast: true);
  }

  Stream<List<FoodItem>> liveByCategory(String category) {
    return streamWithInitial(category);
  }

  Future<bool> add(FoodItem item) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    try {
      int nextOrder = 0;
      // sort_order logic wrapped in try-catch
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
      // Remove sort_order if it causes issues.
      payload.remove('sort_order');

      final res = await c.from(table).insert(payload).select().maybeSingle();
      final ok = res != null;
      if (ok) {
        await _fetchAndCache(c, item.category);
      }
      return ok;
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
      payload.remove('sort_order'); // Safe removal

      final res = await c
          .from(table)
          .update(payload)
          .eq('id', item.id)
          .select();
      final ok = (res.isNotEmpty);
      if (ok) {
        await _fetchAndCache(c, item.category);
      }
      return ok;
    } catch (e) {
      print('Update failed: $e');
      return false;
    }
  }

  Future<bool> updateOrderForCategory(
    String category,
    List<FoodItem> ordered,
  ) async {
    // Save order locally in Hive since DB column is missing
    final box = _box;
    if (box == null) {
      print('⚠️ Cannot save order: Cache box not available');
      return false;
    }
    try {
      final ids = ordered.map((e) => e.id).toList();
      await box.put('order_$category', ids);
      print('📦 Saved local order for $category: $ids');
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
      if (ids is List) {
        return ids.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> delete(String id) async {
    final c = _svc ?? _c;
    if (c == null) return false;
    try {
      final row = await c.from(table).select().eq('id', id).maybeSingle();
      await c.from(table).delete().eq('id', id);

      // If we got here, delete was successful (or no-op if id not found, but we checked row)
      if (row != null) {
        final m = Map<String, dynamic>.from(row);
        final cat = m['category']?.toString() ?? '';
        if (cat.isNotEmpty) {
          await _fetchAndCache(c, cat);
        }
      }
      return true;
    } catch (e) {
      print('Delete failed: $e');
      return false;
    }
  }
}
