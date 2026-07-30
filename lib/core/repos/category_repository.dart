import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/category_model.dart';
import '../supabase_client.dart';

class CategoryRepository {
  static const _supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0';

  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient ?? _c;

  /// Exposes the service client for external use (e.g. bulk updates before category deletion)
  SupabaseClient? get supabaseClient => _svc;

  /// Direct HTTP fetch — bypasses supabase_flutter SDK, works on iOS AOT Release.
  Future<List<CategoryModel>> _httpFetchCategories() async {
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    try {
      final url = Uri.parse(
          '$_supabaseUrl/rest/v1/categories?select=*&order=id.asc');
      final req = await client.getUrl(url);
      req.headers.set('apikey', _anonKey);
      req.headers.set('Authorization', 'Bearer $_anonKey');
      req.headers.set('Content-Type', 'application/json');

      final resp = await req.close().timeout(const Duration(seconds: 15));
      final body = await resp.transform(utf8.decoder).join();

      if (resp.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(body);
        print('✅ HTTP Categories: fetched ${rows.length} categories');
        return rows
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        print('❌ HTTP Categories error: ${resp.statusCode} $body');
        return [];
      }
    } catch (e) {
      print('❌ HTTP Categories fetch error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  Future<List<CategoryModel>> getAllCategories() async {
    // PRIMARY: Direct HTTP (reliable on iOS & Android)
    final cats = await _httpFetchCategories();
    if (cats.isNotEmpty) return cats;

    // FALLBACK: supabase_flutter SDK
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

      // STEP 1: Immediate HTTP fetch
      try {
        final initial = await getAllCategories();
        if (initial.isNotEmpty && !controller.isClosed) {
          currentCats = initial;
          controller.add(initial);
        }
      } catch (e) {
        print('⚠️ streamCategories initial fetch error: $e');
      }

      // STEP 2: Real-time WebSocket updates (do NOT overwrite non-empty categories with empty WebSocket data)
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

  Future<void> addCategory(CategoryModel category) async {
    final svc = _svc;
    if (svc == null) return;
    await svc.from('categories').insert(category.toJson());
  }

  Future<void> updateCategory(CategoryModel category) async {
    final svc = _svc;
    if (svc == null) return;
    await svc
        .from('categories')
        .update(category.toJson())
        .eq('id', category.id);
  }

  Future<void> deleteCategory(int id) async {
    final svc = _svc;
    if (svc == null) return;
    await svc.from('categories').delete().eq('id', id);
  }
}
