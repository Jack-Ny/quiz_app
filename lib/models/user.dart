class AppUser {
  final String id;
  final String email;
  final String userType;
  final String name;
  final String? profilePicture;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.userType,
    required this.name,
    this.profilePicture,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      userType: json['user_type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'user_type': userType,
        'name': name,
        'profile_picture': profilePicture,
        'created_at': createdAt.toIso8601String(),
      };
}
