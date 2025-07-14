// lib/models/user_model.dart
class User {
  final int userId;
  final String username;
  // Add other user properties if needed, e.g., role
  // final String role;

  User({required this.userId, required this.username}); //, required this.role});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      // role: json['role'] ?? 'user', // Default role if not provided
    );
  }
}