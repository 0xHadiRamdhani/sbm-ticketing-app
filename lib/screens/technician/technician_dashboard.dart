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
          // ── Search + Filter ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari ID Tiket, Lokasi, atau Pelapor...',
                    hintStyle: const TextStyle(
                        color: Color(0xFFADB5BD), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF9CA3AF), size: 20),
                    suffixIcon: const Icon(Icons.tune_rounded,
                        color: Color(0xFF9CA3AF), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF1A3A5C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF1A3A5C)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Ticket List ─────────────────────────────────────────────────
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
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1A73E8)));
                }
                if (snap.hasError) {
                  return const DashboardEmptyState(
                      icon: Icons.error_outline,
                      message: 'Terjadi kesalahan.');
                }

                var tickets = snap.data ?? [];
                
                // 1. Filter Status Chip
                if (_filterStatus != 'All') {
                  tickets = tickets.where((t) {
                    if (_filterStatus == 'Assigned') {
                      return t.status != 'Open';
                    } else if (_filterStatus == 'Completed') {
                      return t.status == 'Resolved';
                    } else {
                      return t.status == _filterStatus;
                    }
                  }).toList();
                }

                // 2. Filter Text Search
                if (_searchQuery.isNotEmpty) {
                  tickets = tickets.where((t) {
                    return t.ticketId.toLowerCase().contains(_searchQuery) ||
                        (t.location ?? '').toLowerCase().contains(_searchQuery) ||
                        t.category.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (tickets.isEmpty) {
                  return const DashboardEmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'Tidak ada tiket ditemukan.');
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: const Color(0xFF1A3A5C),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: tickets.length,
                    itemBuilder: (_, i) => TicketCard(ticket: tickets[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
