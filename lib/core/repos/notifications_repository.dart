import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification_model.dart';
import '../supabase_client.dart';

class NotificationsRepository {
  static const _supabaseUrl = 'https://boylzidmvvldouxtrpiv.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJveWx6aWRtdnZsZG91eHRycGl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4NDQ0NjgsImV4cCI6MjA3OTQyMDQ2OH0.k-YInG1GfcBK6GQCjOuGMYcP_m2Eq7yTQSPuspCExr0';

  SupabaseClient? get _c => SupabaseManager.client;

  Future<List<NotificationModel>> _httpFetchNotifications() async {
    final client = HttpClient();
    try {
      final url = Uri.parse(
          '$_supabaseUrl/rest/v1/notifications?select=*&order=id.desc');
      final req = await client.getUrl(url);
      req.headers.set('apikey', _anonKey);
      req.headers.set('Authorization', 'Bearer $_anonKey');
      req.headers.set('Content-Type', 'application/json');

      final resp = await req.close().timeout(const Duration(seconds: 15));
      final body = await resp.transform(utf8.decoder).join();

      if (resp.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(body);
        return rows
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ HTTP Notifications fetch error: $e');
      return [];
    } finally {
      client.close();
    }
  }

  Future<List<NotificationModel>> fetchNotifications() async {
    final c = _c;
    if (c != null) {
      try {
        final response = await c
            .from('notifications')
            .select()
            .order('id', ascending: false);
        return (response as List)
            .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (e) {
        print('Error fetching notifications via SDK: $e');
      }
    }
    return await _httpFetchNotifications();
  }

  Stream<List<NotificationModel>> streamNotifications() {
    return Stream<List<NotificationModel>>.multi((controller) async {
      List<NotificationModel> currentList = [];

      try {
        final initial = await fetchNotifications();
        if (!controller.isClosed) {
          currentList = initial;
          controller.add(initial);
        }
      } catch (e) {
        print('⚠️ streamNotifications initial fetch error: $e');
      }

      final c = _c;
      if (c != null) {
        try {
          final sub = c
              .from('notifications')
              .stream(primaryKey: ['id'])
              .order('id', ascending: false)
              .map((data) => data
                  .map((e) =>
                      NotificationModel.fromJson(Map<String, dynamic>.from(e)))
                  .toList())
              .listen(
                (data) {
                  if (!controller.isClosed) {
                    currentList = data;
                    controller.add(data);
                  }
                },
                onError: (e) {
                  print('⚠️ Notifications WebSocket error: $e');
                  // On error, try periodic HTTP fetch fallback
                },
              );
          controller.onCancel = () => sub.cancel();
        } catch (e) {
          print('⚠️ Notifications WebSocket setup error: $e');
        }
      }
    }, isBroadcast: true);
  }

  Future<bool> sendNotification(String message, {String title = 'إشعار من الإدارة'}) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return false;

    final c = _c;
    if (c != null) {
      try {
        await c.from('notifications').insert({
          'title': title.trim().isEmpty ? 'إشعار من الإدارة' : title.trim(),
          'message': cleanMessage,
        });
        return true;
      } catch (e) {
        print('❌ SDK sendNotification error: $e');
      }
    }

    // HTTP Fallback
    final client = HttpClient();
    try {
      final key = SupabaseConfig.serviceRoleKey.isNotEmpty
          ? SupabaseConfig.serviceRoleKey
          : _anonKey;
      final url = Uri.parse('$_supabaseUrl/rest/v1/notifications');
      final req = await client.postUrl(url);
      req.headers.set('apikey', key);
      req.headers.set('Authorization', 'Bearer $key');
      req.headers.set('Content-Type', 'application/json');
      req.headers.set('Prefer', 'return=minimal');

      final payload = jsonEncode({
        'title': title.trim().isEmpty ? 'إشعار من الإدارة' : title.trim(),
        'message': cleanMessage,
      });
      req.add(utf8.encode(payload));

      final resp = await req.close().timeout(const Duration(seconds: 15));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      print('❌ HTTP sendNotification fallback error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  Future<bool> deleteNotification(int id) async {
    final c = _c;
    if (c != null) {
      try {
        await c.from('notifications').delete().eq('id', id);
        return true;
      } catch (e) {
        print('❌ SDK deleteNotification error: $e');
      }
    }

    // HTTP Fallback
    final client = HttpClient();
    try {
      final key = SupabaseConfig.serviceRoleKey.isNotEmpty
          ? SupabaseConfig.serviceRoleKey
          : _anonKey;
      final url = Uri.parse('$_supabaseUrl/rest/v1/notifications?id=eq.$id');
      final req = await client.deleteUrl(url);
      req.headers.set('apikey', key);
      req.headers.set('Authorization', 'Bearer $key');

      final resp = await req.close().timeout(const Duration(seconds: 15));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (e) {
      print('❌ HTTP deleteNotification fallback error: $e');
      return false;
    } finally {
      client.close();
    }
  }
}
