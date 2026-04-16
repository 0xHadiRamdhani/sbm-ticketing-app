import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ticket_model.dart';
import 'package:image_picker/image_picker.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Mendapatkan stream tiket berdasarkan status/orang
  Stream<List<TicketModel>> getTickets({String? role, String? uid, String? status}) {
    Query query = _firestore.collection('tickets');

    if (role == 'student' || role == 'staff') {
      query = query
          .where('requester_id', isEqualTo: uid)
          .orderBy('created_at', descending: true);
    } else if (role == 'technician') {
      if (status == 'Open') {
        query = query
            .where('status', isEqualTo: 'Open')
            .orderBy('created_at', descending: true);
      } else {
        query = query
            .where('technician_id', isEqualTo: uid)
            .orderBy('created_at', descending: true);
      }
    } else {
      // Admin: lihat semua tiket
      query = query.orderBy('created_at', descending: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Membuat tiket baru (dengan kemungkinan upload gambar)
  Future<void> createTicket({
    required String requesterId,
    required String category,
    required String description,
    required String priority,
    required String location,
    XFile? imageFile,
  }) async {
    String? imageUrl;
    
    // Jika ada gambar, upload dulu ke Firebase Storage
    if (imageFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + imageFile.name;
      Reference ref = _storage.ref().child('ticket_images').child(fileName);
      UploadTask uploadTask = ref.putFile(File(imageFile.path));
      TaskSnapshot targetSnapshot = await uploadTask;
      imageUrl = await targetSnapshot.ref.getDownloadURL();
    }

    TicketModel newTicket = TicketModel(
      ticketId: '', // ticketId dikosongkan karena dibuat oleh firestore doc ref nantinya
      createdAt: DateTime.now(),
      category: category,
      description: description,
      status: 'Open',
      priority: priority,
      requesterId: requesterId,
      imageUrl: imageUrl,
      location: location,
    );

    await _firestore.collection('tickets').add(newTicket.toMap());
  }

  // Update status tiket (Misal Teknisi mengambil atau menyelesaikannya)
  Future<void> updateTicketStatus(String ticketId, String newStatus, {String? technicianId}) async {
    Map<String, dynamic> updateData = {'status': newStatus};
    if (technicianId != null) {
      updateData['technician_id'] = technicianId;
    }
    await _firestore.collection('tickets').doc(ticketId).update(updateData);
  }
}
