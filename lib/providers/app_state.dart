import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService apiService;

  UserModel? _currentUser;
  List<UserModel> _teachers = [];
  List<UserModel> _students = [];
  bool _isLoading = false;
  String? _error;

  AppState({ApiService? apiService})
      : apiService = apiService ?? ApiService();

  UserModel? get currentUser => _currentUser;
  List<UserModel> get teachers => _teachers;
  List<UserModel> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  void selectUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        apiService.getTeachers(),
        apiService.getStudents(),
      ]);
      _teachers = results[0];
      _students = results[1];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel> createUser(String name, String email, String role) async {
    final user = await apiService.createUser(
      name: name,
      email: email,
      role: role,
    );
    if (role == 'TEACHER') {
      _teachers.add(user);
    } else {
      _students.add(user);
    }
    notifyListeners();
    return user;
  }
}
