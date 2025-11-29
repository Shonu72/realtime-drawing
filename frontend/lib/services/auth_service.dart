import 'package:dio/dio.dart';

import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  /// Extract user-friendly error message from DioException
  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      // Try to get error message from response data
      if (error.response?.data != null) {
        final responseData = error.response!.data;
        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('error')) {
          return responseData['error'] as String;
        }
      }

      // Provide user-friendly messages based on status code
      final statusCode = error.response?.statusCode;
      switch (statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Invalid email or password.';
        case 409:
          return 'An account with this email already exists. Please sign in instead.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          if (error.type == DioExceptionType.connectionError) {
            return 'Connection error. Please check your internet connection.';
          } else if (error.type == DioExceptionType.connectionTimeout) {
            return 'Connection timeout. Please try again.';
          }
          return 'An error occurred. Please try again.';
      }
    }

    // Fallback for non-DioException errors
    return error.toString();
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        name: name,
      );

      final data = response.data;

      // Validate response structure
      if (data == null || data['token'] == null || data['user'] == null) {
        return {
          'success': false,
          'error': 'Invalid response from server',
        };
      }

      final token = data['token'] as String? ?? data['token'].toString();
      final userData = data['user'] as Map<String, dynamic>?;

      if (userData == null) {
        return {
          'success': false,
          'error': 'User data not found in response',
        };
      }

      // Extract user ID - handle both string and ObjectId formats
      final userId =
          userData['id']?.toString() ?? userData['_id']?.toString() ?? '';

      if (userId.isEmpty) {
        return {
          'success': false,
          'error': 'User ID not found in response',
        };
      }

      final userEmail = userData['email'] as String? ?? '';
      final userName = userData['name'] as String? ?? '';

      // Save token and user data
      await StorageService.saveToken(token);
      await StorageService.saveUserData(
        userId: userId,
        email: userEmail,
        name: userName,
      );

      return {
        'success': true,
        'token': token,
        'user': {
          'id': userId,
          'email': userEmail,
          'name': userName,
          'avatar': userData['avatar'],
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': _extractErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      final data = response.data;

      // Validate response structure
      if (data == null || data['token'] == null || data['user'] == null) {
        return {
          'success': false,
          'error': 'Invalid response from server',
        };
      }

      final token = data['token'] as String? ?? data['token'].toString();
      final userData = data['user'] as Map<String, dynamic>?;

      if (userData == null) {
        return {
          'success': false,
          'error': 'User data not found in response',
        };
      }

      // Extract user ID - handle both string and ObjectId formats
      final userId =
          userData['id']?.toString() ?? userData['_id']?.toString() ?? '';

      if (userId.isEmpty) {
        return {
          'success': false,
          'error': 'User ID not found in response',
        };
      }

      final userEmail = userData['email'] as String? ?? '';
      final userName = userData['name'] as String? ?? '';

      // Save token and user data
      await StorageService.saveToken(token);
      await StorageService.saveUserData(
        userId: userId,
        email: userEmail,
        name: userName,
      );

      return {
        'success': true,
        'token': token,
        'user': {
          'id': userId,
          'email': userEmail,
          'name': userName,
          'avatar': userData['avatar'],
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': _extractErrorMessage(e),
      };
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      return response.data['user'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await StorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await StorageService.clearAll();
  }

  Future<String?> getToken() async {
    return await StorageService.getToken();
  }
}
