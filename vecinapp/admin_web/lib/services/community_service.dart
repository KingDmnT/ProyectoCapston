import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:admin_web/models/community.dart';

class CommunityService {
  final String _baseUrl = dotenv.env['BACKEND_URL'] ?? "http://127.0.0.1:8000";

  Future<Map<String, String>> _getHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Community>> getCommunities() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/communities/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Community.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar comunidades: ${response.body}');
    }
  }

  Future<Community> createCommunity(Community community) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/communities/'),
      headers: await _getHeaders(),
      body: json.encode(community.toJson()),
    );

    if (response.statusCode == 201) {
      return Community.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al crear comunidad: ${response.body}');
    }
  }
}
