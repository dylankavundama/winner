// lib/models/client_model.dart
class Client {
  final int id;
  final String name;

  Client({required this.id, required this.name});

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: int.parse(json['id'].toString()), // Ensure int parsing
      name: json['name'] as String,
    );
  }

  @override
  String toString() {
    return name; // For easy display in dropdowns
  }
}