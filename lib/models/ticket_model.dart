import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String ticketId;
  final DateTime createdAt;
  final String category; // 'Laptop', 'Printer', 'Jaringan', 'Proyektor'
  final String description;
  final String
  status; // 'New', 'Assigned', 'In Progress', 'Pending', 'Resolved', 'Closed', 'Re-opened'
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
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastMessageSender;
  
  // SLA & Escalation
  final DateTime? targetResolutionAt;
  final int escalationLevel; // 0: Normal, 1: Warning (80% SLA), 2: Breached (100% SLA)

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
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageSender,
    this.targetResolutionAt,
    this.escalationLevel = 0,
  });

  factory TicketModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TicketModel(
      ticketId: documentId,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      category: data['category'] ?? 'Lainnya',
      description: data['description'] ?? '',
      status: data['status'] ?? 'New',
      priority: data['priority'] ?? 'Low',
      requesterId: data['requester_id'] ?? '',
      technicianId: data['technician_id'],
      imageUrl: data['image_url'] ?? data['imageUrl'] ?? data['image'],
      location: data['location'],
      resolvedImageUrls: data['resolved_image_urls'] != null
          ? List<String>.from(data['resolved_image_urls'])
          : null,
      note: data['note'],
      photoBeforeUrl: data['photo_before_url'] ?? data['photoBeforeUrl'],
      photoAfterUrl: data['photo_after_url'] ?? data['photoAfterUrl'],
      resolvedAt: data['resolved_at'] != null
          ? (data['resolved_at'] as Timestamp).toDate()
          : null,
      inProgressAt: data['in_progress_at'] != null
          ? (data['in_progress_at'] as Timestamp).toDate()
          : null,
      lastMessageAt: data['last_message_at'] != null
          ? (data['last_message_at'] as Timestamp).toDate()
          : null,
      lastMessagePreview: data['last_message_preview'],
      lastMessageSender: data['last_message_sender'],
      targetResolutionAt: data['target_resolution_at'] != null
          ? (data['target_resolution_at'] as Timestamp).toDate()
          : null,
      escalationLevel: data['escalation_level'] ?? 0,
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
      if (inProgressAt != null)
        'in_progress_at': Timestamp.fromDate(inProgressAt!),
      if (targetResolutionAt != null)
        'target_resolution_at': Timestamp.fromDate(targetResolutionAt!),
      'escalation_level': escalationLevel,
    };
  }
}
