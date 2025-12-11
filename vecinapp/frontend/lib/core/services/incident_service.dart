import 'package:vecinapp/core/services/api_service.dart';
import 'package:vecinapp/core/models/incident.dart';

class IncidentService {
  final ApiService _apiService = ApiService();

  /// Crear nuevo incidente (notifica automáticamente a todos los admins)
  Future<Incident> createIncident(Incident incident) async {
    try {
      final response = await _apiService.post(
        '/incidents/',
        incident.toJson(),
      );
      return Incident.fromJson(response);
    } catch (e) {
      print('Error al crear incidente: $e');
      rethrow;
    }
  }

  /// Obtener todos los incidentes de una comunidad
  Future<List<Incident>> getIncidents({
    required String communityId,
    String? category,
    String? status,
    String? createdBy,
  }) async {
    try {
      final queryParams = <String, String>{
        'community_id': communityId,
      };
      
      if (category != null) queryParams['category'] = category;
      if (status != null) queryParams['status'] = status;
      if (createdBy != null) queryParams['created_by'] = createdBy;

      final response = await _apiService.get(
        '/incidents/',
        queryParameters: queryParams,
      );

      if (response is List) {
        return response.map((json) => Incident.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta inesperado');
    } catch (e) {
      print('Error al obtener incidentes: $e');
      rethrow;
    }
  }

  /// Obtener un incidente por ID
  Future<Incident> getIncidentById({
    required String communityId,
    required String incidentId,
  }) async {
    try {
      final response = await _apiService.get(
        '/incidents/$incidentId',
        queryParameters: {'community_id': communityId},
      );
      return Incident.fromJson(response);
    } catch (e) {
      print('Error al obtener incidente: $e');
      rethrow;
    }
  }

  /// Actualizar incidente (notifica automáticamente al creador)
  Future<Incident> updateIncident({
    required String communityId,
    required String incidentId,
    IncidentStatus? status,
    String? adminNotes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status.value;
      if (adminNotes != null) body['admin_notes'] = adminNotes;

      final response = await _apiService.patch(
        '/incidents/$incidentId?community_id=$communityId',
        body,
      );
      return Incident.fromJson(response);
    } catch (e) {
      print('Error al actualizar incidente: $e');
      rethrow;
    }
  }

  /// Eliminar incidente
  Future<void> deleteIncident({
    required String communityId,
    required String incidentId,
  }) async {
    try {
      await _apiService.delete(
        '/incidents/$incidentId?community_id=$communityId',
      );
    } catch (e) {
      print('Error al eliminar incidente: $e');
      rethrow;
    }
  }
}
