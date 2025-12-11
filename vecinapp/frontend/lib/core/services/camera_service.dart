import 'package:vecinapp/core/services/api_service.dart';

class CameraService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getConfig(String communityId) async {
    try {
      final response = await _apiService.get('/cameras/$communityId/config');
      return response as Map<String, dynamic>;
    } catch (e) {
      if (e.toString().contains('404')) {
        return {}; // No config found is a valid state
      }
      rethrow;
    }
  }

  Future<void> saveConfig(String communityId, Map<String, dynamic> config) async {
    await _apiService.post('/cameras/$communityId/config', config);
  }

  Future<bool> checkConnection(String communityId) async {
    try {
      // Endpoint dummy por ahora
      await _apiService.get('/cameras/$communityId/status');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> testConnection(String communityId) async {
    try {
      final response = await _apiService.get('/cameras/$communityId/test-connection');
      return response as Map<String, dynamic>;
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getChannels(String communityId) async {
    try {
      final response = await _apiService.get('/cameras/$communityId/channels');
      return (response['channels'] as List<dynamic>?) ?? [];
    } catch (e) {
      print('Error obteniendo canales: $e');
      return [];
    }
  }

  String getSnapshotUrl(String communityId, int channelId) {
    // Nota: Esta URL requiere autenticación, el navegador manejará las credenciales
    return '${ApiService.baseUrl}/cameras/$communityId/snapshot/$channelId';
  }

  String getMjpegUrl(String communityId, int channelId) {
    // MJPEG stream continuo desde backend (proxy a Hikvision)
    return '${ApiService.baseUrl}/cameras/$communityId/mjpeg/$channelId';
  }
}
