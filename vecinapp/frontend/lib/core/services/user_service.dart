import 'package:vecinapp/core/services/api_service.dart';
import 'package:vecinapp/core/models/user.dart';

/// Servicio para gestión de usuarios desde el admin
class UserService {
  final ApiService _apiService = ApiService();

  /// Obtener todos los usuarios con filtros opcionales
  Future<List<AppUser>> getUsers({
    String? communityId,
    String? role,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{};
    if (communityId != null) queryParams['community_id'] = communityId;
    if (role != null) queryParams['role'] = role;
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    try {
      final response = await _apiService.get(
        '/users',
        queryParameters: queryParams,
      );

      // La respuesta es directamente una lista
      if (response is List) {
        return response.map((json) => AppUser.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta inesperado');
    } catch (e) {
      print('Error en getUsers: $e');
      rethrow;
    }
  }

  /// Obtener un usuario por ID
  Future<AppUser> getUserById(String userId) async {
    try {
      final response = await _apiService.get('/users/$userId');
      return AppUser.fromJson(response);
    } catch (e) {
      print('Error en getUserById: $e');
      rethrow;
    }
  }

  /// Crear un nuevo usuario
  Future<AppUser> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String rut,
    String? phone,
    String? role,
  }) async {
    try {
      final response = await _apiService.post('/users', {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'rut': rut,
        if (phone != null) 'phone': phone,
        if (role != null) 'role': role,
      });

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error en createUser: $e');
      rethrow;
    }
  }

  /// Actualizar un usuario existente
  Future<AppUser> updateUser(
    String userId, {
    String? firstName,
    String? lastName,
    String? phone,
    String? rut,
    String? role,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (lastName != null) data['last_name'] = lastName;
      if (phone != null) data['phone'] = phone;
      if (rut != null) data['rut'] = rut;
      if (role != null) data['role'] = role;

      final response = await _apiService.put('/users/$userId', data);
      return AppUser.fromJson(response);
    } catch (e) {
      print('Error en updateUser: $e');
      rethrow;
    }
  }

  /// Eliminar (desactivar) un usuario
  Future<void> deleteUser(String userId) async {
    try {
      await _apiService.delete('/users/$userId');
    } catch (e) {
      print('Error en deleteUser: $e');
      rethrow;
    }
  }

  /// Asignar usuario a una unidad
  Future<AppUser> assignUserToUnit({
    required String userId,
    required String communityId,
    required String unitId,
    List<String> roles = const ['resident'],  // FIX: lowercase 'resident'
  }) async {
    try {
      final response = await _apiService.post(
        '/users/$userId/assign-unit',
        {
          'community_id': communityId,
          'unit_id': unitId,
          'roles': roles,
        },
      );

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error en assignUserToUnit: $e');
      rethrow;
    }
  }


  /// Desasignar usuario de una comunidad (TODAS las unidades)
  Future<AppUser> unassignUserFromCommunity({
    required String userId,
    required String communityId,
  }) async {
    try {
      final response = await _apiService.delete(
        '/users/$userId/unassign-unit/$communityId',
      );

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error en unassignUserFromCommunity: $e');
      rethrow;
    }
  }

  /// Desasignar usuario de una unidad específica
  Future<AppUser> unassignUserFromUnit({
    required String userId,
    required String communityId,
    required String unitId,
  }) async {
    try {
      final response = await _apiService.delete(
        '/users/$userId/unassign-unit/$communityId/$unitId',
      );

      return AppUser.fromJson(response);
    } catch (e) {
      print('Error en unassignUserFromUnit: $e');
      rethrow;
    }
  }
}
