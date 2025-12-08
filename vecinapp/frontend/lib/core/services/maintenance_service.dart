import 'package:vecinapp/core/services/api_service.dart';
import 'package:vecinapp/core/models/maintenance.dart';

class MaintenanceService {
  final ApiService _apiService = ApiService();

  // Crear nuevo mantenimiento
  Future<Maintenance> createMaintenance(Maintenance maintenance) async {
    try {
      final response = await _apiService.post(
        '/maintenance',
        maintenance.toJson(),
      );
      return Maintenance.fromJson(response);
    } catch (e) {
      print('Error al crear mantenimiento: $e');
      rethrow;
    }
  }

  // Obtener todos los mantenimientos de una comunidad
  Future<List<Maintenance>> getMaintenances({
    required String communityId,
    String? type,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Construir query params
      final queryParams = <String, String>{
        'community_id': communityId,
      };
      
      if (type != null) queryParams['type'] = type;
      if (status != null) queryParams['status'] = status;
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await _apiService.get(
        '/maintenance',
        queryParameters: queryParams,
      );

      if (response is List) {
        return response.map((json) => Maintenance.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta inesperado');
    } catch (e) {
      print('Error al obtener mantenimientos: $e');
      rethrow;
    }
  }

  // Obtener un mantenimiento por ID
  Future<Maintenance> getMaintenanceById({
    required String communityId,
    required String maintenanceId,
  }) async {
    try {
      final response = await _apiService.get(
        '/maintenance/$maintenanceId',
        queryParameters: {'community_id': communityId},
      );
      return Maintenance.fromJson(response);
    } catch (e) {
      print('Error al obtener mantenimiento: $e');
      rethrow;
    }
  }

  // Actualizar mantenimiento
  Future<Maintenance> updateMaintenance({
    required String communityId,
    required String maintenanceId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      // Agregar community_id al cuerpo de la actualización
      final body = Map<String, dynamic>.from(updates);
      
      final response = await _apiService.put(
        '/maintenance/$maintenanceId?community_id=$communityId',
        body,
      );
      return Maintenance.fromJson(response);
    } catch (e) {
      print('Error al actualizar mantenimiento: $e');
      rethrow;
    }
  }

  // Actualizar estado de mantenimiento
  Future<Maintenance> updateMaintenanceStatus({
    required String communityId,
    required String maintenanceId,
    required MaintenanceStatus newStatus,
  }) async {
    try {
      final response = await _apiService.put(
        '/maintenance/$maintenanceId/status?community_id=$communityId&new_status=${newStatus.value}',
        {},
      );
      return Maintenance.fromJson(response);
    } catch (e) {
      print('Error al actualizar estado: $e');
      rethrow;
    }
  }

  // Aprobar mantenimiento
  Future<Maintenance> approveMaintenance({
    required String communityId,
    required String maintenanceId,
  }) async {
    try {
      final response = await _apiService.post(
        '/maintenance/$maintenanceId/approve?community_id=$communityId',
        {},
      );
      return Maintenance.fromJson(response);
    } catch (e) {
      print('Error al aprobar mantenimiento: $e');
      rethrow;
    }
  }

  // Rechazar mantenimiento
  Future<Maintenance> rejectMaintenance({
    required String communityId,
    required String maintenanceId,
  }) async {
    try {
      final response = await _apiService.post(
        '/maintenance/$maintenanceId/reject?community_id=$communityId',
        {},
      );
      return Maintenance.fromJson(response);
    } catch (e) {
      print('Error al rechazar mantenimiento: $e');
      rethrow;
    }
  }

  // Actualizar checklist
  Future<Maintenance> updateChecklist({
    required String communityId,
    required String maintenanceId,
    required List<ChecklistItem> checklistItems,
  }) async {
    try {
      final response = await _apiService.put(
        '/maintenance/$maintenanceId/checklist?community_id=$communityId',
        {'checklist_items': checklistItems.map((item) => item.toJson()).toList()},
      );
      return Maintenance.fromJson(response);
    } catch (e) {
      print('Error al actualizar checklist: $e');
      rethrow;
    }
  }

  // Eliminar mantenimiento
  Future<void> deleteMaintenance({
    required String communityId,
    required String maintenanceId,
  }) async {
    try {
      await _apiService.delete(
        '/maintenance/$maintenanceId?community_id=$communityId',
      );
    } catch (e) {
      print('Error al eliminar mantenimiento: $e');
      rethrow;
    }
  }
}
