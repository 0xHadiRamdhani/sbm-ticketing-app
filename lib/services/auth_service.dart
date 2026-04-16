import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream pergerakan state auth (Login/Logout)
  Stream<User?> get userStream => _auth.authStateChanges();

  // Mendapatkan User saat ini dari Firestore
  Future<UserModel?> getCurrentUser() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    DocumentSnapshot doc = await _firestore.collection('users').doc(currentUser.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Registrasi
  Future<UserModel?> registerWithEmail(String email, String password, String name, String role, String department) async {
    try {
      if (!email.endsWith('@itb.ac.id') && !email.endsWith('@sbm-itb.ac.id')) {
        throw Exception("Harap gunakan email institusi (@itb.ac.id / @sbm-itb.ac.id)");
      }

      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      UserModel newUser = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        role: role,
        department: department,
      );

      await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  // Login
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
