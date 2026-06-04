class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String department;
  final String phoneNumber; // nomor telepon (opsional, diisi saat login via OTP)
  final String? photoUrl; // url foto profil
  
  // Smart Routing & Auto-Assign
  final List<String> skills;
  final bool isAvailable;
  final int activeTicketsCount;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    this.phoneNumber = '',
    this.photoUrl,
    this.skills = const [],
    this.isAvailable = true,
    this.activeTicketsCount = 0,
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
      skills: data['skills'] != null ? List<String>.from(data['skills']) : [],
      isAvailable: data['isAvailable'] ?? true,
      activeTicketsCount: data['activeTicketsCount'] ?? 0,
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
      'skills': skills,
      'isAvailable': isAvailable,
      'activeTicketsCount': activeTicketsCount,
    };
  }
}
