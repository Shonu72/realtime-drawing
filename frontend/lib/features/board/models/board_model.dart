import '../../../core/utils/helpers.dart';

enum BoardRole {
  admin,
  editor,
  viewer,
}

class BoardMember {
  final String userId;
  final BoardRole role;
  final DateTime joinedAt;
  
  BoardMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });
  
  factory BoardMember.fromJson(Map<String, dynamic> json) {
    // userId is always a string in API responses
    final userIdValue = json['userId'];
    final userId = Helpers.extractId(userIdValue);
    
    return BoardMember(
      userId: userId,
      role: _parseRole(json['role']),
      joinedAt: Helpers.parseDate(json['joinedAt']),
    );
  }
  
  static BoardRole _parseRole(dynamic role) {
    final roleString = Helpers.extractString(role);
    switch (roleString.toLowerCase()) {
      case 'admin':
        return BoardRole.admin;
      case 'editor':
        return BoardRole.editor;
      case 'viewer':
        return BoardRole.viewer;
      default:
        return BoardRole.editor;
    }
  }
}

class BoardSettings {
  final bool allowGuests;
  final int maxUsers;
  final bool enableChat;
  final bool enableReplay;
  
  BoardSettings({
    this.allowGuests = false,
    this.maxUsers = 50,
    this.enableChat = true,
    this.enableReplay = true,
  });
  
  factory BoardSettings.fromJson(Map<String, dynamic> json) {
    return BoardSettings(
      allowGuests: Helpers.extractBool(json['allowGuests'], fallback: false),
      maxUsers: Helpers.extractInt(json['maxUsers'], fallback: 50),
      enableChat: Helpers.extractBool(json['enableChat'], fallback: true),
      enableReplay: Helpers.extractBool(json['enableReplay'], fallback: true),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'allowGuests': allowGuests,
      'maxUsers': maxUsers,
      'enableChat': enableChat,
      'enableReplay': enableReplay,
    };
  }
}

class Board {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final List<BoardMember> members;
  final bool isPublic;
  final BoardSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Board({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.members,
    required this.isPublic,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Board.fromJson(Map<String, dynamic> json) {
    // Extract ID - backend returns _id
    final id = Helpers.extractId(json['_id'] ?? json['id']);
    
    // Extract ownerId - can be string or populated object
    final ownerIdValue = json['ownerId'];
    final ownerId = Helpers.extractId(ownerIdValue);
    
    // Parse members
    final membersList = json['members'] as List<dynamic>?;
    final members = membersList
        ?.map((m) {
          try {
            return BoardMember.fromJson(m as Map<String, dynamic>);
          } catch (e) {
            return null;
          }
        })
        .whereType<BoardMember>()
        .toList() ?? [];
    
    return Board(
      id: id,
      name: Helpers.extractString(json['name']),
      description: json['description'] != null 
          ? Helpers.extractString(json['description'])
          : null,
      ownerId: ownerId,
      members: members,
      isPublic: Helpers.extractBool(json['isPublic'], fallback: false),
      settings: BoardSettings.fromJson(json['settings'] ?? {}),
      createdAt: Helpers.parseDate(json['createdAt']),
      updatedAt: Helpers.parseDate(json['updatedAt']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'isPublic': isPublic,
      'settings': settings.toJson(),
    };
  }
  
  BoardRole? getUserRole(String userId) {
    final member = members.firstWhere(
      (m) => m.userId == userId,
      orElse: () => BoardMember(
        userId: '',
        role: BoardRole.viewer,
        joinedAt: DateTime.now(),
      ),
    );
    return member.userId == userId ? member.role : null;
  }
  
  bool isOwner(String userId) {
    return ownerId == userId;
  }
  
  bool canEdit(String userId) {
    final role = getUserRole(userId);
    return role == BoardRole.admin || role == BoardRole.editor || isOwner(userId);
  }
}

