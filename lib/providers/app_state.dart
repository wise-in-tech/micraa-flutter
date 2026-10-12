import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final ApiService apiService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppState({ApiService? apiService})
      : apiService = apiService ?? ApiService();

  UserModel? get currentUser => _currentUser;
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
}
