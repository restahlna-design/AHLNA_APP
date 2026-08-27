import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class OffersRepository {
  static const table = 'offers';
  static const fallbackTable = 'app_settings';
  SupabaseClient? get _c => SupabaseManager.client;

  Future<String?> getLink() async {
    final c = _c;
    if (c == null) return null;
    try {
      final res = await c.from(table).select().eq('id', 'current').maybeSingle();
      if (res == null) return null;
      final m = Map<String, dynamic>.from(res);
      return m['url']?.toString();
    } catch (e) {
      try {
        final fb = await c.from(fallbackTable).select().maybeSingle();
        if (fb == null) return null;
        final fm = Map<String, dynamic>.from(fb);
        return fm['offer_image_url']?.toString();
      } catch (_) {
        return null;
      }
    }
  }

  Stream<String?> liveLink() {
    final c = _c;
    if (c == null) return const Stream.empty();
    return c
        .from(table)
        .stream(primaryKey: ['id'])
        .map((rows) {
          if (rows.isEmpty) return null;
          final first = Map<String, dynamic>.from(rows.first);
          return first['url']?.toString();
        })
        .asBroadcastStream();
  }
}
