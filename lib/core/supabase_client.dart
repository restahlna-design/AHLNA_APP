import 'package:supabase_flutter/supabase_flutter.dart';

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
    final url = SupabaseConfig.supabaseUrl;
    final key = SupabaseConfig.supabaseAnonKey;
    
    if (url.isNotEmpty && key.isNotEmpty) {
      try {
        await Supabase.initialize(url: url, anonKey: key);
      } catch (e) {
        print('⚠️ Supabase initialize error: $e');
      }
    }
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
