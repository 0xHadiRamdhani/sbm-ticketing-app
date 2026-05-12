import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../chat_screen.dart';
import '../../services/chat_service.dart';

class RequesterTicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;
  const RequesterTicketDetailScreen({Key? key, required this.ticket})
    : super(key: key);

  @override
  State<RequesterTicketDetailScreen> createState() =>
      _RequesterTicketDetailScreenState();
}

class _RequesterTicketDetailScreenState
    extends State<RequesterTicketDetailScreen> {
  bool _isCancelling = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _cancelTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Batalkan Tiket',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFB91C1C),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin masalah sudah terselesaikan dan ingin membatalkan tiket ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(
              'Tutup',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              elevation: 0,
            ),
            child: const Text(
              'Batalkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isCancelling = true);
      try {
        await Provider.of<TicketProvider>(
          context,
          listen: false,
        ).updateTicketStatus(widget.ticket.ticketId, 'Resolved');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tiket berhasil dibatalkan/diselesaikan.'),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      } finally {
        if (mounted) setState(() => _isCancelling = false);
      }
    }
  }

  String _formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy, HH:mm').format(dt) + ' WIB';

  Color _statusColor(String status) {
    if (status.toLowerCase() == 'in progress') return const Color(0xFF1A73E8);
    if (status.toLowerCase() == 'resolved') return const Color(0xFF1E8C45);
    return const Color(0xFFF29900); // pending
  }

  String _statusLabel(String status) {
    if (status.toLowerCase() == 'in progress') return 'Diproses';
    if (status.toLowerCase() == 'resolved') return 'Selesai';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final shortId =
        '#TKT-${widget.ticket.ticketId.substring(0, 4).toUpperCase()}-${widget.ticket.ticketId.substring(4, 8).toUpperCase()}';

    // Parses ticket title from description if it contains "Judul: " format
    String displayTitle = widget.ticket.category;
    String displayDesc = widget.ticket.description;

    if (widget.ticket.description.startsWith('Judul: ')) {
      final parts = widget.ticket.description.split('\n\nDetail:\n');
      if (parts.length == 2) {
        displayTitle = parts[0].replaceFirst('Judul: ', '').trim();
        displayDesc = parts[1].trim();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        leadingWidth: 200,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Row(
            children: [
              SizedBox(width: 16),
              Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF475569),
                size: 20,
              ),
              SizedBox(width: 6),
              Text(
                'Kembali ke Inbox',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(ticket: widget.ticket),
            ),
          );
        },
        backgroundColor: const Color(0xFF1A3A5C),
        child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shortId,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(widget.ticket.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.sync,
                        size: 12,
                        color: _statusColor(widget.ticket.status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel(widget.ticket.status),
                        style: TextStyle(
                          color: _statusColor(widget.ticket.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business,
                        size: 12,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.ticket.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '•   ${_formatDate(widget.ticket.createdAt)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Card 1: Deskripsi Masalah
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi Masalah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayDesc,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                  if (widget.ticket.imageUrl != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.ticket.imageUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 180,
                            color: const Color(0xFFF1F5F9),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: Color(0xFF94A3B8),
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),



            // Card 3: Status Perjalanan
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Perjalanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTimelineItem(
                    'Diajukan',
                    _formatDate(widget.ticket.createdAt),
                    true,
                    false,
                    false,
                  ),
                  _buildTimelineItem(
                    'Diverifikasi',
                    'Menunggu Teknisi',
                    widget.ticket.status != 'Pending',
                    widget.ticket.status == 'Pending',
                    false,
                  ),
                  _buildTimelineItem(
                    'Sedang Dikerjakan',
                    'Oleh Teknisi',
                    widget.ticket.status == 'Resolved',
                    widget.ticket.status == 'In Progress',
                    widget.ticket.status != 'Resolved',
                  ),
                  if (widget.ticket.status == 'Resolved')
                    _buildTimelineItem(
                      'Selesai',
                      'Tiket Ditutup',
                      true,
                      true,
                      true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Catatan Teknisi
            if (widget.ticket.note != null && widget.ticket.note!.isNotEmpty) ...[
              _buildCardWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catatan Teknisi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        widget.ticket.note!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Card Bukti Perbaikan (Before & After)
            if (widget.ticket.photoBeforeUrl != null || widget.ticket.photoAfterUrl != null) ...[
              _buildCardWrapper(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bukti Perbaikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.ticket.photoBeforeUrl != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sebelum', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.ticket.photoBeforeUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 120, color: const Color(0xFFF1F5F9),
                                      child: const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.ticket.photoBeforeUrl != null && widget.ticket.photoAfterUrl != null)
                          const SizedBox(width: 12),
                        if (widget.ticket.photoAfterUrl != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Sesudah', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.ticket.photoAfterUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 120, color: const Color(0xFFF1F5F9),
                                      child: const Center(child: Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8))),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Card 4: Pembatalan
            if (widget.ticket.status != 'Resolved')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pembatalan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Jika masalah sudah terselesaikan sendiri, Anda dapat membatalkan tiket ini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7F1D1D),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling ? null : _cancelTicket,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB91C1C),
                          side: const BorderSide(color: Color(0xFFF87171)),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text(
                          'Batalkan Tiket',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    bool isCompleted,
    bool isCurrent,
    bool isLast,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFF0F172A) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : isCurrent
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isCompleted || isCurrent
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted || isCurrent
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
