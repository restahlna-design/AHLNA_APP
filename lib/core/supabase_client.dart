import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage.dart';
import 'dart:io';

class SupabaseConfig {
  static const _envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static String get supabaseUrl => _envUrl.isNotEmpty ? _envUrl : 'https://boylzidmvvldouxtrpiv.supabase.co';

  static const _envAnon = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static String get supabaseAnonKey => _envAnon.isNotEmpty ? _envAnon : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0';

  static const _envSvc = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');
  static String get supabaseServiceKey => _envSvc.isNotEmpty ? _envSvc : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2Mzg0NDQ2OCwiZXhwIjoyMDc5NDIwNDY4fQ.GnddzO4SFff1ze0pdvmk-X-FKxpn9ajdm5Q4hjbiGoY';
}

class SupabaseManager {
  static bool _initialized = false;
  static String _svcUrl = '';
  static String _svcKey = '';

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
      // Persist for future debug runs without dart-define
      await Storage.saveSupabaseConfig(url: url, anonKey: key);
    }

    // Resolve service role key and cache it for runtime use
    _svcUrl = url.isNotEmpty ? url : SupabaseConfig.supabaseUrl;
    _svcKey = SupabaseConfig.supabaseServiceKey;
    if (_svcKey.isEmpty) {
      _svcKey = await Storage.loadSupabaseServiceKey();
    } else {
      await Storage.saveSupabaseServiceKey(serviceKey: _svcKey);
    }
    if (_svcKey.isEmpty) {
      try {
        final cwd = Directory.current.path;
        final f1 = File('$cwd/requirements/supabase_service_key.txt');
        final f2 = File('$cwd/supabase_service_key.txt');
        String k = '';
        if (await f1.exists()) {
          k = await f1.readAsString();
        } else if (await f2.exists()) {
          k = await f2.readAsString();
        }
        final trimmed = k.trim();
        if (trimmed.isNotEmpty) {
          _svcKey = trimmed;
          await Storage.saveSupabaseServiceKey(serviceKey: _svcKey);
        }
      } catch (_) {}
    }
    _initialized = true;
  }

  static Future<void> reconfigure({
    required String url,
    required String anonKey,
    String? serviceKey,
  }) async {
    await Storage.saveSupabaseConfig(url: url, anonKey: anonKey);
    if (serviceKey != null && serviceKey.isNotEmpty) {
      await Storage.saveSupabaseServiceKey(serviceKey: serviceKey);
    }
    _svcUrl = url;
    if (serviceKey != null && serviceKey.isNotEmpty) {
      _svcKey = serviceKey;
    }
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

  static SupabaseClient? get serviceClient {
    final url = _svcUrl.isNotEmpty ? _svcUrl : SupabaseConfig.supabaseUrl;
    final svc = _svcKey.isNotEmpty ? _svcKey : SupabaseConfig.supabaseServiceKey;
    if (url.isEmpty || svc.isEmpty) return null;
    return SupabaseClient(url, svc);
  }
}
