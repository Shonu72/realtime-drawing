import '../../../core/utils/helpers.dart';

enum StrokeTool {
  pencil,
  brush,
  highlighter,
  eraser,
}

class Point {
  final double x;
  final double y;
  final double? pressure;
  final int timestamp;
  
  Point({
    required this.x,
    required this.y,
    this.pressure,
    required this.timestamp,
  });
  
  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      x: Helpers.extractDouble(json['x']),
      y: Helpers.extractDouble(json['y']),
      pressure: json['pressure'] != null 
          ? Helpers.extractDouble(json['pressure'])
          : null,
      timestamp: Helpers.extractInt(json['timestamp']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      if (pressure != null) 'pressure': pressure,
      'timestamp': timestamp,
    };
  }
}

class Stroke {
  final String id;
  final String boardId;
  final String userId;
  final StrokeTool tool;
  final List<Point> points;
  final String color;
  final double width;
  final String? layerId;
  final int timestamp;
  final int version;
  final bool deleted;
  final String? userName;
  final String? userAvatar;
  
  Stroke({
    required this.id,
    required this.boardId,
    required this.userId,
    required this.tool,
    required this.points,
    required this.color,
    required this.width,
    this.layerId,
    required this.timestamp,
    required this.version,
    this.deleted = false,
    this.userName,
    this.userAvatar,
  });
  
  factory Stroke.fromJson(Map<String, dynamic> json) {
    // Extract IDs - handle both _id and id
    final id = Helpers.extractId(json['id'] ?? json['_id']);
    final boardId = Helpers.extractId(json['boardId']);
    
    // Extract userId - can be string or populated object
    final userIdValue = json['userId'];
    final userId = Helpers.extractId(userIdValue);
    
    // Extract user info - can be in 'user' field or nested in 'userId'
    final userData = json['user'] as Map<String, dynamic>?;
    final userIdData = userIdValue is Map<String, dynamic> ? userIdValue : null;
    final userName = userData?['name'] ?? userIdData?['name'];
    final userAvatar = userData?['avatar'] ?? userIdData?['avatar'];
    
    // Parse points
    final pointsList = json['points'] as List<dynamic>?;
    final points = pointsList
        ?.map((p) {
          try {
            return Point.fromJson(p as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        })
        .whereType<Point>()
        .toList() ?? [];
    
    return Stroke(
      id: id,
      boardId: boardId,
      userId: userId,
      tool: _parseTool(json['tool']),
      points: points,
      color: Helpers.extractString(json['color'], fallback: '#000000'),
      width: Helpers.extractDouble(json['width'], fallback: 3.0),
      layerId: json['layerId'] != null 
          ? Helpers.extractString(json['layerId'])
          : null,
      timestamp: Helpers.extractInt(json['timestamp']),
      version: Helpers.extractInt(json['version']),
      deleted: Helpers.extractBool(json['deleted'], fallback: false),
      userName: userName != null ? Helpers.extractString(userName) : null,
      userAvatar: userAvatar != null ? Helpers.extractString(userAvatar) : null,
    );
  }
  
  static StrokeTool _parseTool(dynamic tool) {
    final toolString = Helpers.extractString(tool).toLowerCase();
    switch (toolString) {
      case 'pencil':
        return StrokeTool.pencil;
      case 'brush':
        return StrokeTool.brush;
      case 'highlighter':
        return StrokeTool.highlighter;
      case 'eraser':
        return StrokeTool.eraser;
      default:
        return StrokeTool.pencil;
    }
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boardId': boardId,
      'tool': tool.name,
      'points': points.map((p) => p.toJson()).toList(),
      'color': color,
      'width': width,
      if (layerId != null) 'layerId': layerId,
    };
  }
  
  Stroke copyWith({
    String? id,
    String? boardId,
    String? userId,
    StrokeTool? tool,
    List<Point>? points,
    String? color,
    double? width,
    String? layerId,
    int? timestamp,
    int? version,
    bool? deleted,
    String? userName,
    String? userAvatar,
  }) {
    return Stroke(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      userId: userId ?? this.userId,
      tool: tool ?? this.tool,
      points: points ?? this.points,
      color: color ?? this.color,
      width: width ?? this.width,
      layerId: layerId ?? this.layerId,
      timestamp: timestamp ?? this.timestamp,
      version: version ?? this.version,
      deleted: deleted ?? this.deleted,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }
}

