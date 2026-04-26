import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    // Add interceptor for auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            // Handle unauthorized - token expired or invalid
            // Could trigger logout here
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // Auth endpoints
  Future<Response> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _dio.post(
      ApiConstants.authRegister,
      data: {
        'email': email,
        'password': password,
        'name': name,
      },
    );
  }
  
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await _dio.post(
      ApiConstants.authLogin,
      data: {
        'email': email,
        'password': password,
      },
    );
  }
  
  Future<Response> getCurrentUser() async {
    return await _dio.get(ApiConstants.authMe);
  }
  
  // Board endpoints
  Future<Response> getBoards() async {
    return await _dio.get('${ApiConstants.boards}/my-boards');
  }
  
  Future<Response> getBoard(String boardId) async {
    return await _dio.get(ApiConstants.boardById(boardId));
  }
  
  Future<Response> createBoard({
    required String name,
    String? description,
    bool isPublic = false,
    Map<String, dynamic>? settings,
  }) async {
    return await _dio.post(
      ApiConstants.boards,
      data: {
        'name': name,
        if (description != null) 'description': description,
        'isPublic': isPublic,
        if (settings != null) 'settings': settings,
      },
    );
  }
  
  Future<Response> deleteBoard(String boardId) async {
    return await _dio.delete(ApiConstants.boardById(boardId));
  }
  
  Future<Response> getBoardStrokes(String boardId) async {
    return await _dio.get(ApiConstants.boardStrokes(boardId));
  }
  
  Future<Response> updateBoardSettings(
    String boardId,
    Map<String, dynamic> settings,
  ) async {
    return await _dio.patch(
      ApiConstants.boardSettings(boardId),
      data: settings,
    );
  }
  
  Future<Response> addBoardMember(
    String boardId,
    String userId,
    String role,
  ) async {
    return await _dio.post(
      ApiConstants.boardMembers(boardId),
      data: {
        'userId': userId,
        'role': role,
      },
    );
  }
  
  Future<Response> removeBoardMember(String boardId, String userId) async {
    return await _dio.delete(
      '${ApiConstants.boardMembers(boardId)}/$userId',
    );
  }
  
  Future<Response> verifyBoardPassword(String boardId, String password) async {
    return await _dio.post(
      ApiConstants.boardVerifyPassword(boardId),
      data: {'password': password},
    );
  }

  Future<Response> getBoardChat(String boardId) async {
    return await _dio.get(ApiConstants.boardChat(boardId));
  }
}

