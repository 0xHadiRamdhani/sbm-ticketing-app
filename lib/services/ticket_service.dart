import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
    } else {
      // For technician and admin, fetch all to avoid composite index crashes,
      // and perform filtering locally in memory.
      query = query.orderBy('created_at', descending: true);
    }

    return query.snapshots().map((snapshot) {
      var tickets = snapshot.docs.map((doc) {
        return TicketModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Technician base filter: Only see 'Open' tickets OR tickets assigned to them
      if (role == 'technician') {
        tickets = tickets.where((t) => t.status == 'Open' || t.technicianId == uid).toList();
      }

      // Explicit status filter from parameter
      if (status != null && status.isNotEmpty) {
        tickets = tickets.where((t) => t.status == status).toList();
      }

      return tickets;
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
    
    // Jika ada gambar, upload ke ImgBB
    if (imageFile != null) {
      try {
        final bytes = await File(imageFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);

        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {
            'key': '639f57d0cc80d6da8ddb0c1927ea1a8a',
            'image': base64Image,
          },
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          imageUrl = responseData['data']['url'];
        } else {
          print('ImgBB Upload Failed: ${response.body}');
        }
      } catch (e) {
        print('Error uploading to ImgBB: $e');
      }
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
  Future<void> updateTicketStatus(String ticketId, String newStatus, {String? technicianId, List<XFile>? resolvedImages, String? note}) async {
    Map<String, dynamic> updateData = {'status': newStatus};
    if (technicianId != null) {
      updateData['technician_id'] = technicianId;
    }
    if (note != null && note.isNotEmpty) {
      updateData['note'] = note;
    }

    if (resolvedImages != null && resolvedImages.isNotEmpty) {
      List<String> imageUrls = [];
      for (var imageFile in resolvedImages) {
        try {
          final bytes = await File(imageFile.path).readAsBytes();
          final base64Image = base64Encode(bytes);

          final response = await http.post(
            Uri.parse('https://api.imgbb.com/1/upload'),
            body: {
              'key': '639f57d0cc80d6da8ddb0c1927ea1a8a',
              'image': base64Image,
            },
          );

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            imageUrls.add(responseData['data']['url']);
          } else {
            print('ImgBB Upload Failed: ${response.body}');
          }
        } catch (e) {
          print('Error uploading resolved image to ImgBB: $e');
        }
      }
      if (imageUrls.isNotEmpty) {
        updateData['resolved_image_urls'] = imageUrls;
      }
    }

    await _firestore.collection('tickets').doc(ticketId).update(updateData);
  }

  // Menghapus tiket (Hanya Admin)
  Future<void> deleteTicket(String ticketId) async {
    await _firestore.collection('tickets').doc(ticketId).delete();
  }

  // Mengubah tanggal tiket (Hanya Admin)
  Future<void> updateTicketDate(String ticketId, DateTime newDate) async {
    await _firestore.collection('tickets').doc(ticketId).update({
      'created_at': Timestamp.fromDate(newDate),
    });
  }
}
