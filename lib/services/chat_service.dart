import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream pesan untuk suatu tiket
  Stream<List<MessageModel>> getMessages(String ticketId) {
    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Mengirim pesan baru
  Future<void> sendMessage(String ticketId, String senderId, String text) async {
    if (text.trim().isEmpty) return;

    final newMessage = MessageModel(
      messageId: '', // akan di-generate oleh firestore
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('messages')
        .add(newMessage.toMap());
  }
}
