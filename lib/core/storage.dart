import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static const _kRegistered = 'registered';
  static const _kName = 'name';
  static const _kPhone = 'phone';
  static const _kAddress = 'address';
  static const _kSupabaseUrl = 'supabase_url';
  static const _kSupabaseAnon = 'supabase_anon_key';
  static const _kTheme = 'theme_mode';
  static const _kProfileImage = 'profile_image_path';

  static Future<void> saveTheme(String theme) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTheme, theme);
  }

  static Future<String?> loadTheme() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kTheme);
  }

  static Future<bool> isRegistered() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRegistered) ?? false;
  }

  static Future<void> saveProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name);
    await p.setString(_kPhone, phone);
    await p.setString(_kAddress, address);
    await p.setBool(_kRegistered, true);
  }

  static Future<Map<String, String>> loadProfile() async {
    final p = await SharedPreferences.getInstance();
    return {
      'name': p.getString(_kName) ?? '',
      'phone': p.getString(_kPhone) ?? '',
      'address': p.getString(_kAddress) ?? '',
    };
  }

  static Future<void> saveSupabaseConfig({
    required String url,
    required String anonKey,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSupabaseUrl, url);
    await p.setString(_kSupabaseAnon, anonKey);
  }

  static Future<Map<String, String>> loadSupabaseConfig() async {
    final p = await SharedPreferences.getInstance();
    return {
      'url': p.getString(_kSupabaseUrl) ?? '',
      'anon': p.getString(_kSupabaseAnon) ?? '',
    };
  }

  static Future<void> saveProfileImage(String path) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kProfileImage, path);
  }

  static Future<String?> loadProfileImage() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kProfileImage);
  }

  static Future<void> clearUser() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kRegistered);
    await p.remove(_kName);
    await p.remove(_kPhone);
    await p.remove(_kAddress);
    await p.remove(_kProfileImage);
  }

  static Future<void> setString(String key, String value) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(key);
  }
}
