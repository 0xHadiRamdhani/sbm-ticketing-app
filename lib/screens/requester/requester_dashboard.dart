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
import 'create_ticket_screen.dart';

class RequesterDashboard extends StatefulWidget {
  @override
  State<RequesterDashboard> createState() => _RequesterDashboardState();
}

class _RequesterDashboardState extends State<RequesterDashboard> {
  String _filterStatus = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  StreamSubscription<List<TicketModel>>? _notifSub;
  bool _isFirstLoad = true;
  Map<String, TicketModel> _knownTickets = {};

  final _filters = ['All', 'Open', 'In Progress', 'Resolved'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startNotifListener());
  }

  void _startNotifListener() {
    final tp = Provider.of<TicketProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    _notifSub = tp.fetchTickets(role: 'requester', uid: uid).listen(
      (tickets) {
        if (_isFirstLoad) {
          _knownTickets = {for (var t in tickets) t.ticketId: t};
          _isFirstLoad = false;
          return;
        }
        for (var t in tickets) {
          final oldT = _knownTickets[t.ticketId];
          if (oldT != null) {
            // 1. Status Change Notification
            if (oldT.status != t.status) {
              String statusIndo = _statusLabelIndo(t.status);
              NotificationService().showNotification(
                id: t.ticketId.hashCode,
                title: 'Pembaruan Status Tiket',
                body: 'Tiket ${t.category} Anda sekarang berstatus "$statusIndo".',
              );
            } 
            // 2. Technician Assigned Notification
            else if (oldT.technicianId == null && t.technicianId != null) {
              NotificationService().showNotification(
                id: t.ticketId.hashCode + 1,
                title: 'Teknisi Ditugaskan',
                body: 'Seorang teknisi telah ditugaskan untuk menangani tiket ${t.category} Anda.',
              );
            }
            // 3. New Note Notification
            else if (oldT.note != t.note && t.note != null && t.note!.isNotEmpty) {
              NotificationService().showNotification(
                id: t.ticketId.hashCode + 2,
                title: 'Catatan Teknisi Baru',
                body: 'Teknisi menambahkan catatan: "${t.note}"',
              );
            }
          }
          _knownTickets[t.ticketId] = t;
        }
      },
    );
  }

  String _statusLabelIndo(String status) {
    switch (status) {
      case 'Open': return 'Diajukan';
      case 'In Progress': return 'Diproses';
      case 'Resolved': return 'Selesai';
      case 'Pending': return 'Ditunda';
      default: return status;
    }
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateTicketScreen()),
        ),
        backgroundColor: const Color(0xFF1A3A5C),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Buat Tiket',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
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
                    hintText:
                        'Cari tiket berdasarkan kategori atau lokasi...',
                    hintStyle: const TextStyle(
                        color: Color(0xFFADB5BD), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
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
                    role: user?.role,
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
                      message: 'Terjadi kesalahan sistem.');
                }

                var tickets = snap.data ?? [];
                
                // 1. Filter Status Chip
                if (_filterStatus != 'All') {
                  tickets = tickets.where((t) => t.status == _filterStatus).toList();
                }

                // 2. Filter Text Search
                if (_searchQuery.isNotEmpty) {
                  tickets = tickets.where((t) {
                    return t.category
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        (t.location ?? '')
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        t.description.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (tickets.isEmpty) {
                  return const DashboardEmptyState(
                      icon: Icons.inbox_outlined,
                      message: 'Belum ada tiket yang diajukan.');
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Force a rebuild to refresh data
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
