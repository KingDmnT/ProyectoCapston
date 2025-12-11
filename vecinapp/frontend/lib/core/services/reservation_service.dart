import 'package:vecinapp/core/services/api_service.dart';
import 'package:vecinapp/core/models/reservation.dart';

class ReservationService {
  final ApiService _apiService = ApiService();

  /// Crear nueva reserva (notifica automáticamente a todos los admins)
  Future<Reservation> createReservation(Reservation reservation) async {
    try {
      final response = await _apiService.post(
        '/reservations/',
        reservation.toJson(),
      );
      return Reservation.fromJson(response);
    } catch (e) {
      print('Error al crear reserva: $e');
      rethrow;
    }
  }

  /// Obtener todas las reservas de una comunidad
  Future<List<Reservation>> getReservations({
    required String communityId,
    String? spaceType,
    String? status,
    String? createdBy,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'community_id': communityId,
      };
      
      if (spaceType != null) queryParams['space_type'] = spaceType;
      if (status != null) queryParams['status'] = status;
      if (createdBy != null) queryParams['created_by'] = createdBy;
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final response = await _apiService.get(
        '/reservations/',
        queryParameters: queryParams,
      );

      if (response is List) {
        return response.map((json) => Reservation.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta inesperado');
    } catch (e) {
      print('Error al obtener reservas: $e');
      rethrow;
    }
  }

  /// Obtener una reserva por ID
  Future<Reservation> getReservationById({
    required String communityId,
    required String reservationId,
  }) async {
    try {
      final response = await _apiService.get(
        '/reservations/$reservationId',
        queryParameters: {'community_id': communityId},
      );
      return Reservation.fromJson(response);
    } catch (e) {
      print('Error al obtener reserva: $e');
      rethrow;
    }
  }

  /// Actualizar reserva (notifica automáticamente al creador)
  Future<Reservation> updateReservation({
    required String communityId,
    required String reservationId,
    ReservationStatus? status,
    String? adminNotes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status.value;
      if (adminNotes != null) body['admin_notes'] = adminNotes;

      final response = await _apiService.patch(
        '/reservations/$reservationId?community_id=$communityId',
        body,
      );
      return Reservation.fromJson(response);
    } catch (e) {
      print('Error al actualizar reserva: $e');
      rethrow;
    }
  }

  /// Cancelar/eliminar reserva
  Future<void> deleteReservation({
    required String communityId,
    required String reservationId,
  }) async {
    try {
      await _apiService.delete(
        '/reservations/$reservationId?community_id=$communityId',
      );
    } catch (e) {
      print('Error al eliminar reserva: $e');
      rethrow;
    }
  }
}
