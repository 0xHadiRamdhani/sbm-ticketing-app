import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../chat_screen.dart';
import '../shared/ticket_card.dart';
import '../../services/audit_service.dart';
import '../../services/ticket_service.dart';
import '../../utils/app_notifications.dart';
import '../../utils/app_colors.dart';

class AdminTicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;
  const AdminTicketDetailScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<AdminTicketDetailScreen> createState() => _AdminTicketDetailScreenState();
}

class _AdminTicketDetailScreenState extends State<AdminTicketDetailScreen> {
  
  Future<void> _updateTicketDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.ticket.createdAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A3A5C)),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.ticket.createdAt),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year, pickedDate.month, pickedDate.day,
          pickedTime.hour, pickedTime.minute,
        );
        
        try {
          await context.read<TicketProvider>().updateTicketDate(widget.ticket.ticketId, newDateTime);
          
          // Audit Log
          await AuditService().logAction(
            actionType: 'UPDATE_TICKET_DATE',
            targetId: widget.ticket.ticketId,
            description: 'Mengubah tanggal tiket dari ${widget.ticket.createdAt} ke $newDateTime',
          );

          if (mounted) {
            AppNotifications.showNotification(
              context,
              title: 'Sukses',
              message: 'Tanggal tiket berhasil diperbarui.',
              isError: false,
            );
          }
        } catch (e) {
          if (mounted) {
            AppNotifications.showNotification(
              context,
              title: 'Gagal',
              message: 'Gagal memperbarui tanggal tiket: $e',
              isError: true,
            );
          }
        }
      }
    }
  }

  Future<void> _deleteTicket() async {
    final confirm = await AppNotifications.showConfirmDialog(
      context,
      title: 'Hapus Tiket',
      message: 'Apakah Anda yakin ingin menghapus tiket ini secara permanen?',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
    );
    if (confirm == true && mounted) {
      await context.read<TicketProvider>().deleteTicket(widget.ticket.ticketId);
      
      // Audit Log
      await AuditService().logAction(
        actionType: 'DELETE_TICKET',
        targetId: widget.ticket.ticketId,
        description: 'Menghapus tiket kategori ${widget.ticket.category}',
      );

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final shortId = '#TKT-${widget.ticket.ticketId.substring(0, 4).toUpperCase()}-${widget.ticket.ticketId.substring(4, 8).toUpperCase()}';
    
    // Parse title and description
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
      appBar: buildSbmAppBar(
        extraActions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: c.textSecondary),
            onSelected: (val) {
              if (val == 'date') _updateTicketDate();
              if (val == 'delete') _deleteTicket();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'date', child: Text('Ubah Tanggal Tiket', style: TextStyle(color: c.textPrimary))),
              const PopupMenuItem(value: 'delete', child: Text('Hapus Tiket', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(ticket: widget.ticket))),
        backgroundColor: c.primary,
        child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, color: c.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text('Kembali ke Kotak Masuk', style: TextStyle(color: c.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatusChip(widget.ticket.status),
                const SizedBox(width: 12),
                Text(shortId, style: TextStyle(color: c.textSecondary, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Text(displayTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c.textPrimary)),
            
            const SizedBox(height: 16),
            _buildSLATimer(),

            const SizedBox(height: 24),

            // Detail Laporan Card
            _buildSection('Detail Laporan', [
              _buildInfoRow(Icons.location_on_outlined, 'Lokasi', widget.ticket.location ?? 'Tidak ada lokasi', c),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.category_outlined, 'Kategori', widget.ticket.category, c),
              const SizedBox(height: 16),
              _buildRequesterRow(widget.ticket.requesterId, c),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.access_time, 'Waktu Laporan', DateFormat('dd MMM yyyy, HH:mm').format(widget.ticket.createdAt) + ' WIB', c),
              const SizedBox(height: 16),
              if (widget.ticket.technicianId != null)
                _buildTechnicianRow(widget.ticket.technicianId!, c),
              const SizedBox(height: 20),
              _buildDescriptionBox(displayDesc, c),
            ], c),

            const SizedBox(height: 20),

            // Catatan Internal
            _buildInternalNotesSection(c),

            const SizedBox(height: 20),

            // Timeline Riwayat Status
            _buildTimelineSection(c),

            const SizedBox(height: 20),

            // Informasi Perbaikan
            if (widget.ticket.note != null || widget.ticket.photoAfterUrl != null)
              _buildSection('Informasi Perbaikan', [
                Text('Catatan Teknisi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.textPrimary)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: c.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.ticket.note ?? 'Tidak ada catatan.', style: TextStyle(fontSize: 13, color: c.textSecondary)),
                ),
                if (widget.ticket.photoBeforeUrl != null || widget.ticket.photoAfterUrl != null) ...[
                  const SizedBox(height: 24),
                  Text('Bukti Foto Perbaikan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.textPrimary)),
                  const SizedBox(height: 12),
                  if (widget.ticket.photoBeforeUrl != null) ...[
                    Text('Foto Sebelum:', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                    const SizedBox(height: 4),
                    _buildImage(widget.ticket.photoBeforeUrl!),
                    const SizedBox(height: 12),
                  ],
                  if (widget.ticket.photoAfterUrl != null) ...[
                    Text('Foto Sesudah:', style: TextStyle(fontSize: 11, color: c.textSecondary)),
                    const SizedBox(height: 4),
                    _buildImage(widget.ticket.photoAfterUrl!),
                  ],
                ],
              ], c),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, AppColors c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(20), child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.textPrimary))),
          Divider(height: 1, color: c.border),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(AppColors c) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(20), child: Text('Riwayat Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.textPrimary))),
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.all(20),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tickets').doc(widget.ticket.ticketId).collection('status_history').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Gagal memuat riwayat: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  );
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final history = snapshot.data!.docs.toList();
                // Sort locally to avoid index requirement
                history.sort((a, b) {
                  final tsA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final tsB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (tsA == null || tsB == null) return 0;
                  return tsA.compareTo(tsB);
                });
 
                if (history.isEmpty) return Text('Tidak ada riwayat status.', style: TextStyle(fontSize: 13, color: c.textMuted));
 
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final data = history[index].data() as Map<String, dynamic>;
                    final label = data['label'] ?? data['status'];
                    final time = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null;
                    
                    return _buildTimelineItem(
                      label,
                      time != null ? DateFormat('dd MMM, HH:mm').format(time) : '-',
                      index == history.length - 1, // isCurrent (latest)
                      index == history.length - 1, // isLast
                      c,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String label, String time, bool isCurrent, bool isLast, AppColors c) {
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
                  color: isCurrent ? circleColor : c.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: circleColor,
                    width: 2,
                  ),
                ),
                child: isCurrent
                    ? Icon(Icons.check, size: 14, color: c.isDark ? Colors.black : Colors.white)
                    : Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: circleColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: circleColor,
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
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textSecondary,
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

  Widget _buildInternalNotesSection(AppColors c) {
    final TextEditingController _noteController = TextEditingController();
    
    final bgNotes = c.isDark ? const Color(0xFF2E2315) : const Color(0xFFFFF7ED);
    final borderNotes = c.isDark ? const Color(0xFF4D3715) : const Color(0xFFFED7AA);
    final textOrange = c.isDark ? const Color(0xFFFBBF24) : const Color(0xFFC2410C);
    final textAuthor = c.isDark ? const Color(0xFFFDE68A) : const Color(0xFF9A3412);
    final textContent = c.isDark ? const Color(0xFFFFFBEB) : const Color(0xFF431407);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgNotes,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderNotes),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: textOrange),
                const SizedBox(width: 8),
                Text('Catatan Internal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textOrange)),
                const Spacer(),
                Text('Hanya Staff', style: TextStyle(fontSize: 10, color: textOrange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Divider(height: 1, color: borderNotes),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tickets').doc(widget.ticket.ticketId).collection('internal_notes').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final notes = snapshot.data!.docs;
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final data = notes[index].data() as Map<String, dynamic>;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderNotes, width: 0.5))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(data['author_name'] ?? 'Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textAuthor)),
                            Text(
                              data['timestamp'] != null ? DateFormat('dd MMM, HH:mm').format((data['timestamp'] as Timestamp).toDate()) : '-',
                              style: TextStyle(fontSize: 10, color: textOrange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(data['note'] ?? '', style: TextStyle(fontSize: 13, color: textContent)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Tambah catatan internal...',
                      hintStyle: TextStyle(fontSize: 13, color: textOrange.withOpacity(0.6)),
                      filled: true,
                      fillColor: c.isDark ? const Color(0xFF251A0F) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    style: TextStyle(fontSize: 13, color: c.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    if (_noteController.text.trim().isEmpty) return;
                    final auth = context.read<AuthProvider>();
                    await TicketService().addInternalNote(
                      widget.ticket.ticketId,
                      _noteController.text.trim(),
                      auth.user?.uid ?? '',
                      auth.user?.name ?? 'Admin',
                    );
                    _noteController.clear();
                  },
                  icon: Icon(Icons.send_rounded, color: textOrange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSLATimer() {
    // SLA Definitions (in hours)
    final Map<String, int> slaTargets = {
      'Critical': 2,
      'High': 4,
      'Medium': 8,
      'Low': 24,
    };

    final targetHours = slaTargets[widget.ticket.priority] ?? 24;
    final deadline = widget.ticket.createdAt.add(Duration(hours: targetHours));
    final now = DateTime.now();
    final isOverdue = now.isAfter(deadline);
    final remaining = deadline.difference(now);

    Color statusColor = isOverdue ? Colors.red : const Color(0xFF16A34A);
    if (!isOverdue && remaining.inHours < (targetHours * 0.25)) {
      statusColor = Colors.orange;
    }

    if (widget.ticket.status == 'Resolved') return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: statusColor),
              const SizedBox(width: 8),
              Text(
                isOverdue ? 'SLA Terlewati' : 'Target Penyelesaian (SLA)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor),
              ),
              const Spacer(),
              Text(
                isOverdue 
                  ? 'Terlambat ${remaining.abs().inHours} jam' 
                  : '${remaining.inHours}j ${remaining.inMinutes % 60}m tersisa',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isOverdue ? 1.0 : (now.difference(widget.ticket.createdAt).inMinutes / (targetHours * 60)).clamp(0.0, 1.0),
              backgroundColor: statusColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prioritas ${widget.ticket.priority}: Batas waktu $targetHours jam dari pembuatan.',
            style: TextStyle(fontSize: 11, color: statusColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, AppColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: c.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, color: c.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionBox(String desc, AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.surfaceElevated, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deskripsi Kendala', style: TextStyle(fontSize: 12, color: c.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('"$desc"', style: TextStyle(fontSize: 13, color: c.textPrimary, height: 1.5)),
          if (widget.ticket.imageUrl != null) ...[
            const SizedBox(height: 12),
            _buildImage(widget.ticket.imageUrl!),
          ],
        ],
      ),
    );
  }

  Widget _buildRequesterRow(String requesterId, AppColors c) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(requesterId).get(),
      builder: (_, snap) {
        String display = 'Memuat...';
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          final name = d['name'] ?? '-';
          final role = d['role'] ?? '';
          String roleLabel = role == 'student' ? 'Mahasiswa' : (role == 'staff' ? 'Dosen/Staff' : role);
          display = '$name ($roleLabel)';
        }
        return _buildInfoRow(Icons.person_outline, 'Pelapor', display, c);
      },
    );
  }

  Widget _buildTechnicianRow(String technicianId, AppColors c) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(technicianId).get(),
      builder: (_, snap) {
        String name = 'Memuat...';
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          name = d['name'] ?? 'Teknisi';
        }
        return _buildInfoRow(Icons.engineering_outlined, 'Teknisi Penanggung Jawab', name, c);
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = statusDotColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(statusLabel(status), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildImage(String url) {
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, width: double.infinity, height: 140, fit: BoxFit.cover));
  }
}
