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
    final url = SupabaseConfig.supabaseUrl;
    final key = isAdmin ? SupabaseConfig.serviceRoleKey : SupabaseConfig.supabaseAnonKey;
    
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
