import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class FoodRepository {
  static const table = 'food_items';
  static const _supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0';

  SupabaseClient? get _c => SupabaseManager.client;
  Box? get _box => Hive.isBoxOpen('food_cache_v2') ? Hive.box('food_cache_v2') : null;

  Future<List<FoodItem>> _httpFetchAll() async {
    final client = HttpClient();
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
        final items = _parseItems(rows);
        if (items.isNotEmpty) {
          try {
            final box = _box;
            await box?.put('__ALL__', rows);
          } catch (_) {}
        }
        return items;
      } else {
        return [];
      }
    } catch (e) {
      print('❌ HTTP fetchAll error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  List<FoodItem> _parseItems(List<dynamic>? rows) {
    if (rows == null) return [];
    final List<FoodItem> items = [];
    for (var row in rows) {
      try {
        if (row is Map) {
          final map = row.map((k, v) => MapEntry(k.toString(), v));
          items.add(FoodItem.fromJson(map));
        }
      } catch (e) {
        print('⚠️ Error parsing FoodItem row: $e');
      }
    }
    return items;
  }

  List<FoodItem> filterByCategory(List<FoodItem> items, String category) {
    if (items.isEmpty) return [];
    if (category.isEmpty || category == '__ALL__') return items;

    final nameEn = category.split('|').first.trim().toLowerCase();
    final nameAr = category.contains('|')
        ? category.split('|').last.trim().toLowerCase()
        : '';

    return items.where((item) {
      final cat = item.category.trim().toLowerCase();
      if (cat.isEmpty) return false;
      return cat == nameEn || (nameAr.isNotEmpty && cat == nameAr);
    }).toList();
  }

  Future<List<FoodItem>> fetchByCategory(String category) async {
    final all = await _httpFetchAll();
    if (all.isNotEmpty) {
      return filterByCategory(all, category);
    }

    final c = _c;
    if (c != null) {
      try {
        final res = await c.from(table).select().order('created_at', ascending: false);
        final items = _parseItems(res as List?);
        if (items.isNotEmpty) {
          return filterByCategory(items, category);
        }
      } catch (e) {
        print('⚠️ SDK fetch failed: $e');
      }
    }

    final box = _box;
    if (box != null) {
      final cached = box.get('__ALL__') ?? box.get(category);
      if (cached != null) {
        try {
          final items = _parseItems(List.from(cached));
          if (items.isNotEmpty) {
            return filterByCategory(items, category);
          }
        } catch (_) {}
      }
    }

    return [];
  }

  Future<List<FoodItem>> fetchByCategoryFresh(String category) =>
      fetchByCategory(category);

  static const List<FoodItem> defaultFallbackItems = _defaultFallbackItems;
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
  ];

  Future<List<FoodItem>> fetchAllFresh() async {
    final all = await _httpFetchAll();
    if (all.isNotEmpty) return all;

    final c = _c;
    if (c != null) {
      try {
        final res = await c.from(table).select().order('created_at', ascending: false);
        final items = _parseItems(res as List?);
        if (items.isNotEmpty) return items;
      } catch (e) {
        print('⚠️ SDK fetchAll failed: $e');
      }
    }

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

    return _defaultFallbackItems;
  }

  Stream<List<FoodItem>> streamAllFoodItems() {
    return Stream<List<FoodItem>>.multi((controller) async {
      List<FoodItem> currentItems = [];

      try {
        final initial = await fetchAllFresh();
        if (initial.isNotEmpty && !controller.isClosed) {
          currentItems = initial;
          controller.add(initial);
        }
      } catch (e) {
        print('⚠️ streamAllFoodItems initial fetch error: $e');
      }

      final c = _c;
      if (c != null) {
        try {
          final sub = c
              .from(table)
              .stream(primaryKey: ['id'])
              .map((rows) => _parseItems(rows))
              .listen(
                (data) {
                  if (!controller.isClosed) {
                    if (data.isNotEmpty || currentItems.isEmpty) {
                      currentItems = data;
                      controller.add(data);
                    }
                  }
                },
                onError: (e) => print('⚠️ WebSocket stream All error: $e'),
              );
          controller.onCancel = () => sub.cancel();
        } catch (e) {
          print('⚠️ WebSocket setup error: $e');
        }
      }
    }, isBroadcast: true);
  }

  Stream<List<FoodItem>> streamByCategory(String category) {
    final c = _c;
    if (c == null) return const Stream.empty();
    return c
        .from(table)
        .stream(primaryKey: ['id'])
        .map((rows) {
          final allItems = _parseItems(rows);
          final filtered = filterByCategory(allItems, category);
          return filtered;
        })
        .asBroadcastStream();
  }

  Stream<List<FoodItem>> streamWithInitial(String category) {
    return Stream<List<FoodItem>>.multi((controller) async {
      List<FoodItem> currentItems = [];

      try {
        final initial = await fetchByCategory(category);
        if (initial.isNotEmpty && !controller.isClosed) {
          currentItems = initial;
          controller.add(initial);
        }
      } catch (e) {
        print('⚠️ streamWithInitial initial fetch error: $e');
      }

      if (currentItems.isEmpty && !controller.isClosed) {
        currentItems = filterByCategory(_defaultFallbackItems, category);
        controller.add(currentItems);
      }

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
}
