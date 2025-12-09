import 'package:vecinapp/core/services/api_service.dart';
import 'package:vecinapp/core/models/common_expense.dart';

class CommonExpenseService {
  final ApiService _apiService = ApiService();

  // ===========================
  // MÉTODOS PARA ADMINISTRADORES
  // ===========================

  /// Crear gasto común en borrador
  Future<CommonExpense> createCommonExpense(CommonExpense expense) async {
    try {
      final response = await _apiService.post(
        '/common-expenses',
        expense.toJson(),
      );
      return CommonExpense.fromJson(response);
    } catch (e) {
      print('Error al crear gasto común: $e');
      rethrow;
    }
  }

  /// Listar gastos comunes (admin)
  Future<List<CommonExpense>> getCommonExpenses({
    required String communityId,
    int? year,
    int? month,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'community_id': communityId,
      };

      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();
      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get(
        '/common-expenses',
        queryParameters: queryParams,
      );

      if (response is List) {
        return response.map((json) => CommonExpense.fromJson(json)).toList();
      }
      throw Exception('Formato de respuesta inesperado');
    } catch (e) {
      print('Error al obtener gastos comunes: $e');
      rethrow;
    }
  }

  /// Obtener detalle de gasto común
  Future<CommonExpense> getCommonExpenseById({
    required String communityId,
    required String expenseId,
  }) async {
    try {
      final response = await _apiService.get(
        '/common-expenses/$expenseId',
        queryParameters: {'community_id': communityId},
      );
      return CommonExpense.fromJson(response);
    } catch (e) {
      print('Error al obtener gasto común: $e');
      rethrow;
    }
  }

  /// Actualizar gasto común
  Future<CommonExpense> updateCommonExpense({
    required String communityId,
    required String expenseId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final response = await _apiService.put(
        '/common-expenses/$expenseId?community_id=$communityId',
        updates,
      );
      return CommonExpense.fromJson(response);
    } catch (e) {
      print('Error al actualizar gasto común: $e');
      rethrow;
    }
  }

  /// Importar mantenimientos del mes
  Future<CommonExpense> importMaintenances({
    required String communityId,
    required String expenseId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await _apiService.post(
        '/common-expenses/$expenseId/import-maintenances?community_id=$communityId&year=$year&month=$month',
        {},
      );
      return CommonExpense.fromJson(response);
    } catch (e) {
      print('Error al importar mantenimientos: $e');
      rethrow;
    }
  }

  /// Cerrar período de gasto común
  Future<CommonExpense> closeExpense({
    required String communityId,
    required String expenseId,
  }) async {
    try {
      final response = await _apiService.post(
        '/common-expenses/$expenseId/close?community_id=$communityId',
        {},
      );
      return CommonExpense.fromJson(response);
    } catch (e) {
      print('Error al cerrar gasto común: $e');
      rethrow;
    }
  }

  /// Notificar residentes (enviar emails con PDFs)
  Future<Map<String, dynamic>> notifyResidents({
    required String communityId,
    required String expenseId,
  }) async {
    try {
      final response = await _apiService.post(
        '/common-expenses/$expenseId/notify?community_id=$communityId',
        {},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error al notificar residentes: $e');
      rethrow;
    }
  }

  /// Descargar PDF de una unidad (admin)
  Future<void> downloadPDF({
    required String communityId,
    required String expenseId,
    required String unitId,
  }) async {
    try {
      // Nota: Este método requiere manejo especial de descarga de archivos
      // Por ahora retorna la URL, la implementación completa requiere
      // usar url_launcher o similar
      final url = '/common-expenses/$expenseId/pdf/$unitId?community_id=$communityId';
      print('URL de descarga: $url');
      // TODO: Implementar descarga real usando url_launcher
    } catch (e) {
      print('Error al descargar PDF: $e');
      rethrow;
    }
  }

  /// Eliminar gasto común (solo borrador)
  Future<void> deleteCommonExpense({
    required String communityId,
    required String expenseId,
  }) async {
    try {
      await _apiService.delete(
        '/common-expenses/$expenseId?community_id=$communityId',
      );
    } catch (e) {
      print('Error al eliminar gasto común: $e');
      rethrow;
    }
  }

  // ===========================
  // MÉTODOS PARA RESIDENTES
  // ===========================

  /// Obtener mis gastos comunes (últimos 2 años)
  Future<List<Map<String, dynamic>>> getMyExpenses({
    required String communityId,
  }) async {
    try {
      print('📡 Llamando API: /common-expenses/my-expenses/list?community_id=$communityId');
      
      final response = await _apiService.get(
        '/common-expenses/my-expenses/list',
        queryParameters: {'community_id': communityId},
      );

      print('📥 Tipo de respuesta: ${response.runtimeType}');
      print('📊 Respuesta raw: $response');

      if (response is List) {
        print('✅ Respuesta es una lista con ${response.length} elementos');
        
        final result = <Map<String, dynamic>>[];
        for (int i = 0; i < response.length; i++) {
          try {
            final item = response[i];
            print('🔍 Procesando item $i: $item');
            
            if (item is Map<String, dynamic>) {
              result.add(item);
            } else if (item is Map) {
              result.add(Map<String, dynamic>.from(item));
            } else {
              print('⚠️ Item $i no es un Map: ${item.runtimeType}');
            }
          } catch (e) {
            print('💥 Error procesando item $i: $e');
          }
        }
        
        print('✅ Total procesados correctamente: ${result.length}');
        return result;
      }
      
      print('❌ Formato de respuesta inesperado: ${response.runtimeType}');
      throw Exception('Formato de respuesta inesperado: esperaba List, recibió ${response.runtimeType}');
    } catch (e, stackTrace) {
      print('💥 Error en getMyExpenses: $e');
      print('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Generar token temporal para descarga de PDF
  Future<Map<String, dynamic>> generateDownloadToken({
    required String communityId,
    required String expenseId,
  }) async {
    try {
      final response = await _apiService.post(
        '/common-expenses/my-expenses/$expenseId/generate-download-token?community_id=$communityId',
        {},
      );
      
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error al generar token de descarga: $e');
      rethrow;
    }
  }

  /// Descargar mi PDF
  Future<String> downloadMyPDF({
    required String communityId,
    required String expenseId,
  }) async {
    try {
      // Retorna la URL para descarga
      final url = '/common-expenses/my-expenses/$expenseId/pdf?community_id=$communityId';
      return url;
    } catch (e) {
      print('Error al obtener URL de PDF: $e');
      rethrow;
    }
  }

  /// Obtener el gasto común más reciente  del residente
  Future<Map<String, dynamic>?> getLatestExpense({
    required String communityId,
  }) async {
    try {
      final expenses = await getMyExpenses(communityId: communityId);
      if (expenses.isEmpty) return null;
      
      // Retorna el más reciente (ya vienen ordenados por fecha descendente)
      return expenses.first;
    } catch (e) {
      print('Error al obtener último gasto común: $e');
      return null;
    }
  }
}
