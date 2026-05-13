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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tanggal tiket berhasil diperbarui.')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
          }
        }
      }
    }
  }

  Future<void> _deleteTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Tiket', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
        content: const Text('Apakah Anda yakin ingin menghapus tiket ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, elevation: 0),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: buildSbmAppBar(
        extraActions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF475569)),
            onSelected: (val) {
              if (val == 'date') _updateTicketDate();
              if (val == 'delete') _deleteTicket();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('Ubah Tanggal Tiket')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus Tiket', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(ticket: widget.ticket))),
        backgroundColor: const Color(0xFF1A3A5C),
        child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(
                children: [
                  Icon(Icons.arrow_back_ios_new, color: Color(0xFF475569), size: 18),
                  SizedBox(width: 8),
                  Text('Kembali ke Kotak Masuk', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatusChip(widget.ticket.status),
                const SizedBox(width: 12),
                Text(shortId, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            Text(displayTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            
            const SizedBox(height: 16),
            _buildSLATimer(),

            const SizedBox(height: 24),

            // Detail Laporan Card
            _buildSection('Detail Laporan', [
              _buildInfoRow(Icons.location_on_outlined, 'Lokasi', widget.ticket.location ?? 'Tidak ada lokasi'),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.category_outlined, 'Kategori', widget.ticket.category),
              const SizedBox(height: 16),
              _buildRequesterRow(widget.ticket.requesterId),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.access_time, 'Waktu Laporan', DateFormat('dd MMM yyyy, HH:mm').format(widget.ticket.createdAt) + ' WIB'),
              const SizedBox(height: 16),
              if (widget.ticket.technicianId != null)
                _buildTechnicianRow(widget.ticket.technicianId!),
              const SizedBox(height: 20),
              _buildDescriptionBox(displayDesc),
            ]),

            const SizedBox(height: 20),

            // Catatan Internal
            _buildInternalNotesSection(),

            const SizedBox(height: 20),

            // Timeline Riwayat Status
            _buildTimelineSection(),

            const SizedBox(height: 20),

            // Informasi Perbaikan
            if (widget.ticket.note != null || widget.ticket.photoAfterUrl != null)
              _buildSection('Informasi Perbaikan', [
                const Text('Catatan Teknisi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.ticket.note ?? 'Tidak ada catatan.', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                ),
                if (widget.ticket.photoBeforeUrl != null || widget.ticket.photoAfterUrl != null) ...[
                  const SizedBox(height: 24),
                  const Text('Bukti Foto Perbaikan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  if (widget.ticket.photoBeforeUrl != null) ...[
                    const Text('Foto Sebelum:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    _buildImage(widget.ticket.photoBeforeUrl!),
                    const SizedBox(height: 12),
                  ],
                  if (widget.ticket.photoAfterUrl != null) ...[
                    const Text('Foto Sesudah:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    _buildImage(widget.ticket.photoAfterUrl!),
                  ],
                ],
              ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(20), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.all(20), child: Text('Riwayat Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
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

                if (history.isEmpty) return const Text('Tidak ada riwayat status.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)));

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

  Widget _buildTimelineItem(String label, String time, bool isCurrent, bool isLast) {
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
                  color: isCurrent ? const Color(0xFF0F172A) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F172A),
                    width: 2,
                  ),
                ),
                child: isCurrent
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFF0F172A),
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
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
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

  Widget _buildInternalNotesSection() {
    final TextEditingController _noteController = TextEditingController();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 18, color: Color(0xFFC2410C)),
                const SizedBox(width: 8),
                const Text('Catatan Internal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                const Spacer(),
                const Text('Hanya Staff', style: TextStyle(fontSize: 10, color: Color(0xFFC2410C), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFED7AA)),
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
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFFED7AA), width: 0.5))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(data['author_name'] ?? 'Admin', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                            Text(
                              data['timestamp'] != null ? DateFormat('dd MMM, HH:mm').format((data['timestamp'] as Timestamp).toDate()) : '-',
                              style: const TextStyle(fontSize: 10, color: Color(0xFFC2410C)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(data['note'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF431407))),
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
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFC2410C)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
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
                  icon: const Icon(Icons.send_rounded, color: Color(0xFFC2410C)),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionBox(String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deskripsi Kendala', style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('"$desc"', style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5)),
          if (widget.ticket.imageUrl != null) ...[
            const SizedBox(height: 12),
            _buildImage(widget.ticket.imageUrl!),
          ],
        ],
      ),
    );
  }

  Widget _buildRequesterRow(String requesterId) {
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
        return _buildInfoRow(Icons.person_outline, 'Pelapor', display);
      },
    );
  }

  Widget _buildTechnicianRow(String technicianId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(technicianId).get(),
      builder: (_, snap) {
        String name = 'Memuat...';
        if (snap.hasData && snap.data!.exists) {
          final d = snap.data!.data() as Map<String, dynamic>;
          name = d['name'] ?? 'Teknisi';
        }
        return _buildInfoRow(Icons.engineering_outlined, 'Teknisi Penanggung Jawab', name);
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = const Color(0xFFF59E0B);
    if (status.toLowerCase() == 'in progress') color = const Color(0xFF06B6D4);
    if (status.toLowerCase() == 'resolved') color = const Color(0xFF10B981);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildImage(String url) {
    return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, width: double.infinity, height: 140, fit: BoxFit.cover));
  }
}
