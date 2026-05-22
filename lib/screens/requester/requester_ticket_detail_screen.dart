import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../chat_screen.dart';
import '../../services/chat_service.dart';
import '../shared/ticket_card.dart';
import '../../utils/app_notifications.dart';
import '../../utils/app_colors.dart';

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
    final confirm = await AppNotifications.showConfirmDialog(
      context,
      title: 'Batalkan Tiket',
      message:
          'Apakah Anda yakin masalah sudah terselesaikan dan ingin membatalkan tiket ini?',
      confirmLabel: 'Batalkan',
      cancelLabel: 'Tutup',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      setState(() => _isCancelling = true);
      try {
        await Provider.of<TicketProvider>(
          context,
          listen: false,
        ).updateTicketStatus(widget.ticket.ticketId, 'Resolved');
        if (mounted) {
          AppNotifications.showNotification(
            context,
            title: 'Sukses',
            message: 'Tiket berhasil dibatalkan/diselesaikan.',
            isError: false,
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          AppNotifications.showNotification(
            context,
            title: 'Gagal',
            message: 'Gagal: $e',
            isError: true,
          );
        }
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
    if (status.toLowerCase() == 'open') return const Color(0xFFF59E0B);
    return const Color(0xFF94A3B8); // pending/unknown
  }

  String _statusLabel(String status) {
    if (status.toLowerCase() == 'in progress') return 'Diproses';
    if (status.toLowerCase() == 'resolved') return 'Selesai';
    if (status.toLowerCase() == 'open') return 'Diajukan';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
      backgroundColor: c.background,
      appBar: buildSbmAppBar(),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => ChatScreen(ticket: widget.ticket),
      //       ),
      //     );
      //   },
      //   backgroundColor: c.primary,
      //   child: const Icon(
      //     Icons.chat_bubble_outline_rounded,
      //     color: Colors.white,
      //   ),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    color: c.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kembali ke Inbox',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shortId,
                  style: TextStyle(
                    color: c.textSecondary,
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
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
                    color: c.isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business, size: 12, color: c.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        widget.ticket.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '•   ${_formatDate(widget.ticket.createdAt)}',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Card 1: Deskripsi Masalah
            _buildCardWrapper(
              c: c,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deskripsi Masalah',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayDesc,
                    style: TextStyle(
                      fontSize: 14,
                      color: c.textSecondary,
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
                            color: c.surfaceElevated,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: c.textMuted,
                                  size: 40,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(
                                    color: c.textSecondary,
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
                  if (widget.ticket.technicianId != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: c.border),
                    ),
                    _buildTechnicianRow(widget.ticket.technicianId!, c),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Status Perjalanan
            _buildCardWrapper(
              c: c,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Perjalanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tickets')
                        .doc(widget.ticket.ticketId)
                        .collection('status_history')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Gagal memuat riwayat: ${snapshot.error}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final history = snapshot.data!.docs.toList();
                      // Sort locally to avoid index requirement
                      history.sort((a, b) {
                        final tsA =
                            (a.data() as Map<String, dynamic>)['timestamp']
                                as Timestamp?;
                        final tsB =
                            (b.data() as Map<String, dynamic>)['timestamp']
                                as Timestamp?;
                        if (tsA == null || tsB == null) return 0;
                        return tsA.compareTo(tsB);
                      });

                      if (history.isEmpty) {
                        return Text(
                          'Belum ada riwayat status.',
                          style: TextStyle(fontSize: 13, color: c.textMuted),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final data =
                              history[index].data() as Map<String, dynamic>;
                          final label = data['label'] ?? data['status'];
                          final time = data['timestamp'] != null
                              ? (data['timestamp'] as Timestamp).toDate()
                              : null;

                          return _buildTimelineItem(
                            label,
                            time != null
                                ? DateFormat('dd MMM, HH:mm').format(time)
                                : 'Proses...',
                            true, // Mark as completed since it's in history
                            index ==
                                history.length -
                                    1, // isCurrent if it's the last one
                            index == history.length - 1, // isLast
                            c,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Catatan Teknisi
            if (widget.ticket.note != null &&
                widget.ticket.note!.isNotEmpty) ...[
              _buildCardWrapper(
                c: c,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Teknisi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        widget.ticket.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textSecondary,
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
            if (widget.ticket.photoBeforeUrl != null ||
                widget.ticket.photoAfterUrl != null) ...[
              _buildCardWrapper(
                c: c,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bukti Perbaikan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.ticket.photoBeforeUrl != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sebelum',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: c.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.ticket.photoBeforeUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 120,
                                              color: c.surfaceElevated,
                                              child: Center(
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: c.textMuted,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.ticket.photoBeforeUrl != null &&
                            widget.ticket.photoAfterUrl != null)
                          const SizedBox(width: 12),
                        if (widget.ticket.photoAfterUrl != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sesudah',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: c.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.ticket.photoAfterUrl!,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 120,
                                              color: c.surfaceElevated,
                                              child: Center(
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: c.textMuted,
                                                ),
                                              ),
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
                  color: c.isDark
                      ? const Color(0xFF2E1919)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: c.isDark
                        ? const Color(0xFF4D1D1D)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembatalan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: c.isDark
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jika masalah sudah terselesaikan sendiri, Anda dapat membatalkan tiket ini.',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.isDark
                            ? const Color(0xFFFCA5A5).withOpacity(0.8)
                            : const Color(0xFF7F1D1D),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isCancelling ? null : _cancelTicket,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.isDark
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFB91C1C),
                          side: BorderSide(
                            color: c.isDark
                                ? const Color(0xFF4D1D1D)
                                : const Color(0xFFF87171),
                          ),
                          backgroundColor: c.surface,
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

  Widget _buildCardWrapper({required Widget child, required AppColors c}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.transparent
                : Colors.black.withOpacity(0.02),
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
    AppColors c,
  ) {
    final circleColor = c.textPrimary;
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
                  color: isCompleted ? circleColor : c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted || isCurrent ? circleColor : c.border,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: c.isDark ? Colors.black : Colors.white,
                      )
                    : isCurrent
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: circleColor,
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
                    color: isCompleted ? circleColor : c.border,
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
                          ? c.textPrimary
                          : c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: isCompleted || isCurrent
                          ? c.textSecondary
                          : c.textMuted,
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

  Widget _buildTechnicianRow(String technicianId, AppColors c) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(technicianId)
          .get(),
      builder: (_, snap) {
        String name = 'Memuat...';
        String? photoUrl;
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          name = d['name'] ?? 'Teknisi';
          photoUrl = d['photoUrl'] as String?;
        }
        return Row(
          children: [
            if (photoUrl != null && photoUrl.isNotEmpty)
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(photoUrl),
                backgroundColor: c.primaryLight,
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.engineering_outlined,
                  size: 20,
                  color: c.primary,
                ),
              ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teknisi Penanggung Jawab',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
