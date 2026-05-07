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
    };
  }
}
