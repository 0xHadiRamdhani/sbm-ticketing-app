class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String department;
  final String phoneNumber; // nomor telepon (opsional, diisi saat login via OTP)
  final String? photoUrl; // url foto profil

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.phoneNumber = '',
    this.photoUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      department: data['department'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
    };
  }
}
