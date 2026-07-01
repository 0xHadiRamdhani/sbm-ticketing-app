import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/ticket_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_notifications.dart';
import '../../../services/audit_service.dart';

class WebAdminTicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;
  const WebAdminTicketDetailScreen({Key? key, required this.ticket}) : super(key: key);

  @override
  State<WebAdminTicketDetailScreen> createState() => _WebAdminTicketDetailScreenState();
}

class _WebAdminTicketDetailScreenState extends State<WebAdminTicketDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _noteCtrl = TextEditingController();
  final TextEditingController _replyCtrl = TextEditingController();
  bool _isSubmitting = false;

  UserModel? _requester;
  UserModel? _technician;

  final List<String> _cannedResponses = [
    "Terima kasih atas laporannya. Tim IT SBM sedang melakukan pengecekan ke lokasi.",
    "Terkait laporan Anda, komponen yang rusak sedang dalam proses pemesanan. Mohon ketersediaannya untuk menunggu.",
    "Masalah telah berhasil diselesaikan. Silakan cek kembali jaringan/perangkat Anda. Jika masih terkendala, balas pesan ini.",
    "Laporan ini kami eskalasikan ke tingkat universitas (DTI ITB) karena berada di luar wewenang SBM."
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final reqDoc = await FirebaseFirestore.instance.collection('users').doc(widget.ticket.requesterId).get();
      if (reqDoc.exists) setState(() => _requester = UserModel.fromMap(reqDoc.data()!, reqDoc.id));

      if (widget.ticket.technicianId != null) {
        final techDoc = await FirebaseFirestore.instance.collection('users').doc(widget.ticket.technicianId).get();
        if (techDoc.exists) setState(() => _technician = UserModel.fromMap(techDoc.data()!, techDoc.id));
      }
    } catch (e) {
      debugPrint("Error loading users: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteCtrl.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text('Detail Tiket #${widget.ticket.ticketId.substring(0, 8).toUpperCase()}', 
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildTopActions(c),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: c.border.withOpacity(0.6), height: 1),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KIRI: Informasi Utama Tiket & Diskusi ─────────────────────
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSlaAlert(c),
                  const SizedBox(height: 24),
                  _buildHeaderInfo(c),
                  const SizedBox(height: 32),
                  
                  // Description Box
                  Text('Deskripsi Kendala', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
                    child: Text(widget.ticket.description, style: TextStyle(fontSize: 14, color: c.textSecondary, height: 1.5)),
                  ),
                  const SizedBox(height: 32),

                  // Tabs: Diskusi (Publik) vs Internal Notes
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF1D4ED8),
                      unselectedLabelColor: c.textMuted,
                      indicatorColor: const Color(0xFF1D4ED8),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.forum_outlined, size: 18), SizedBox(width: 8), Text('Diskusi Pengguna', style: TextStyle(fontWeight: FontWeight.w600))])),
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.lock_outline_rounded, size: 18), SizedBox(width: 8), Text('Catatan Internal', style: TextStyle(fontWeight: FontWeight.w600))])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tab Views
                  SizedBox(
                    height: 400, // Fixed height for demo, ideally flexible
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPublicDiscussionTab(c),
                        _buildInternalNotesTab(c),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // ── KANAN: Sidebar Meta Data & Activity Timeline ──────────────────
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(left: BorderSide(color: c.border.withOpacity(0.6))),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaSection('Status', _buildStatusBadge(widget.ticket.status), c),
                        const SizedBox(height: 20),
                        _buildMetaSection('Prioritas', _buildPriorityBadge(widget.ticket.priority), c),
                        const SizedBox(height: 20),
                        _buildMetaSection('Kategori', Text(widget.ticket.category, style: TextStyle(fontWeight: FontWeight.w600, color: c.textPrimary, fontSize: 13)), c),
                        const SizedBox(height: 20),
                        _buildMetaSection('Lokasi', Text(widget.ticket.location ?? '-', style: TextStyle(color: c.textSecondary, fontSize: 13)), c),
                        const Divider(height: 48),
                        
                        Text('Pelapor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c.textMuted, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        _buildUserTile(_requester, c),
                        const SizedBox(height: 24),
                        
                        Text('Teknisi Bertugas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c.textMuted, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        _buildUserTile(_technician, c, emptyText: 'Belum ditugaskan'),
                        
                        const Divider(height: 48),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Log Aktivitas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c.textPrimary)),
                            TextButton(onPressed: (){}, child: const Text('Lihat Semua', style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8)))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildActivityTimeline(c),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UI Components ─────────────────────────────────────────────────────────

  Widget _buildTopActions(AppColors c) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () {}, 
          icon: const Icon(Icons.assignment_ind_outlined, size: 16),
          label: const Text('Tetapkan Teknisi'),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.textPrimary,
            side: BorderSide(color: c.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {}, 
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Tandai Selesai'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSlaAlert(AppColors c) {
    if (widget.ticket.status == 'Closed' || widget.ticket.status == 'Resolved') return const SizedBox.shrink();
    
    // Logic for SLA Alert
    Color bannerColor = const Color(0xFF10B981);
    IconData bannerIcon = Icons.timer_outlined;
    String bannerTitle = "SLA Terkendali";
    String bannerText = "Tiket berjalan sesuai estimasi waktu penyelesaian.";

    if (widget.ticket.escalationLevel == 1) {
      bannerColor = const Color(0xFFF59E0B);
      bannerIcon = Icons.warning_amber_rounded;
      bannerTitle = "Peringatan SLA (Warning)";
      bannerText = "Waktu penyelesaian tersisa kurang dari 20%. Mohon segera direspon.";
    } else if (widget.ticket.escalationLevel >= 2) {
      bannerColor = const Color(0xFFEF4444);
      bannerIcon = Icons.error_outline_rounded;
      bannerTitle = "SLA BREACHED! (Telah Lewati Batas Waktu)";
      bannerText = "Tiket telah melewati target waktu penyelesaian dan akan segera dieskalasikan ke dekanat.";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        border: Border.all(color: bannerColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, color: bannerColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bannerTitle, style: TextStyle(fontWeight: FontWeight.bold, color: bannerColor, fontSize: 14)),
                const SizedBox(height: 2),
                Text(bannerText, style: TextStyle(color: bannerColor.withOpacity(0.9), fontSize: 12)),
              ],
            ),
          ),
          if (widget.ticket.targetResolutionAt != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Target Selesai:', style: TextStyle(fontSize: 11, color: bannerColor.withOpacity(0.8))),
                Text(DateFormat('dd MMM yyyy, HH:mm').format(widget.ticket.targetResolutionAt!), 
                     style: TextStyle(fontWeight: FontWeight.bold, color: bannerColor, fontSize: 13)),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.ticket.category, style: const TextStyle(fontSize: 13, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text(widget.ticket.description.split('\n').first, // Mocking title from description
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Text('Dibuat: ${DateFormat('dd MMMM yyyy, HH:mm').format(widget.ticket.createdAt)}', style: TextStyle(fontSize: 12, color: c.textSecondary)),
            const SizedBox(width: 24),
            Icon(Icons.update_rounded, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Text('Update terakhir: Hari ini', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ],
        )
      ],
    );
  }

  Widget _buildPublicDiscussionTab(AppColors c) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 48, color: c.border),
                const SizedBox(height: 12),
                Text('Mulai diskusi dengan pelapor', style: TextStyle(color: c.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Reply Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: c.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Balas Cepat:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  _buildCannedResponseDropdown(c),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _replyCtrl,
                maxLines: 3,
                style: TextStyle(fontSize: 13, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ketik balasan untuk pengguna...',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: c.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Color(0xFF1D4ED8))),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(onPressed: (){}, icon: const Icon(Icons.attach_file_rounded), color: c.textSecondary, tooltip: 'Lampirkan file'),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {}, 
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Kirim Balasan'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white, elevation: 0),
                  ),
                ],
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInternalNotesTab(AppColors c) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Catatan di tab ini bersifat rahasia dan HANYA bisa dilihat oleh tim Admin & Teknisi SBM.', style: TextStyle(fontSize: 12, color: const Color(0xFFF59E0B).withOpacity(0.9)))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              _buildInternalNoteCard("Mungkin ini masalah hardware pada proyektor. Saya sudah cek kabel HDMI tapi aman.", "Taufik (Teknisi)", "Hari ini, 10:23", c),
              const SizedBox(height: 12),
              _buildInternalNoteCard("Mohon segera diurus, ini untuk kelas MBA jam 1 siang.", "Admin SBM", "Hari ini, 10:45", c, isSelf: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _noteCtrl,
                style: TextStyle(fontSize: 13, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tambah catatan internal...',
                  hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                  filled: true, fillColor: c.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {}, 
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20), elevation: 0),
              child: const Text('Simpan'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildInternalNoteCard(String note, String author, String time, AppColors c, {bool isSelf = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelf ? const Color(0xFFFFFBEB) : c.surface,
        border: Border.all(color: isSelf ? const Color(0xFFFDE68A) : c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, backgroundColor: isSelf ? const Color(0xFFF59E0B) : c.border, child: Text(author[0], style: TextStyle(fontSize: 10, color: isSelf ? Colors.white : c.textSecondary, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              Text(author, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: c.textPrimary)),
              const Spacer(),
              Text(time, style: TextStyle(fontSize: 11, color: c.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          Text(note, style: TextStyle(fontSize: 13, color: c.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildCannedResponseDropdown(AppColors c) {
    return PopupMenuButton<String>(
      tooltip: 'Pilih templat balasan',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: c.background, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(6)),
        child: Row(
          children: [
            const Text('Pilih Templat...', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 16, color: c.textSecondary),
          ],
        ),
      ),
      onSelected: (val) {
        setState(() => _replyCtrl.text = val);
      },
      itemBuilder: (ctx) => _cannedResponses.map((r) => PopupMenuItem(
        value: r,
        child: Text(r, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
      )).toList(),
    );
  }

  Widget _buildMetaSection(String label, Widget content, AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
        const SizedBox(height: 6),
        content,
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final Map<String, Color> colors = {
      'New': const Color(0xFF6366F1), 'Assigned': const Color(0xFFF59E0B),
      'In Progress': const Color(0xFF3B82F6), 'Pending': const Color(0xFFEF4444),
      'Resolved': const Color(0xFF10B981), 'Closed': const Color(0xFF94A3B8),
    };
    final col = colors[status] ?? const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(0.3))),
      child: Text(status, style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final Map<String, List<dynamic>> map = {
      'Low': [const Color(0xFF10B981), Icons.arrow_downward_rounded],
      'Medium': [const Color(0xFFF59E0B), Icons.remove_rounded],
      'High': [const Color(0xFFEF4444), Icons.arrow_upward_rounded],
      'Urgent': [const Color(0xFF7C3AED), Icons.priority_high_rounded],
    };
    final data = map[priority] ?? [const Color(0xFF94A3B8), Icons.help_outline];
    final col = data[0] as Color;
    final icon = data[1] as IconData;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: col),
      const SizedBox(width: 6),
      Text(priority, style: TextStyle(fontSize: 13, color: col, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildUserTile(UserModel? user, AppColors c, {String emptyText = 'Data tidak ditemukan'}) {
    if (user == null) {
      return Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: c.background, child: Icon(Icons.person_outline, color: c.textMuted, size: 20)),
          const SizedBox(width: 12),
          Text(emptyText, style: TextStyle(color: c.textMuted, fontSize: 13, fontStyle: FontStyle.italic)),
        ],
      );
    }
    return Row(
      children: [
        CircleAvatar(radius: 18, backgroundColor: const Color(0xFF1D4ED8).withOpacity(0.15), child: Text(user.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${user.role.toUpperCase()} • ${user.email}', style: TextStyle(fontSize: 10, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTimeline(AppColors c) {
    // Dummy timeline data for visual representation of Audit Log feature
    final timeline = [
      {"action": "Tiket dibuat", "user": "Andi (Mahasiswa)", "time": "Hari ini, 09:00"},
      {"action": "Status berubah ke Assigned", "user": "System (Auto-Assign)", "time": "Hari ini, 09:05"},
      {"action": "Prioritas dinaikkan menjadi High", "user": "Admin SBM", "time": "Hari ini, 10:15"},
    ];

    return Column(
      children: timeline.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF1D4ED8), shape: BoxShape.circle, border: Border.all(color: c.surface, width: 2))),
                Container(width: 2, height: 40, color: c.border), // connector line
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item["action"]!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textPrimary)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(item["user"]!, style: TextStyle(fontSize: 11, color: c.textSecondary)),
                      const SizedBox(width: 6),
                      Text("•", style: TextStyle(fontSize: 10, color: c.textMuted)),
                      const SizedBox(width: 6),
                      Text(item["time"]!, style: TextStyle(fontSize: 10, color: c.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
