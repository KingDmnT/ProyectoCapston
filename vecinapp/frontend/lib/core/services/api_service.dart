import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Servicio para comunicación con el backend FastAPI
class ApiService {
  // URL base del backend desde .env
  static final String _baseUrl = dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Obtener headers con token de autenticación
  Future<Map<String, String>> _getHeaders() async {
    final user = _auth.currentUser;
    String? token;
    
    if (user != null) {
      token = await user.getIdToken();
    }
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // --- GET ---
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();
      
      final response = await http.get(url, headers: headers);
      
      return _handleResponse(response);
    } catch (e) {
      print('Error en GET $endpoint: $e');
      rethrow;
    }
  }
  
  // --- POST ---
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();
      
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('Error en POST $endpoint: $e');
      rethrow;
    }
  }
  
  // --- PUT ---
  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();
      
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _handleResponse(response);
    } catch (e) {
      print('Error en PUT $endpoint: $e');
      rethrow;
    }
  }
  
  // --- DELETE ---
  Future<dynamic> delete(String endpoint) async {
    try {
      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders();
      
      final response = await http.delete(url, headers: headers);
      
      return _handleResponse(response);
    } catch (e) {
      print('Error en DELETE $endpoint: $e');
      rethrow;
    }
  }
  
  // --- MANEJO DE RESPUESTA ---
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Respuesta exitosa
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      // Error
      throw ApiException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

// Excepción personalizada para errores de API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException({required this.statusCode, required this.message});
  
  @override
  String toString() => 'ApiException($statusCode): $message';
}
