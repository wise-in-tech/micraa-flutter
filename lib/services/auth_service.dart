import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const _storage = FlutterSecureStorage();

  /// Enregistrer un nouvel utilisateur
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role, // 'TEACHER' ou 'STUDENT'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'role': role.toUpperCase(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Sauvegarder le token de manière sécurisée
        await _storage.write(key: _tokenKey, value: data['token']);
        
        // Sauvegarder les données utilisateur
        await _storage.write(
          key: _userKey,
          value: jsonEncode({
            'userId': data['userId'],
            'email': data['email'],
            'name': data['name'],
            'role': data['role'],
          }),
        );

        return {
          'success': true,
          'token': data['token'],
          'user': {
            'userId': data['userId'],
            'email': data['email'],
            'name': data['name'],
            'role': data['role'],
          }
        };
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['error'] ?? error['message'] ?? 'Registration failed: ${response.statusCode}'
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'Registration failed: ${response.statusCode} - ${response.body}'
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e'
      };
    }
  }

  /// Connecter un utilisateur existant
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$kApiBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Sauvegarder le token de manière sécurisée
        await _storage.write(key: _tokenKey, value: data['token']);

        // Sauvegarder les données utilisateur
        await _storage.write(
          key: _userKey,
          value: jsonEncode({
            'userId': data['userId'],
            'email': data['email'],
            'name': data['name'],
            'role': data['role'],
          }),
        );

        return {
          'success': true,
          'token': data['token'],
          'user': {
            'userId': data['userId'],
            'email': data['email'],
            'name': data['name'],
            'role': data['role'],
          }
        };
      } else {
        try {
          final error = jsonDecode(response.body);
          return {
            'success': false,
            'error': error['error'] ?? error['message'] ?? 'Login failed: ${response.statusCode}'
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'Login failed: ${response.statusCode} - ${response.body}'
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e'
      };
    }
  }

  /// Récupérer le token JWT sauvegardé
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Récupérer les données utilisateur
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userKey);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  /// Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Déconnecter l'utilisateur
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Récupérer le rôle de l'utilisateur connecté
  Future<String?> getUserRole() async {
    final userData = await getUserData();
    return userData?['role'];
  }

  /// Récupérer l'ID de l'utilisateur connecté
  Future<int?> getUserId() async {
    final userData = await getUserData();
    if (userData != null && userData['userId'] != null) {
      return int.tryParse(userData['userId'].toString());
    }
    return null;
  }
}
