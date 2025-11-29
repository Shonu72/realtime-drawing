import '../../../core/utils/helpers.dart';

class ChatMessage {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String message;
  final int timestamp;
  final String? color;

  ChatMessage({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.message,
    required this.timestamp,
    this.color,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Extract userId - can be string or object
    final userIdValue = json['userId'];
    final userId = Helpers.extractId(userIdValue);

    // Extract user info - can be in 'user' field or nested in 'userId'
    final userData = json['user'] as Map<String, dynamic>?;
    final userIdData = userIdValue is Map<String, dynamic> ? userIdValue : null;
    final userName = userData?['name'] ??
        userIdData?['name'] ??
        json['name'] ??
        json['userName'] ??
        '';
    final userAvatar = userData?['avatar'] ??
        userIdData?['avatar'] ??
        json['avatar'] ??
        json['userAvatar'];

    // Extract timestamp - can be int or ISO string
    int timestamp;
    if (json['timestamp'] is int) {
      timestamp = json['timestamp'] as int;
    } else if (json['timestamp'] is String) {
      try {
        final date = DateTime.parse(json['timestamp']);
        timestamp = date.millisecondsSinceEpoch;
      } catch (e) {
        timestamp = DateTime.now().millisecondsSinceEpoch;
      }
    } else {
      timestamp = DateTime.now().millisecondsSinceEpoch;
    }

    return ChatMessage(
      userId: userId,
      userName: Helpers.extractString(userName),
      userAvatar: userAvatar != null ? Helpers.extractString(userAvatar) : null,
      message: Helpers.extractString(json['message']),
      timestamp: timestamp,
      color:
          json['color'] != null ? Helpers.extractString(json['color']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      if (userAvatar != null) 'userAvatar': userAvatar,
      'message': message,
      'timestamp': timestamp,
      if (color != null) 'color': color,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}
