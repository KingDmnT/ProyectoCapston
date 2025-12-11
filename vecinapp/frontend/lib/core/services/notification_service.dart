import 'package:vecinapp/core/services/api_service.dart';
import 'package:vecinapp/core/models/notification.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  /// Obtener notificaciones del usuario actual
  Future<List<AppNotification>> getMyNotifications({
    required String communityId,
    bool? isRead,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'community_id': communityId,
        'limit': limit.toString(),
      };
      
      if (isRead != null) queryParams['is_read'] = isRead.toString();

      final response = await _apiService.get(
        '/notifications/me',
        queryParameters: queryParams,
      );

      if (response is List) {
        return response.map((json) => AppNotification.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta inesperado');
    } catch (e) {
      print('Error al obtener notificaciones: $e');
      rethrow;
    }
  }

  /// Marcar notificación como leída
  Future<AppNotification> markAsRead({
    required String communityId,
    required String notificationId,
  }) async {
    try {
      final response = await _apiService.patch(
        '/notifications/$notificationId/read?community_id=$communityId',
        {},
      );
      return AppNotification.fromJson(response);
    } catch (e) {
      print('Error al marcar notificación como leída: $e');
      rethrow;
    }
  }

  /// Obtener número de notificaciones no leídas
  Future<int> getUnreadCount({
    required String communityId,
  }) async {
    try {
      final response = await _apiService.get(
        '/notifications/unread-count',
        queryParameters: {'community_id': communityId},
      );
      return response['unread_count'] ?? 0;
    } catch (e) {
      print('Error al obtener contador de no leídas: $e');
      rethrow;
    }
  }
}
