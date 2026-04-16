class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'student', 'staff', 'technician', 'admin'
  final String department;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      department: data['department'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
    };
  }
}
