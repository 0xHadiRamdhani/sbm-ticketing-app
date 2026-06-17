import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/premium_route.dart';
import '../settings_screen.dart';
import '../shared/ticket_card.dart';
import '../shared/impersonation_banner.dart';
import 'technician_my_reports_screen.dart';

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

  final _filters = ['All', 'New', 'Assigned', 'In Progress', 'Pending', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNotifListener();
      Provider.of<TicketProvider>(context, listen: false).checkAndEscalateTickets();
    });
  }

  void _startNotifListener() {
    final tp = Provider.of<TicketProvider>(context, listen: false);
    final uid = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    _notifSub = tp.fetchTickets(role: 'technician', uid: uid, status: 'New').listen(
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
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        onSettingsTap: () => Navigator.push(
          context,
          PremiumPageRoute(child: SettingsScreen()),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          PremiumPageRoute(child: TechnicianMyReportsScreen()),
        ),
        backgroundColor: const Color(0xFF1A3A5C),
        icon: const Icon(Icons.history_edu, color: Colors.white),
        label: Text(lang.translate('Laporan Teknisi', 'My Reports'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          const ImpersonationBanner(),
          Expanded(
            child: StreamBuilder<List<TicketModel>>(
              stream: Provider.of<TicketProvider>(context, listen: false)
                  .fetchTickets(role: 'technician', uid: user?.uid, status: _firestoreStatus()),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: c.primary));
                }
                if (snap.hasError) {
                  return DashboardEmptyState(icon: Icons.error_outline, message: lang.translate('Terjadi kesalahan.', 'An error occurred.'));
                }

                final allTickets = snap.data ?? [];
                final assignedCount  = allTickets.where((t) => t.status == 'Assigned' || t.status == 'New').length;
                final inProgressCount = allTickets.where((t) => t.status == 'In Progress' || t.status == 'Pending').length;
                final completedCount  = allTickets.where((t) => t.status == 'Resolved' || t.status == 'Closed').length;

                var displayedTickets = allTickets;
                if (_filterStatus != 'All') {
                  displayedTickets = displayedTickets.where((t) {
                    return t.status == _filterStatus;
                  }).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  displayedTickets = displayedTickets.where((t) {
                    return t.ticketId.toLowerCase().contains(_searchQuery) ||
                        (t.location ?? '').toLowerCase().contains(_searchQuery) ||
                        t.category.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                return Column(
                  children: [
                    // ── Header Stats ───────────────────────────────────────
                    Container(
                      color: c.surface,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.translate('Ringkasan Tugas', 'Task Summary'),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard(context, lang.translate('Ditugaskan', 'Assigned'), assignedCount, const Color(0xFF3B82F6), Icons.assignment_ind_rounded, 0)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard(context, lang.translate('Diproses', 'In Progress'), inProgressCount, const Color(0xFFF59E0B), Icons.autorenew_rounded, 1)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard(context, lang.translate('Selesai', 'Completed'), completedCount, const Color(0xFF10B981), Icons.check_circle_rounded, 2)),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // ── Search + Filter ────────────────────────────────────
                    Container(
                      color: c.surface,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            onSubmitted: (v) => setState(() => _searchQuery = v.toLowerCase()),
                            textInputAction: TextInputAction.search,
                            style: TextStyle(color: c.textPrimary),
                            decoration: InputDecoration(
                              hintText: lang.translate('Cari ID Tiket, Lokasi, atau Pelapor...', 'Search Ticket ID, Location, or Requester...'),
                              hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                              prefixIcon: Icon(Icons.search_rounded, color: c.textMuted, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(Icons.close_rounded, size: 18, color: c.textMuted),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : Icon(Icons.tune_rounded, color: c.textMuted, size: 20),
                              filled: true,
                              fillColor: c.searchBar,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.primary, width: 1.5),
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
                                      color: sel ? c.chipSelected : c.chipUnselected,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: sel ? c.chipSelected : c.chipBorder),
                                    ),
                                    child: Text(
                                      opt,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: sel ? Colors.white : c.textSecondary,
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

                    // ── Ticket List ────────────────────────────────────────
                    Expanded(
                      child: displayedTickets.isEmpty
                          ? DashboardEmptyState(icon: Icons.inbox_outlined, message: lang.translate('Tidak ada tiket ditemukan.', 'No tickets found.'))
                          : RefreshIndicator(
                              onRefresh: () async {
                                setState(() {});
                                await Future.delayed(const Duration(milliseconds: 500));
                              },
                              color: c.primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: displayedTickets.length,
                                itemBuilder: (_, i) {
                                  final ticket = displayedTickets[i];
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey(ticket.ticketId),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(milliseconds: 300 + (i * 60).clamp(0, 300)),
                                    curve: Curves.easeOutQuad,
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: Opacity(
                                          opacity: value,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: TicketCard(ticket: ticket),
                                  );
                                },
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

  Widget _buildStatCard(BuildContext context, String title, int count, Color color, IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Text(
                    count.toString(),
                    key: ValueKey<int>(count),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}
