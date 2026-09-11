import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category_model.dart';
import '../supabase_client.dart';

class CategoryRepository {
  SupabaseClient? get _c => SupabaseManager.client;

  Future<List<CategoryModel>> getAllCategories() async {
    final c = _c;
    if (c == null) return [];
    try {
      final response = await c
          .from('categories')
          .select()
          .order('id', ascending: true);
      return (response as List)
          .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      print('Error fetching categories via SDK: $e');
      return [];
    }
  }

  Stream<List<CategoryModel>> streamCategories() {
    return Stream<List<CategoryModel>>.multi((controller) async {
      List<CategoryModel> currentCats = [];

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
