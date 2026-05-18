import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/notification_service.dart';
import '../settings_screen.dart';
import '../shared/ticket_card.dart';
import '../shared/impersonation_banner.dart';

class TechnicianDashboard extends StatefulWidget {
  @override
  _TechnicianDashboardState createState() => _TechnicianDashboardState();
}

class _TechnicianDashboardState extends State<TechnicianDashboard> {
  String _filterStatus = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  StreamSubscription<List<TicketModel>>? _notifSub;
  bool _isFirstLoad = true;
  Set<String> _knownTickets = {};

  final _filters = ['All', 'Assigned', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startNotifListener());
  }

  void _startNotifListener() {
    final tp = Provider.of<TicketProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    _notifSub =
        tp.fetchTickets(role: 'technician', uid: uid, status: 'Open').listen(
          (tickets) {
            if (_isFirstLoad) {
              _knownTickets = tickets.map((t) => t.ticketId).toSet();
              _isFirstLoad = false;
              return;
            }
            for (var t in tickets) {
              if (!_knownTickets.contains(t.ticketId)) {
                _knownTickets.add(t.ticketId);
                NotificationService().showNotification(
                  id: t.ticketId.hashCode,
                  title: 'Tiket Baru Masuk!',
                  body: '${t.category} - ${t.location ?? "Tanpa Lokasi"}',
                );
              }
            }
          },
        );
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String? _firestoreStatus() => null;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: buildSbmAppBar(
        onSettingsTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsScreen()),
        ),
      ),
      body: Column(
        children: [
          const ImpersonationBanner(),
          Expanded(
            child: StreamBuilder<List<TicketModel>>(
              stream: Provider.of<TicketProvider>(context, listen: false)
                  .fetchTickets(
                    role: 'technician',
                    uid: user?.uid,
                    status: _firestoreStatus(),
                  ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1A73E8)));
                }
                if (snap.hasError) {
                  return const DashboardEmptyState(icon: Icons.error_outline, message: 'Terjadi kesalahan.');
                }

                final allTickets = snap.data ?? [];
                
                // Calculate Stats
                final assignedCount = allTickets.where((t) => t.status != 'Open' && t.status != 'Resolved').length;
                final inProgressCount = allTickets.where((t) => t.status == 'In Progress').length;
                final completedCount = allTickets.where((t) => t.status == 'Resolved').length;

                // 1. Filter Status Chip
                var displayedTickets = allTickets;
                if (_filterStatus != 'All') {
                  displayedTickets = displayedTickets.where((t) {
                    if (_filterStatus == 'Assigned') {
                      return t.status != 'Open' && t.status != 'Resolved';
                    } else if (_filterStatus == 'Completed') {
                      return t.status == 'Resolved';
                    } else {
                      return t.status == _filterStatus;
                    }
                  }).toList();
                }

                // 2. Filter Text Search
                if (_searchQuery.isNotEmpty) {
                  displayedTickets = displayedTickets.where((t) {
                    return t.ticketId.toLowerCase().contains(_searchQuery) ||
                        (t.location ?? '').toLowerCase().contains(_searchQuery) ||
                        t.category.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                return Column(
                  children: [
                    // ── Header Stats ─────────────────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Tugas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard('Ditugaskan', assignedCount, const Color(0xFF3B82F6), Icons.assignment_ind_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Diproses', inProgressCount, const Color(0xFFF59E0B), Icons.autorenew_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard('Selesai', completedCount, const Color(0xFF10B981), Icons.check_circle_rounded)),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // ── Search + Filter ─────────────────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: 'Cari ID Tiket, Lokasi, atau Pelapor...',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : const Icon(Icons.tune_rounded, color: Color(0xFF64748B), size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1A3A5C), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 36,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filters.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final opt = _filters[i];
                                final sel = _filterStatus == opt;
                                return GestureDetector(
                                  onTap: () => setState(() => _filterStatus = opt),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel ? const Color(0xFF1A3A5C) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: sel ? const Color(0xFF1A3A5C) : Colors.transparent,
                                      ),
                                    ),
                                    child: Text(
                                      opt,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: sel ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Ticket List ─────────────────────────────────────────────────
                    Expanded(
                      child: displayedTickets.isEmpty
                          ? const DashboardEmptyState(
                              icon: Icons.inbox_outlined,
                              message: 'Tidak ada tiket ditemukan.')
                          : RefreshIndicator(
                              onRefresh: () async {
                                setState(() {});
                                await Future.delayed(const Duration(milliseconds: 500));
                              },
                              color: const Color(0xFF1A3A5C),
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                itemCount: displayedTickets.length,
                                itemBuilder: (_, i) => TicketCard(ticket: displayedTickets[i]),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
