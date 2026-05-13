import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String ticketId;
  final DateTime createdAt;
  final String category; // 'Laptop', 'Printer', 'Jaringan', 'Proyektor'
  final String description;
  final String status; // 'Open', 'In Progress', 'Pending', 'Resolved'
  final String priority; // 'Low', 'Medium', 'High'
  final String requesterId;
  final String? technicianId;
  final String? imageUrl;
  final String? location;
  final List<String>? resolvedImageUrls;
  final String? note;
  final String? photoBeforeUrl;
  final String? photoAfterUrl;
  final DateTime? resolvedAt;
  final DateTime? inProgressAt;

  TicketModel({
    required this.ticketId,
    required this.createdAt,
    required this.category,
    required this.description,
    required this.status,
    required this.priority,
    required this.requesterId,
    this.technicianId,
    this.imageUrl,
    this.location,
    this.resolvedImageUrls,
    this.note,
    this.photoBeforeUrl,
    this.photoAfterUrl,
    this.resolvedAt,
    this.inProgressAt,
  });

  factory TicketModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TicketModel(
      ticketId: documentId,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      category: data['category'] ?? 'Lainnya',
      description: data['description'] ?? '',
      status: data['status'] ?? 'Open',
      priority: data['priority'] ?? 'Low',
      requesterId: data['requester_id'] ?? '',
      technicianId: data['technician_id'],
      imageUrl: data['image_url'],
      location: data['location'],
      resolvedImageUrls: data['resolved_image_urls'] != null 
          ? List<String>.from(data['resolved_image_urls']) 
          : null,
      note: data['note'],
      photoBeforeUrl: data['photo_before_url'],
      photoAfterUrl: data['photo_after_url'],
      resolvedAt: data['resolved_at'] != null 
          ? (data['resolved_at'] as Timestamp).toDate() 
          : null,
      inProgressAt: data['in_progress_at'] != null 
          ? (data['in_progress_at'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'created_at': Timestamp.fromDate(createdAt),
      'category': category,
      'description': description,
      'status': status,
      'priority': priority,
      'requester_id': requesterId,
      if (technicianId != null) 'technician_id': technicianId,
      if (imageUrl != null) 'image_url': imageUrl,
      if (location != null) 'location': location,
      if (resolvedImageUrls != null) 'resolved_image_urls': resolvedImageUrls,
      if (note != null && note!.isNotEmpty) 'note': note,
      if (photoBeforeUrl != null) 'photo_before_url': photoBeforeUrl,
      if (photoAfterUrl != null) 'photo_after_url': photoAfterUrl,
      if (resolvedAt != null) 'resolved_at': Timestamp.fromDate(resolvedAt!),
      if (inProgressAt != null) 'in_progress_at': Timestamp.fromDate(inProgressAt!),
    };
  }
}
