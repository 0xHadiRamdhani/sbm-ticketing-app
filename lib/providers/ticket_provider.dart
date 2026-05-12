import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ticket_model.dart';
import '../services/ticket_service.dart';

class TicketProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<TicketModel>> fetchTickets({String? role, String? uid, String? status}) {
    return _ticketService.getTickets(role: role, uid: uid, status: status);
  }

  Future<void> submitTicket({
    required String requesterId,
    required String category,
    required String description,
    required String priority,
    required String location,
    XFile? imageFile,
  }) async {
    _setLoading(true);
    try {
      await _ticketService.createTicket(
        requesterId: requesterId,
        category: category,
        description: description,
        priority: priority,
        location: location,
        imageFile: imageFile,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTicketStatus(String ticketId, String status, {String? technicianId, List<XFile>? resolvedImages, String? note, XFile? photoBefore, XFile? photoAfter}) async {
    _setLoading(true);
    try {
      await _ticketService.updateTicketStatus(ticketId, status, technicianId: technicianId, resolvedImages: resolvedImages, note: note, photoBefore: photoBefore, photoAfter: photoAfter);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    _setLoading(true);
    try {
      await _ticketService.deleteTicket(ticketId);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateTicketDate(String ticketId, DateTime newDate) async {
    _setLoading(true);
    try {
      await _ticketService.updateTicketDate(ticketId, newDate);
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
