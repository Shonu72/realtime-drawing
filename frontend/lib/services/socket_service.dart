import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;
  
  // Connection management
  Future<void> connect() async {
    if (_socket != null && _isConnected) {
      return;
    }
    
    final token = await _getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    
    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );
    
    _setupEventHandlers();
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  void _setupEventHandlers() {
    _socket?.onConnect((_) {
      _isConnected = true;
      print('✅ Socket connected');
    });
    
    _socket?.onDisconnect((_) {
      _isConnected = false;
      print('❌ Socket disconnected');
    });
    
    _socket?.onError((error) {
      print('❌ Socket error: $error');
    });
    
    _socket?.onConnectError((error) {
      print('❌ Socket connection error: $error');
    });
  }
  
  // Board events
  void joinBoard(String boardId) {
    _socket?.emit(ApiConstants.socketBoardJoin, {'boardId': boardId});
  }
  
  void leaveBoard(String boardId) {
    _socket?.emit(ApiConstants.socketBoardLeave, {'boardId': boardId});
  }
  
  // Stroke events
  void drawStroke(Map<String, dynamic> strokeData) {
    _socket?.emit(ApiConstants.socketStrokeDraw, strokeData);
  }
  
  void deleteStroke(String boardId, String strokeId) {
    _socket?.emit(ApiConstants.socketStrokeDelete, {
      'boardId': boardId,
      'strokeId': strokeId,
    });
  }
  
  // Cursor events
  void updateCursor(String boardId, double x, double y) {
    _socket?.emit(ApiConstants.socketCursorMove, {
      'boardId': boardId,
      'x': x,
      'y': y,
    });
  }
  
  // Chat events
  void sendChatMessage(String boardId, String message) {
    _socket?.emit(ApiConstants.socketChatMessage, {
      'boardId': boardId,
      'message': message,
    });
  }
  
  void sendTypingIndicator(String boardId, bool isTyping) {
    _socket?.emit(ApiConstants.socketChatTyping, {
      'boardId': boardId,
      'isTyping': isTyping,
    });
  }
  
  // Event listeners
  void onBoardState(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketBoardState, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onStrokeCreated(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketStrokeCreated, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onStrokeDeleted(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketStrokeDeleted, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onUserJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketUserJoined, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onUserLeft(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketUserLeft, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onCursorUpdate(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketCursorUpdate, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onChatMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketChatMessage, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onChatTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketChatTyping, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onBoardCleared(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketBoardCleared, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  void onError(Function(Map<String, dynamic>) callback) {
    _socket?.on(ApiConstants.socketError, (data) {
      callback(data as Map<String, dynamic>);
    });
  }
  
  // Remove event listeners
  void off(String event) {
    _socket?.off(event);
  }
  
  // Disconnect
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}

