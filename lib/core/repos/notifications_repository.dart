import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notification_model.dart';
import '../supabase_client.dart';

class NotificationsRepository {
  SupabaseClient? get _c => SupabaseManager.client;

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
    return [];
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
                },
              );
          controller.onCancel = () => sub.cancel();
        } catch (e) {
          print('⚠️ Notifications WebSocket setup error: $e');
        }
      }
    }, isBroadcast: true);
  }
}
