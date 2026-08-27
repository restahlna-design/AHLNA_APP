import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_client.dart';

class AdminOffersRepository {
  static const table = 'offers';
  static const fallbackTable = 'app_settings';
  SupabaseClient? get _c => SupabaseManager.client;

  Future<void> setLink(String url) async {
    final c = _c;
    if (c == null) return;
    try {
      await c.from(table).upsert({
        'id': 'current',
        'url': url,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      try {
        await c.from(fallbackTable).upsert({
          'id': 'offers',
          'offer_image_url': url,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      } catch (_) {}
    }
  }

  Future<void> deleteLink() async {
    final c = _c;
    if (c == null) return;
    try {
      await c.from(table).delete().eq('id', 'current');
    } catch (e) {
      try {
        await c.from(fallbackTable).update({'offer_image_url': null}).eq('id', 'offers');
      } catch (_) {}
    }
  }
}
