import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../chat_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Warna & helpers
// ─────────────────────────────────────────────────────────────────────────────
Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'in progress':
      return const Color(0xFF1A73E8);
    case 'resolved':
      return const Color(0xFF1E8C45);
    case 'pending':
      return const Color(0xFFF29900);
    default:
      return const Color(0xFF9E9E9E);
  }
}

Color _statusBg(String status) {
  switch (status.toLowerCase()) {
    case 'in progress':
      return const Color(0xFFE8F0FE);
    case 'resolved':
      return const Color(0xFFE6F4EA);
    case 'pending':
      return const Color(0xFFFEF7E0);
    default:
      return const Color(0xFFF5F5F5);
  }
}

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'in progress':
      return 'In Progress';
    case 'resolved':
      return 'Resolved';
    case 'pending':
      return 'Pending';
    case 'open':
      return 'Open';
    default:
      return status;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class TicketDetailScreen extends StatelessWidget {
  final TicketModel ticket;
  const TicketDetailScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final isTech = user?.role == 'technician';
    final ticketProvider = Provider.of<TicketProvider>(context);

    final isAdmin = user?.role == 'admin';

    // Short ticket ID display
    final shortId = '#TKT-${ticket.ticketId.substring(0, 8).toUpperCase()}';

    final techKey = GlobalKey<_TechnicianActionState>();

    Future<void> _deleteTicket(BuildContext ctx) async {
      final confirm = await showDialog<bool>(
        context: ctx,
        builder: (c) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Hapus Tiket',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C),
            ),
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus tiket ini secara permanen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                elevation: 0,
              ),
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm == true && ctx.mounted) {
        await ctx.read<TicketProvider>().deleteTicket(ticket.ticketId);
        if (ctx.mounted) Navigator.pop(ctx);
      }
    }

    Future<void> _changeDate(BuildContext ctx) async {
      final picked = await showDatePicker(
        context: ctx,
        initialDate: ticket.createdAt,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (c, child) {
          return Theme(
            data: Theme.of(c).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1A3A5C), // header background color
                onPrimary: Colors.white, // header text color
                onSurface: Color(0xFF1A3A5C), // body text color
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && ctx.mounted) {
        final time = await showTimePicker(
          context: ctx,
          initialTime: TimeOfDay.fromDateTime(ticket.createdAt),
          builder: (c, child) {
            return Theme(
              data: Theme.of(c).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1A3A5C),
                  onSurface: Color(0xFF1A3A5C),
                ),
              ),
              child: child!,
            );
          },
        );

        if (time != null && ctx.mounted) {
          final newDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          await ctx.read<TicketProvider>().updateTicketDate(
            ticket.ticketId,
            newDate,
          );
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text(
                  'Tanggal tiket berhasil diperbarui. Silakan refresh halaman untuk melihat perubahan.',
                ),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
          }
        }
      }
    }

    Future<void> _makeCall(bool isVideo) async {
      final currentUserId = user?.uid;
      final otherUserId = ticket.requesterId == currentUserId
          ? ticket.technicianId
          : ticket.requesterId;

      if (otherUserId == null || otherUserId.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengguna lain belum tersedia')),
          );
        }
        return;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();
        final phoneNumber = doc.data()?['phoneNumber'] as String?;

        if (phoneNumber == null || phoneNumber.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nomor telepon tidak tersedia')),
            );
          }
          return;
        }

        if (isVideo) {
          final roomName = 'sbm_ticket_${ticket.ticketId}';
          final Uri launchUri = Uri.parse('https://meet.jit.si/$roomName');
          if (await canLaunchUrl(launchUri)) {
            await launchUrl(launchUri, mode: LaunchMode.externalApplication);
          }
        } else {
          final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
          if (await canLaunchUrl(launchUri)) {
            await launchUrl(launchUri);
          }
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      // ── Bottom Button (Teknisi) ──────────────────────────────────────────
      bottomNavigationBar: isTech
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Consumer<TicketProvider>(
                builder: (_, tp, __) => ElevatedButton.icon(
                  onPressed: tp.isLoading
                      ? null
                      : () => techKey.currentState?._submit(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  icon: tp.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                        ),
                  label: Text(
                    tp.isLoading ? 'Menyimpan...' : 'Selesaikan Tiket',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : null,
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF1A3A5C),
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali ke Kotak Masuk',
        ),
        title: const Text(
          'Kembali ke Kotak Masuk',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF1A3A5C),
            fontWeight: FontWeight.w500,
          ),
        ),
        titleSpacing: 0,
        centerTitle: false,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.phone_outlined, color: Color(0xFF1A73E8)),
          //   tooltip: 'Telepon',
          //   onPressed: () => _makeCall(false),
          // ),
          // IconButton(
          //   icon: const Icon(Icons.video_call_outlined, color: Color(0xFF1A73E8)),
          //   tooltip: 'Video Call',
          //   onPressed: () => _makeCall(true),
          // ),
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF1A73E8),
            ),
            tooltip: 'Chat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(ticket: ticket)),
            ),
          ),
          if (isAdmin)
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF1A3A5C),
              ),
              onSelected: (val) {
                if (val == 'edit_date') {
                  _changeDate(context);
                } else if (val == 'delete') {
                  _deleteTicket(context);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit_date',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_calendar_rounded,
                        color: Color(0xFF1A3A5C),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ubah Tanggal',
                        style: TextStyle(color: Color(0xFF1A3A5C)),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text('Hapus Tiket', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip + ticket ID
            Row(
              children: [
                _StatusChip(status: ticket.status),
                const SizedBox(width: 10),
                Text(
                  shortId,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              ticket.category,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),

            // ── Detail Laporan Card ─────────────────────────────────────
            _SectionCard(
              title: 'Detail Laporan',
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Lokasi',
                    value: ticket.location ?? 'Tidak tersedia',
                  ),
                  const _Divider(),
                  _DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Kategori',
                    value: ticket.category,
                  ),
                  const _Divider(),
                  // Pelapor — async fetch
                  _RequesterRow(requesterId: ticket.requesterId),
                  const _Divider(),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Waktu Laporan',
                    value: DateFormat(
                      "dd MMM yyyy, HH:mm 'WIB'",
                    ).format(ticket.createdAt),
                  ),
                  const SizedBox(height: 12),
                  // Deskripsi
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        '"${ticket.description}"',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: Color(0xFF374151),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Lampiran Foto ───────────────────────────────────────────
            if (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Lampiran Foto',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      ticket.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: const Color(0xFFF3F4F6),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF9CA3AF),
                          size: 48,
                        ),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],

            // ── Tindakan / Catatan Teknisi ─────────────────────────────
            if ((ticket.note != null && ticket.note!.isNotEmpty) ||
                (ticket.resolvedImageUrls != null &&
                    ticket.resolvedImageUrls!.isNotEmpty)) ...[
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Tindakan Teknisi',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ticket.note != null && ticket.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            ticket.note!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.55,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                      if (ticket.resolvedImageUrls != null &&
                          ticket.resolvedImageUrls!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Foto Perbaikan:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ticket.resolvedImageUrls!
                              .map(
                                (url) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 100,
                                              height: 100,
                                              color: const Color(0xFFF3F4F6),
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.broken_image_outlined,
                                                color: Color(0xFF9CA3AF),
                                                size: 32,
                                              ),
                                            ),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: const Color(0xFFF3F4F6),
                                            alignment: Alignment.center,
                                            child: const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // ── Aksi Teknisi ────────────────────────────────────────────
            if (isTech) ...[
              const SizedBox(height: 20),
              _TechnicianAction(
                key: techKey,
                ticket: ticket,
                ticketProvider: ticketProvider,
                technicianId: user?.uid,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Teknisi: Pembaruan Status + Catatan + Foto
// ─────────────────────────────────────────────────────────────────────────────
class _TechnicianAction extends StatefulWidget {
  final TicketModel ticket;
  final TicketProvider ticketProvider;
  final String? technicianId;

  const _TechnicianAction({
    super.key,
    required this.ticket,
    required this.ticketProvider,
    this.technicianId,
  });

  @override
  State<_TechnicianAction> createState() => _TechnicianActionState();
}

class _TechnicianActionState extends State<_TechnicianAction> {
  late String _selectedStatus;
  final _noteController = TextEditingController();
  XFile? _beforeImage;
  XFile? _afterImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.ticket.status;
    if (widget.ticket.note != null) {
      _noteController.text = widget.ticket.note!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isBefore) async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) {
      setState(() {
        if (isBefore) {
          _beforeImage = img;
        } else {
          _afterImage = img;
        }
      });
    }
  }

  Future<void> _submit() async {
    final images = [
      if (_beforeImage != null) _beforeImage!,
      if (_afterImage != null) _afterImage!,
    ];

    await widget.ticketProvider.updateTicketStatus(
      widget.ticket.ticketId,
      _selectedStatus,
      technicianId: widget.technicianId,
      resolvedImages: images,
      note: _noteController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final statuses = ['Pending', 'In Progress', 'Resolved'];

    return _SectionCard(
      title: 'Pembaruan Status',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status toggle chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statuses.map((s) {
                final selected = _selectedStatus == s;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: selected ? Colors.white : _statusColor(s),
                      ),
                      const SizedBox(width: 6),
                      Text(s),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedStatus = s),
                  selectedColor: _statusColor(s),
                  backgroundColor: _statusBg(s),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : _statusColor(s),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selected
                          ? _statusColor(s)
                          : _statusColor(s).withOpacity(0.4),
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Catatan Perbaikan
            const Text(
              'Catatan Perbaikan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Masukkan detail tindakan yang telah dilakukan...',
                hintStyle: const TextStyle(
                  color: Color(0xFFADB5BD),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F9FC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF1A73E8),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),

            // Bukti Foto Perbaikan
            const Text(
              'Bukti Foto Perbaikan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _PhotoUploadBox(
                    label: 'Unggah Foto Sebelum',
                    image: _beforeImage,
                    onTap: () => _pickImage(true),
                    onRemove: () => setState(() => _beforeImage = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PhotoUploadBox(
                    label: 'Unggah Foto Sesudah',
                    image: _afterImage,
                    onTap: () => _pickImage(false),
                    onRemove: () => setState(() => _afterImage = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Format didukung: JPG, PNG (Maks 5MB per foto)',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Photo Upload Box
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoUploadBox extends StatelessWidget {
  final String label;
  final XFile? image;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoUploadBox({
    required this.label,
    required this.image,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD1D5DB),
            style: BorderStyle.solid,
          ),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 36,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.file(File(image!.path), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _statusColor(status).withOpacity(0.3)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequesterRow extends StatelessWidget {
  final String requesterId;
  const _RequesterRow({required this.requesterId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(requesterId)
          .get(),
      builder: (context, snap) {
        String name = 'Memuat...';
        String role = '';
        if (snap.hasData && snap.data!.exists) {
          final data = snap.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? 'Tidak diketahui';
          final r = data['role'] ?? '';
          if (r == 'student')
            role = 'Mahasiswa';
          else if (r == 'staff')
            role = 'Staf / Dosen';
          else
            role = r;
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pelapor',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role.isNotEmpty ? '$name ($role)' : name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFF3F4F6), indent: 50);
}
