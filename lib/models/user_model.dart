class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'student', 'staff', 'technician', 'admin'
  final String department;
  final String phoneNumber; // nomor telepon (opsional, diisi saat login via OTP)

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.phoneNumber = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      department: data['department'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'phoneNumber': phoneNumber,
    };
  }
}
