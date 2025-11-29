class UserModel {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (avatar != null) 'avatar': avatar,
    };
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
    );
  }
}

