class ApiConstants {
  // Backend API URL
  static const String baseUrl = 'http://10.178.34.95:3000';
  // static const String baseUrl = 'http://localhost:3000';
  static const String apiBaseUrl = '$baseUrl/api';
  
  // Socket.IO URL
  static const String socketUrl = baseUrl;
  
  // API Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  
  static const String boards = '/boards';
  static String boardById(String id) => '/boards/$id';
  static String boardStrokes(String id) => '/boards/$id/strokes';
  static String boardMembers(String id) => '/boards/$id/members';
  static String boardSettings(String id) => '/boards/$id/settings';
  static String boardVerifyPassword(String id) => '/boards/$id/verify-password';
  static String boardChat(String id) => '/boards/$id/chat';
  
  // Socket Events
  static const String socketBoardJoin = 'board:join';
  static const String socketBoardLeave = 'board:leave';
  static const String socketBoardState = 'board:state';
  static const String socketBoardCleared = 'board:cleared';
  
  static const String socketUserJoined = 'user:joined';
  static const String socketUserLeft = 'user:left';
  
  static const String socketStrokeDraw = 'stroke:draw';
  static const String socketStrokeCreated = 'stroke:created';
  static const String socketStrokeDelete = 'stroke:delete';
  static const String socketStrokeDeleted = 'stroke:deleted';
  
  static const String socketCursorMove = 'cursor:move';
  static const String socketCursorUpdate = 'cursor:update';
  
  static const String socketChatMessage = 'chat:message';
  static const String socketChatTyping = 'chat:typing';
  
  static const String socketError = 'error';
}

