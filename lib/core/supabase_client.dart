import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage.dart';

class SupabaseConfig {
  static const _envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static String get supabaseUrl =>
      _envUrl.isNotEmpty ? _envUrl : 'https://boylzidmvvldouxtrpiv.supabase.co';

  static const _envAnon = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static String get supabaseAnonKey =>
      _envAnon.isNotEmpty
          ? _envAnon
          : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0';

  static const _envService = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');
  static String get serviceRoleKey =>
      _envService.isNotEmpty
          ? _envService
          : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
}

class SupabaseManager {
  static bool _initialized = false;

  static Future<void> init({bool isAdmin = false}) async {
    if (_initialized) return;
    var url = SupabaseConfig.supabaseUrl;
    var key = isAdmin ? SupabaseConfig.serviceRoleKey : SupabaseConfig.supabaseAnonKey;
    if (url.isEmpty || key.isEmpty) {
      final conf = await Storage.loadSupabaseConfig();
      url = conf['url'] ?? '';
      key = isAdmin ? SupabaseConfig.serviceRoleKey : (conf['anon'] ?? '');
    }
    if (url.isNotEmpty && key.isNotEmpty) {
      try {
        await Supabase.initialize(url: url, anonKey: key);
      } catch (e) {
        print('⚠️ Supabase initialize error: ');
      }
      if (!isAdmin) {
        await Storage.saveSupabaseConfig(url: url, anonKey: key);
      }
    }
    _initialized = true;
  }

  static Future<void> reconfigure({
    required String url,
    required String anonKey,
  }) async {
    await Storage.saveSupabaseConfig(url: url, anonKey: anonKey);
    _initialized = false;
    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
