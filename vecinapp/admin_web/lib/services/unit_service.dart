import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/unit.dart';

class UnitService {
  final String _baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';

  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Unit>> getUnits(String communityId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/units/?community_id=$communityId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Unit.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar unidades: ${response.body}');
    }
  }

  Future<Unit> createUnit(Unit unit) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/units/'),
      headers: await _getHeaders(),
      body: json.encode(unit.toJson()),
    );

    if (response.statusCode == 201) {
      return Unit.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al crear unidad: ${response.body}');
    }
  }

  Future<Unit> updateUnit(Unit unit) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/units/${unit.id}'),
      headers: await _getHeaders(),
      body: json.encode(unit.toJson()),
    );

    if (response.statusCode == 200) {
      return Unit.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Error al actualizar unidad: ${response.body}');
    }
  }

  Future<void> deleteUnit(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/units/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar unidad: ${response.body}');
    }
  }
}
