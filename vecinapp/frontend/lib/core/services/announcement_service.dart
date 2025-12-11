import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vecinapp/core/models/announcement.dart';
import 'package:vecinapp/core/services/api_service.dart';

class AnnouncementService {
  final String baseUrl = ApiService.baseUrl;

  Future<List<Announcement>> getAll({
    required String communityId,
    String? token,
    bool? isActive,
    bool? showInBanner,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/announcements/').replace(
        queryParameters: {
          'community_id': communityId,
          if (isActive != null) 'is_active': isActive.toString(),
          if (showInBanner != null) 'show_in_banner': showInBanner.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Announcement.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener anuncios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener anuncios: $e');
    }
  }

  Future<List<Announcement>> getActiveBanners({
    required String communityId,
    String? token,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/announcements/active-banners').replace(
        queryParameters: {'community_id': communityId},
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Announcement.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener banners: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener banners: $e');
    }
  }

  Future<Announcement> create({
    required String communityId,
    required String title,
    required String message,
    required AnnouncementPriority priority,
    required bool showInBanner,
    DateTime? expiresAt,
    String? token,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/announcements/').replace(
        queryParameters: {'community_id': communityId},
      );

      final body = {
        'title': title,
        'message': message,
        'priority': priority.value,
        'show_in_banner': showInBanner,
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        return Announcement.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear anuncio: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al crear anuncio: $e');
    }
  }

  Future<Announcement> update({
    required String communityId,
    required String announcementId,
    String? title,
    String? message,
    AnnouncementPriority? priority,
    bool? showInBanner,
    DateTime? expiresAt,
    bool? isActive,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/announcements/$announcementId').replace(
        queryParameters: {'community_id': communityId},
      );

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (message != null) body['message'] = message;
      if (priority != null) body['priority'] = priority.value;
      if (showInBanner != null) body['show_in_banner'] = showInBanner;
      if (expiresAt != null) body['expires_at'] = expiresAt.toIso8601String();
      if (isActive != null) body['is_active'] = isActive;

      final response = await http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return Announcement.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al actualizar anuncio: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al actualizar anuncio: $e');
    }
  }

  Future<void> delete({
    required String communityId,
    required String announcementId,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/announcements/$announcementId').replace(
        queryParameters: {'community_id': communityId},
      );

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Error al eliminar anuncio: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error al eliminar anuncio: $e');
    }
  }
}
