import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/live_class_model.dart';
import '../models/join_class_response.dart';
import 'auth_service.dart';

class ApiService {
  // Résolu à chaque instanciation pour prendre l'IP dynamique
  final String baseUrl;
  final AuthService authService;

  ApiService({String? baseUrl, AuthService? authService}) 
    : baseUrl = baseUrl ?? kApiBaseUrl,
      authService = authService ?? AuthService();

  /// Construire les headers avec le JWT si disponible
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Ajouter le token JWT s'il existe
    final token = await authService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ─── Health ────────────────────────────────────────────
  Future<bool> checkHealth() async {
    try {
      final headers = await _getHeaders();
      final res = await http
          .get(Uri.parse('$baseUrl/api/health'), headers: headers)
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Users ─────────────────────────────────────────────
  Future<List<UserModel>> getTeachers() async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/api/users/teachers'),
      headers: headers,
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserModel>> getStudents() async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/api/users/students'),
      headers: headers,
    );
    _checkStatus(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String role,
  }) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: headers,
      body: jsonEncode({'name': name, 'email': email, 'role': role}),
    );
    _checkStatus(res);
    return UserModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─── Live Classes ───────────────────────────────────────
  Future<List<LiveClassModel>> getLiveClassesForUser(UserModel user) async {
    // L'API attend: GET /api/live-classes?userId=X&role=TEACHER|STUDENT
    final String endpoint =
        '$baseUrl/api/live-classes?userId=${user.id}&role=${user.role}';

    final headers = await _getHeaders();
    final res = await http.get(Uri.parse(endpoint), headers: headers);
    _checkStatus(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => LiveClassModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LiveClassModel> createLiveClass({
    required String title,
    required int teacherId,
    String? scheduledAt,
  }) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/live-classes'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'teacherId': teacherId,
        if (scheduledAt != null) 'scheduledAt': scheduledAt,
      }),
    );
    _checkStatus(res);
    return LiveClassModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<LiveClassModel> startLiveClass(int classId, int teacherId) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/live-classes/$classId/start?teacherId=$teacherId'),
      headers: headers,
    );
    _checkStatus(res);
    return LiveClassModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> addStudents(int classId, int teacherId, List<int> studentIds) async {
    // POST /api/live-classes/{id}/students  (body: studentIds)
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/live-classes/$classId/students'),
      headers: headers,
      body: jsonEncode({'studentIds': studentIds}),
    );
    _checkStatus(res);
  }

  Future<JoinClassResponse> joinLiveClass(int classId, int userId) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/live-classes/$classId/join?userId=$userId'),
      headers: headers,
    );
    _checkStatus(res);
    return JoinClassResponse.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<LiveClassModel> endLiveClass(int classId, int teacherId) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/api/live-classes/$classId/end?teacherId=$teacherId'),
      headers: headers,
    );
    _checkStatus(res);
    return LiveClassModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─── Helpers ───────────────────────────────────────────
  void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw ApiException(
        body['error'] as String? ?? 'Erreur inconnue',
        res.statusCode,
      );
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
