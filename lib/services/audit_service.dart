import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> logAction({
    required String actionType, // 'DELETE_TICKET', 'CHANGE_ROLE', 'ASSIGN_TICKET', 'UPDATE_SLA', etc.
    required String targetId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('audit_logs').add({
      'admin_id': user.uid,
      'admin_email': user.email,
      'action_type': actionType,
      'target_id': targetId,
      'description': description,
      'metadata': metadata,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAuditLogs() {
    return _firestore
        .collection('audit_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
