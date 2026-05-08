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
    } else {
      // Auto-create missing document to prevent silent login failures
      UserModel newUser = UserModel(
        uid: currentUser.uid,
        name: currentUser.displayName ?? 'Pengguna',
        email: currentUser.email ?? '',
        role: 'student', // default
        department: '',
      );
      await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
      return newUser;
    }
  }

  // Registrasi (menerima semua email termasuk Gmail)
  Future<UserModel?> registerWithEmail(String email, String password, String name, String role, String department) async {
    try {
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

  // Cek apakah email sudah terdaftar dengan query ke Firestore
  // (lebih andal dari Firebase Auth karena versi terbaru mengaktifkan
  //  Email Enumeration Protection yang menyembunyikan status email)
  Future<bool> isEmailRegistered(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (_) {
      return false;
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

  // --- PHONE AUTH ---

  /// Kirim OTP ke nomor telepon. Panggil [onCodeSent] jika berhasil.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval (Android only). Sign in langsung.
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verifikasi gagal');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Verifikasi OTP & login. Jika user belum terdaftar di Firestore, simpan data minimal.
  Future<UserModel?> signInWithOtp({
    required String verificationId,
    required String smsCode,
    String? name,
    String? role,
    String? department,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCred = await _auth.signInWithCredential(credential);
    final uid = userCred.user!.uid;
    final phone = userCred.user!.phoneNumber ?? '';

    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    } else {
      // User baru — simpan data awal ke Firestore
      final newUser = UserModel(
        uid: uid,
        name: name ?? phone,
        email: phone, // gunakan nomor telepon sebagai identifier
        role: role ?? 'student',
        department: department ?? '',
        phoneNumber: phone,
      );
      await _firestore.collection('users').doc(uid).set(newUser.toMap());
      return newUser;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
