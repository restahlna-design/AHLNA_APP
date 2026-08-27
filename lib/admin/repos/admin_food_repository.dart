import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food_item.dart';
import '../../core/supabase_client.dart';

class AdminFoodRepository {
  static const table = 'food_items';
  SupabaseClient? get _c => SupabaseManager.client;
  Box? get _box => Hive.isBoxOpen('food_cache_v2') ? Hive.box('food_cache_v2') : null;

  Future<bool> add(FoodItem item) async {
    final c = _c;
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
    final c = _c;
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
    final c = _c;
    if (c == null) return false;
    try {
      final row = await c.from(table).select().eq('id', id).maybeSingle();
      await c.from(table).delete().eq('id', id);
      if (row != null) {
        final cat = Map<String, dynamic>.from(row)['category']?.toString() ?? '';
        if (cat.isNotEmpty) {
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
