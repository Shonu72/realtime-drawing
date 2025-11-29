import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _user;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;
  
  UserModel? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AuthProvider() {
    _checkAuthStatus();
  }
  
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        final userData = await _authService.getCurrentUser();
        if (userData != null) {
          _user = UserModel.fromJson(userData);
          _isAuthenticated = true;
        } else {
          await _authService.logout();
          _isAuthenticated = false;
        }
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      _isAuthenticated = false;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
      );
      
      if (result['success'] == true) {
        _user = UserModel.fromJson(result['user']);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );
      
      if (result['success'] == true) {
        _user = UserModel.fromJson(result['user']);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result['error'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isAuthenticated = false;
    _error = null;
    notifyListeners();
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

