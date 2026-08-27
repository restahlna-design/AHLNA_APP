import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../supabase_client.dart';

class ProfileRepository {
  static const table = 'profiles';
  SupabaseClient? get _c => SupabaseManager.client;

  Future<bool> upsert({
    required String phone,
    required String name,
    required String address,
    String? user,
  }) async {
    final c = _c;
    if (c == null) {
      debugPrint('ProfileRepository: Supabase client is null');
      return false;
    }
    
    try {
      debugPrint('ProfileRepository: Checking existing profile by phone: $phone');
      final existing = await c.from(table).select('phone').eq('phone', phone).maybeSingle();
      if (existing != null) {
        debugPrint('ProfileRepository: Profile exists, performing direct update...');
        await c.from(table).update({
          'name': name,
          'address': address,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('phone', phone);
        return true;
      } else {
        debugPrint('ProfileRepository: Profile new, performing direct insert...');
        await c.from(table).insert({
          'phone': phone,
          'name': name,
          'address': address,
          'user': user ?? phone,
          'user_id_text': user ?? phone,
          'updated_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('ProfileRepository: Insert/Update failed ($e), attempting upsert fallback...');
      try {
        await c.from(table).upsert({
          'phone': phone,
          'name': name,
          'address': address,
          'user': user ?? phone,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'phone');
        return true;
      } catch (upsertErr) {
        debugPrint('ProfileRepository: Upsert also failed: $upsertErr');
      }
    }
    return false;
  }

  Future<Map<String, dynamic>?> getByPhone(String phone) async {
    final c = _c;
    if (c == null) return null;
    try {
      final res = await c.from(table).select().eq('phone', phone).maybeSingle();
      if (res == null) return null;
      return Map<String, dynamic>.from(res);
    } catch (e) {
      debugPrint('ProfileRepository getByPhone error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getByUser(String userId) async {
    final c = _c;
    if (c == null) return null;
    try {
      final res = await c.from(table).select().eq('user', userId).maybeSingle();
      if (res == null) return null;
      return Map<String, dynamic>.from(res);
    } catch (e) {
      debugPrint('ProfileRepository getByUser error: $e');
      return null;
    }
  }

  Future<bool> delete(String phone) async {
    final c = _c;
    if (c == null) return false;
    try {
      await c.from(table).delete().eq('phone', phone);
      return true;
    } catch (e) {
      debugPrint('ProfileRepository delete error: $e');
      return false;
    }
  }
}
