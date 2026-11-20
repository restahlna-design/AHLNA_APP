import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/category_model.dart';
import '../supabase_client.dart';

class CategoryRepository {
  SupabaseClient? get _c => SupabaseManager.client;
  Box? get _box => Hive.isBoxOpen('categories_cache') ? Hive.box('categories_cache') : null;

  static const List<CategoryModel> defaultCategories = [
    CategoryModel(id: 2, nameEn: 'Lahm Bi Ajeen', nameAr: 'لحم بعجين'),
    CategoryModel(id: 3, nameEn: 'Pizza', nameAr: 'بيتزا'),
    CategoryModel(id: 4, nameEn: 'Drinks', nameAr: 'مشروبات'),
    CategoryModel(id: 5, nameEn: 'بيتزا دجاج', nameAr: 'بيتزا دجاج', parentId: 3),
    CategoryModel(id: 6, nameEn: 'بيتزا لحم', nameAr: 'بيتزا لحم', parentId: 3),
    CategoryModel(id: 36, nameEn: 'مارغريتا', nameAr: 'مارغريتا', parentId: 3),
    CategoryModel(id: 37, nameEn: 'شاورما', nameAr: 'شاورما'),
    CategoryModel(id: 38, nameEn: 'بركَر', nameAr: 'بركَر'),
    CategoryModel(id: 39, nameEn: 'مقبلات', nameAr: 'مقبلات'),
  ];

  List<CategoryModel> getCachedCategories() {
    final box = _box;
    if (box != null) {
      final cached = box.get('__CATS__');
      if (cached != null && cached is List) {
        try {
          final list = cached
              .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (list.isNotEmpty) return list;
        } catch (_) {}
      }
    }
    return defaultCategories;
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final c = _c;
    if (c != null) {
      try {
        final response = await c
            .from('categories')
            .select()
            .order('id', ascending: true)
            .timeout(const Duration(seconds: 4));
        final list = (response as List)
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isNotEmpty) {
          try {
            await _box?.put('__CATS__', response);
          } catch (_) {}
          return list;
        }
      } catch (e) {
        print('Error fetching categories via SDK: $e');
      }
    }
    return getCachedCategories();
  }

  Stream<List<CategoryModel>> streamCategories() {
    return Stream<List<CategoryModel>>.multi((controller) async {
      List<CategoryModel> currentCats = getCachedCategories();
      if (!controller.isClosed) {
        controller.add(currentCats);
      }

      try {
        final initial = await getAllCategories();
        if (initial.isNotEmpty && !controller.isClosed) {
          currentCats = initial;
          controller.add(initial);
        }
      } catch (e) {
        print('⚠️ streamCategories initial fetch error: $e');
      }

      final c = _c;
      if (c != null) {
        try {
          final sub = c
              .from('categories')
              .stream(primaryKey: ['id'])
              .order('id', ascending: true)
              .map((data) => data
                  .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList())
              .listen(
                (data) {
                  if (!controller.isClosed) {
                    if (data.isNotEmpty || currentCats.isEmpty) {
                      currentCats = data;
                      controller.add(data);
                    }
                  }
                },
                onError: (e) => print('⚠️ Categories WebSocket error: $e'),
              );
          controller.onCancel = () => sub.cancel();
        } catch (e) {
          print('⚠️ Categories WebSocket setup error: $e');
        }
      }
    }, isBroadcast: true);
  }
}
