import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/ticket_model.dart';
import 'package:image_picker/image_picker.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Mendapatkan stream tiket berdasarkan status/orang
  Stream<List<TicketModel>> getTickets({
    String? role,
    String? uid,
    String? status,
  }) {
    Query query = _firestore.collection('tickets');

    if (role == 'student' ||
        role == 'staff' ||
        role == 'guest' ||
        role == 'requester' ||
        role == 'technician_as_requester') {
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

      // Sort in-memory: tickets with last_message_at first, then fallback to created_at
      tickets.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });

      // Technician base filter: Only see 'Assigned' or 'In Progress' tickets assigned to them,
      // or 'New' tickets if they are expected to pick them up (if that's the logic).
      // Here we allow them to see 'New' tickets OR tickets assigned to them.
      if (role == 'technician') {
        tickets = tickets
            .where((t) => t.status == 'New' || t.technicianId == uid)
            .toList();
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

    // Jika ada gambar, upload ke Firebase Storage
    if (imageFile != null) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
        final ref = _storage.ref().child('ticket_images/$fileName');
        final uploadTask = await ref.putFile(File(imageFile.path)).timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            throw Exception('Koneksi unggah gambar tiket habis (Timeout).');
          },
        );
        imageUrl = await uploadTask.ref.getDownloadURL();
      } catch (e) {
        print('Error uploading to Firebase Storage: $e');
      }
    }

    DateTime now = DateTime.now();
    
    // 1. SLA Management: Calculate Target Resolution Time - ALL SET TO 1 HOUR
    DateTime targetResolution = now.add(const Duration(hours: 1));

    // 2. Auto-Assign & Smart Routing
    String requiredSkill = 'general';
    final catLow = category.toLowerCase();
    if (catLow.contains('jaringan') || catLow.contains('wifi') || catLow.contains('internet')) {
      requiredSkill = 'network';
    } else if (catLow.contains('laptop') || catLow.contains('komputer') || catLow.contains('it')) {
      requiredSkill = 'it_support';
    } else if (catLow.contains('proyektor') || catLow.contains('audio')) {
      requiredSkill = 'av_support';
    }

    String? assignedTechnicianId;
    try {
      final techsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'technician')
          .where('isAvailable', isEqualTo: true)
          .where('skills', arrayContains: requiredSkill)
          .get();

      if (techsSnapshot.docs.isNotEmpty) {
        // Load balancing: sort by activeTicketsCount
        var techs = techsSnapshot.docs.toList();
        techs.sort((a, b) {
          int countA = (a.data()['activeTicketsCount'] ?? 0) as int;
          int countB = (b.data()['activeTicketsCount'] ?? 0) as int;
          return countA.compareTo(countB);
        });

        assignedTechnicianId = techs.first.id;
        
        // Update technician's active count
        await _firestore.collection('users').doc(assignedTechnicianId).update({
          'activeTicketsCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Auto-assign error: $e');
    }

    TicketModel newTicket = TicketModel(
      ticketId: '',
      createdAt: now,
      category: category,
      description: description,
      status: assignedTechnicianId != null ? 'Assigned' : 'New',
      priority: priority,
      requesterId: requesterId,
      technicianId: assignedTechnicianId,
      imageUrl: imageUrl,
      location: location,
      targetResolutionAt: targetResolution,
      escalationLevel: 0,
    );

    final docRef = await _firestore
        .collection('tickets')
        .add(newTicket.toMap());

    // Record initial status history
    await docRef.collection('status_history').add({
      'status': assignedTechnicianId != null ? 'Assigned' : 'New',
      'label': assignedTechnicianId != null ? 'Ditugaskan (Auto-Routing)' : 'Baru',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _uploadImage(XFile imageFile, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final ref = _storage.ref().child('$folder/$fileName');
      final uploadTask = await ref.putFile(File(imageFile.path)).timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw Exception('Koneksi unggah foto lampiran habis (Timeout).');
        },
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Firebase Storage Upload Error: $e');
    }
    return null;
  }

  // Update status tiket (Misal Teknisi mengambil atau menyelesaikannya)
  Future<void> updateTicketStatus(
    String ticketId,
    String newStatus, {
    String? technicianId,
    List<XFile>? resolvedImages,
    String? note,
    XFile? photoBefore,
    XFile? photoAfter,
  }) async {
    final docSnapshot = await _firestore
        .collection('tickets')
        .doc(ticketId)
        .get();
    if (!docSnapshot.exists) return;

    final oldData = docSnapshot.data() as Map<String, dynamic>;
    final oldStatus = oldData['status'] ?? 'New';
    final oldNote = oldData['note'] ?? '';

    Map<String, dynamic> updateData = {'status': newStatus};
    if (technicianId != null) {
      updateData['technician_id'] = technicianId;
    }
    if (note != null && note.isNotEmpty) {
      updateData['note'] = note;
    }

    if (photoBefore != null) {
      String? url = await _uploadImage(photoBefore, 'repair_images');
      if (url != null) updateData['photo_before_url'] = url;
    }

    if (photoAfter != null) {
      String? url = await _uploadImage(photoAfter, 'repair_images');
      if (url != null) updateData['photo_after_url'] = url;
    }

    if (resolvedImages != null && resolvedImages.isNotEmpty) {
      List<String> imageUrls = [];
      for (var imageFile in resolvedImages) {
        String? url = await _uploadImage(imageFile, 'resolved_images');
        if (url != null) imageUrls.add(url);
      }
      if (imageUrls.isNotEmpty) {
        updateData['resolved_image_urls'] = imageUrls;
      }
    }

    if (newStatus == 'Resolved') {
      updateData['resolved_at'] = FieldValue.serverTimestamp();
    } else if (newStatus == 'In Progress' &&
        (oldStatus == 'New' ||
            oldStatus == 'Assigned' ||
            oldStatus == 'Re-opened' ||
            oldStatus == 'Pending')) {
      updateData['in_progress_at'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection('tickets').doc(ticketId).update(updateData);

    // Record status history
    await _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('status_history')
        .add({
          'status': newStatus,
          'label': _getStatusLabel(newStatus),
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Send system messages if status or note changed
    if (oldStatus != newStatus) {
      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .add({
            'sender_id': 'system',
            'text':
                'Pembaruan Sistem: Status tiket telah diubah menjadi $newStatus.',
            'timestamp': FieldValue.serverTimestamp(),
          });
    }

    if (note != null && note.isNotEmpty && note != oldNote) {
      await _firestore
          .collection('tickets')
          .doc(ticketId)
          .collection('messages')
          .add({
            'sender_id': 'system',
            'text':
                'Pembaruan Sistem: Teknisi menambahkan catatan baru: "$note".',
            'timestamp': FieldValue.serverTimestamp(),
          });
    }
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

  Future<void> updateTicketDetails(
    String ticketId, {
    required String category,
    required String priority,
    required String location,
    required String description,
  }) async {
    await _firestore.collection('tickets').doc(ticketId).update({
      'category': category,
      'priority': priority,
      'location': location,
      'description': description,
    });
  }

  Future<void> addInternalNote(
    String ticketId,
    String note,
    String adminId,
    String adminName,
  ) async {
    await _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('internal_notes')
        .add({
          'note': note,
          'author_id': adminId,
          'author_name': adminName,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'New':
        return 'Baru Masuk';
      case 'Assigned':
        return 'Ditugaskan';
      case 'In Progress':
        return 'Diproses';
      case 'Pending':
        return 'Menunggu Info User';
      case 'Resolved':
        return 'Menunggu Konfirmasi User';
      case 'Closed':
        return 'Selesai Sepenuhnya';
      case 'Re-opened':
        return 'Dibuka Kembali';
      case 'Open':
        return 'Diajukan'; // Legacy
      default:
        return status;
    }
  }

  // 3. Auto-Escalation: Check SLA breaches and warn/escalate
  Future<void> checkAndEscalateTickets() async {
    try {
      final now = DateTime.now();
      
      // Karena keterbatasan Firestore (tidak bisa whereNotIn jika banyak data tanpa index yang rumit),
      // kita ambil data tiket yang bukan Closed/Resolved.
      // Dalam produksi, lebih baik menggunakan Cloud Functions (cron job).
      final ticketsSnapshot = await _firestore.collection('tickets').get();

      for (var doc in ticketsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        if (status == 'Resolved' || status == 'Closed') continue;
        if (data['target_resolution_at'] == null) continue;
        
        final targetDate = (data['target_resolution_at'] as Timestamp).toDate();
        final escalationLevel = data['escalation_level'] ?? 0;
        final createdAt = (data['created_at'] as Timestamp).toDate();

        final totalDuration = targetDate.difference(createdAt);
        final elapsed = now.difference(createdAt);
        
        // Cek Level 2: Breached (Melewati batas SLA 100%)
        if (elapsed >= totalDuration && escalationLevel < 2) {
          await doc.reference.update({
            'escalation_level': 2,
            'priority': 'Urgent',
          });

          // Logika: Alihkan tiket ke Supervisor/Koordinator. 
          // Jika kita tidak memetakan spesifik siapa supervisornya di sini, minimal prioritas & level diupdate.
          
          await doc.reference.collection('messages').add({
            'sender_id': 'system',
            'text': '⚠️ [SLA-Breached] Tiket telah melewati batas waktu penyelesaian. Tiket ini telah dieskalasi ke Supervisor dan prioritas dinaikkan menjadi Urgent.',
            'timestamp': FieldValue.serverTimestamp(),
          });
          
          await _firestore.collection('tickets').doc(doc.id).collection('status_history').add({
            'status': status, // Status tetap, hanya dicatat pelanggaran SLA
            'label': 'SLA Breached',
            'timestamp': FieldValue.serverTimestamp(),
          });
        } 
        // Cek Level 1: Warning (Melewati batas SLA 80%)
        else if (elapsed.inMilliseconds >= totalDuration.inMilliseconds * 0.8 && escalationLevel < 1) {
          await doc.reference.update({
            'escalation_level': 1,
          });

          await doc.reference.collection('messages').add({
            'sender_id': 'system',
            'text': '⚠️ Peringatan: Waktu penanganan tiket sudah mencapai 80% dari batas SLA. Harap segera diselesaikan.',
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Auto-escalation error: $e');
    }
  }
}
