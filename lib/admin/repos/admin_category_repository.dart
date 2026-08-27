import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category_model.dart';
import '../../core/supabase_client.dart';

class AdminCategoryRepository {
  SupabaseClient? get _c => SupabaseManager.client;

  Future<void> addCategory(CategoryModel category) async {
    final c = _c;
    if (c == null) return;
    await c.from('categories').insert(category.toJson());
  }

  Future<void> updateCategory(CategoryModel category) async {
    final c = _c;
    if (c == null) return;
    await c
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id);
  }

  Future<void> deleteCategory(int id) async {
    final c = _c;
    if (c == null) return;
    await c.from('categories').delete().eq('id', id);
  }
}
