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
}

class SupabaseManager {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    var url = SupabaseConfig.supabaseUrl;
    var key = SupabaseConfig.supabaseAnonKey;
    if (url.isEmpty || key.isEmpty) {
      final conf = await Storage.loadSupabaseConfig();
      url = conf['url'] ?? '';
      key = conf['anon'] ?? '';
    }
    if (url.isNotEmpty && key.isNotEmpty) {
      try {
        await Supabase.initialize(url: url, anonKey: key);
      } catch (e) {
        print('⚠️ Supabase initialize error: $e');
      }
      await Storage.saveSupabaseConfig(url: url, anonKey: key);
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
