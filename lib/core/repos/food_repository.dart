import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/food_item.dart';
import '../supabase_client.dart';

class FoodRepository {
  static const table = 'food_items';

  SupabaseClient? get _c => SupabaseManager.client;
  Box? get _box => Hive.isBoxOpen('food_cache_v3') ? Hive.box('food_cache_v3') : null;

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

  List<FoodItem> getCachedItems() {
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

  Future<List<FoodItem>> fetchByCategory(String category) async {
    final c = _c;
    if (c != null) {
      try {
        final res = await c
            .from(table)
            .select()
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 4));
        final items = _parseItems(res as List?);
        if (items.isNotEmpty) {
          // Cache the results
          try {
            final box = _box;
            await box?.put('__ALL__', res);
          } catch (_) {}
          return filterByCategory(items, category);
        }
      } catch (e) {
        print('⚠️ SDK fetch failed: $e');
      }
    }

    // Hive cache fallback
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

    return filterByCategory(_defaultFallbackItems, category);
  }

  Future<List<FoodItem>> fetchByCategoryFresh(String category) =>
      fetchByCategory(category);

  static const List<FoodItem> defaultFallbackItems = _defaultFallbackItems;
  static const List<FoodItem> _defaultFallbackItems = [
    FoodItem(
      id: '1765207284918',
      name: 'مارغريتا كبير',
      price: 3000.0,
      description: 'بيتزا مارغريتا شهية مع الجبن والمكونات الطازجة',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/pizza.png',
      category: 'مارغريتا',
      isAvailable: true,
      variants: [
        FoodVariant(name: 'صغير', price: 3000.0),
        FoodVariant(name: 'وسط', price: 4000.0),
        FoodVariant(name: 'كبير', price: 6000.0),
      ],
    ),
    FoodItem(
      id: '1765197555135',
      name: 'بيتزا لحم كبير',
      price: 5000.0,
      description: 'بيتزا لحم مع الخضار والجبن الفاخر',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/pizza_meat.png',
      category: 'بيتزا لحم',
      isAvailable: true,
      variants: [
        FoodVariant(name: 'صغير', price: 9000.0),
        FoodVariant(name: 'وسط', price: 6000.0),
        FoodVariant(name: 'كبير', price: 5000.0),
      ],
    ),
    FoodItem(
      id: '1765197555136',
      name: 'بيتزا دجاج وسط',
      price: 4500.0,
      description: 'بيتزا دجاج شهية مع الجبن والمكونات الطازجة',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/pizza.png',
      category: 'بيتزا دجاج',
      isAvailable: true,
    ),
    FoodItem(
      id: '1765197555137',
      name: 'لحم بالعجين اعتيادي',
      price: 1000.0,
      description: 'طعم عراقي أصيل من قلب داقوق، محضر بأجود أنواع اللحوم',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/pizza_meat.png',
      category: 'لحم بعجين',
      isAvailable: true,
    ),
    FoodItem(
      id: '1765197555138',
      name: 'بركَر هوم',
      price: 4000.0,
      description: 'برجر لحم فاخر محضر طازجاً يومياً',
      imageUrl: 'https://boylzidmvvldouxtrpiv.supabase.co/storage/v1/object/public/food_images/pizza.png',
      category: 'بركَر',
      isAvailable: true,
      variants: [
        FoodVariant(name: 'وجبه', price: 5500.0),
        FoodVariant(name: 'عادي', price: 4000.0),
      ],
    ),
  ];

  Future<List<FoodItem>> fetchAllFresh() async {
    final c = _c;
    if (c != null) {
      try {
        final res = await c
            .from(table)
            .select()
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 4));
        final items = _parseItems(res as List?);
        if (items.isNotEmpty) {
          // Cache the results
          try {
            final box = _box;
            await box?.put('__ALL__', res);
          } catch (_) {}
          return items;
        }
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
      List<FoodItem> currentItems = getCachedItems();
      if (!controller.isClosed) {
        controller.add(currentItems);
      }

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
