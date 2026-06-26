import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import 'admin_stats_screen.dart';
import 'audit_log_screen.dart';
import 'active_devices_screen.dart';
import 'export_reports_screen.dart';
import 'import_tickets_screen.dart';
import 'user_management_screen.dart';
import '../../services/audit_service.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import '../shared/ticket_card.dart';
import '../shared/ios_glass_dropdown.dart';
import '../../utils/app_notifications.dart';

class AdminTicketsScreen extends StatefulWidget {
  @override
  _AdminTicketsScreenState createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  String? _selectedCategory;
  String? _selectedPriority;
  String? _selectedStatus; // null means 'All'
  String? _selectedMonth; // null means 'Semua Bulan'
  int? _selectedDay; // null means 'Semua Tanggal'
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedTicketIds = {};
  bool _isSelectionMode = false;
  bool _isAnalyticsExpanded = true;

  final List<String> _months = [
    'Semua Bulan',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  List<String> get _days {
    final list = <String>['Semua Tanggal'];
    for (int d = 1; d <= 31; d++) {
      list.add(d.toString());
    }
    return list;
  }

  final _filters = [
    'Semua',
    'New',
    'Assigned',
    'In Progress',
    'Pending',
    'Resolved',
    'Closed',
    'Re-opened',
  ];

  final List<String> _categories = [
    'Semua Kategori',
    'Hardware',
    'Software',
    'Jaringan',
    'Fasilitas',
    'Lainnya',
  ];
  final List<String> _priorities = [
    'Semua Prioritas',
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(
        context,
        listen: false,
      ).checkAndEscalateTickets();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search + Filter ─────────────────────────────────────────────
        Container(
          color: AppColors.of(context).surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onSubmitted: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari ID Tiket, Kategori, atau Pelapor...',
                  hintStyle: TextStyle(
                    color: AppColors.of(context).textMuted,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.of(context).textMuted,
                    size: 20,
                  ),
                  suffixIcon: Icon(
                    Icons.tune_rounded,
                    color: AppColors.of(context).textMuted,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: AppColors.of(context).background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(color: AppColors.of(context).textPrimary),
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
                    final sel = (_selectedStatus ?? 'Semua') == opt;
                    return GestureDetector(
                      onTap: () => setState(
                        () => _selectedStatus = opt == 'Semua' ? null : opt,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.of(context).primary
                              : AppColors.of(context).surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? AppColors.of(context).primary
                                : AppColors.of(context).border,
                          ),
                        ),
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? Colors.white
                                : AppColors.of(context).textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: IosGlassDropdown<String>(
                      value: _selectedCategory ?? 'Semua Kategori',
                      items: _categories,
                      itemLabelBuilder: (c) => c,
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val == 'Semua Kategori'
                              ? null
                              : val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IosGlassDropdown<String>(
                      value: _selectedPriority ?? 'Semua Prioritas',
                      items: _priorities,
                      itemLabelBuilder: (p) => p,
                      onChanged: (val) {
                        setState(() {
                          _selectedPriority = val == 'Semua Prioritas'
                              ? null
                              : val;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: IosGlassDropdown<String>(
                      value: _selectedMonth ?? 'Semua Bulan',
                      items: _months,
                      itemLabelBuilder: (m) => m,
                      onChanged: (val) {
                        setState(() {
                          _selectedMonth = val == 'Semua Bulan' ? null : val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: IosGlassDropdown<String>(
                      value: _selectedDay != null
                          ? _selectedDay.toString()
                          : 'Semua Tanggal',
                      items: _days,
                      itemLabelBuilder: (d) => d,
                      onChanged: (val) {
                        setState(() {
                          _selectedDay = val == 'Semua Tanggal'
                              ? null
                              : int.tryParse(val);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickAction(
                  context,
                  icon: Icons.history_rounded,
                  label: 'Audit Log',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuditLogScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  context,
                  icon: Icons.people_outline_rounded,
                  label: 'User Management',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserManagementScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                // _buildQuickAction(
                //   context,
                //   icon: Icons.edit_notifications_outlined,
                //   label: 'Templat',
                //   onTap: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => const NotificationTemplatesScreen(),
                //     ),
                //   ),
                // ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  context,
                  icon: Icons.file_download_outlined,
                  label: 'Ekspor',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExportReportsScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  context,
                  icon: Icons.file_upload_outlined,
                  label: 'Import',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ImportTicketsScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  context,
                  icon: Icons.devices_rounded,
                  label: 'Perangkat',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActiveDevicesScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  context,
                  icon: Icons.bar_chart_rounded,
                  label: 'Statistik',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminStatsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Stream Data ────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<TicketModel>>(
            stream: Provider.of<TicketProvider>(
              context,
              listen: false,
            ).fetchTickets(role: 'admin'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.of(context).primary,
                  ),
                );
              }
              if (snapshot.hasError) {
                return const DashboardEmptyState(
                  icon: Icons.error_outline,
                  message: 'Terjadi kesalahan sistem.',
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const DashboardEmptyState(
                  icon: Icons.inbox_outlined,
                  message: 'Tidak ada data tiket.',
                );
              }

              final allTickets = snapshot.data!;

              // Apply Filters
              final filteredTickets = allTickets.where((t) {
                bool matchCategory =
                    _selectedCategory == null ||
                    t.category == _selectedCategory;
                bool matchPriority =
                    _selectedPriority == null ||
                    t.priority == _selectedPriority;
                bool matchStatus =
                    _selectedStatus == null || t.status == _selectedStatus;
                bool matchMonth =
                    _selectedMonth == null ||
                    t.createdAt.month == _months.indexOf(_selectedMonth!);
                bool matchDay =
                    _selectedDay == null ||
                    t.createdAt.day == _selectedDay;
                bool matchSearch =
                    _searchQuery.isEmpty ||
                    t.ticketId.toLowerCase().contains(_searchQuery) ||
                    (t.location ?? '').toLowerCase().contains(_searchQuery) ||
                    t.category.toLowerCase().contains(_searchQuery) ||
                    (t.description).toLowerCase().contains(_searchQuery);
                return matchCategory &&
                    matchPriority &&
                    matchStatus &&
                    matchMonth &&
                    matchDay &&
                    matchSearch;
              }).toList();

              // Stats
              int total = filteredTickets.length;
              int open = filteredTickets
                  .where((t) => t.status == 'New' || t.status == 'Re-opened')
                  .length;
              int inProgress = filteredTickets
                  .where(
                    (t) => t.status == 'In Progress' || t.status == 'Assigned',
                  )
                  .length;
              int resolved = filteredTickets
                  .where((t) => t.status == 'Resolved' || t.status == 'Closed')
                  .length;

              return Column(
                children: [
                  // ── Statistics Cards ────────────────────────────────────────
                  Container(
                    color: AppColors.of(context).surface,
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard(
                            'Total',
                            total,
                            AppColors.of(context).isDark
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF0F172A),
                            AppColors.of(context).isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                          ),
                          _buildStatCard(
                            'Open',
                            open,
                            AppColors.of(context).isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                            AppColors.of(context).isDark
                                ? const Color(0xFF450A0A)
                                : const Color(0xFFFEF2F2),
                          ),
                          _buildStatCard(
                            'In Progress',
                            inProgress,
                            AppColors.of(context).isDark
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFD97706),
                            AppColors.of(context).isDark
                                ? const Color(0xFF451A03)
                                : const Color(0xFFFFFBEB),
                          ),
                          _buildStatCard(
                            'Resolved',
                            resolved,
                            AppColors.of(context).isDark
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF16A34A),
                            AppColors.of(context).isDark
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFF0FDF4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // _buildAnalyticsChart(allTickets),
                  _buildBulkActionBar(),
                  // ── Ticket List ─────────────────────────────────────────────
                  Expanded(
                    child: Container(
                      color: AppColors.of(context).background,
                      child: filteredTickets.isEmpty
                          ? const DashboardEmptyState(
                              icon: Icons.search_off_rounded,
                              message: 'Tidak ada tiket yang sesuai filter.',
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                setState(() {});
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                              },
                              color: AppColors.of(context).primary,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: filteredTickets.length,
                                itemBuilder: (context, index) {
                                  final ticket = filteredTickets[index];
                                  final isSelected = _selectedTicketIds
                                      .contains(ticket.ticketId);

                                  return GestureDetector(
                                    onLongPress: () {
                                      setState(() {
                                        _isSelectionMode = true;
                                        _selectedTicketIds.add(ticket.ticketId);
                                      });
                                    },
                                    child: TicketCard(
                                      ticket: ticket,
                                      isSelectionMode: _isSelectionMode,
                                      isSelected: isSelected,
                                      onSelect: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedTicketIds.add(
                                              ticket.ticketId,
                                            );
                                          } else {
                                            _selectedTicketIds.remove(
                                              ticket.ticketId,
                                            );
                                            if (_selectedTicketIds.isEmpty)
                                              _isSelectionMode = false;
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(c.isDark ? 0.1 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: c.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: c.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    if (!_isSelectionMode) return const SizedBox();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.of(context).primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() {
              _isSelectionMode = false;
              _selectedTicketIds.clear();
            }),
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          Text(
            '${_selectedTicketIds.length} Tiket Terpilih',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildBulkActionIcon(
            Icons.check_circle_outline,
            'Selesaikan',
            () => _handleBulkStatus('Resolved'),
          ),
          _buildBulkActionIcon(
            Icons.delete_outline,
            'Hapus',
            _handleBulkDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionIcon(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 22),
      tooltip: tooltip,
    );
  }

  Future<void> _handleBulkStatus(String status) async {
    final provider = context.read<TicketProvider>();
    for (String id in _selectedTicketIds) {
      await provider.updateTicketStatus(id, status);
      await AuditService().logAction(
        actionType: 'BULK_UPDATE_STATUS',
        targetId: id,
        description: 'Mengubah status tiket secara massal menjadi $status',
      );
    }
    final count = _selectedTicketIds.length;
    setState(() {
      _isSelectionMode = false;
      _selectedTicketIds.clear();
    });
    AppNotifications.showNotification(
      context,
      title: 'Sukses',
      message: '$count tiket berhasil diupdate.',
      isError: false,
    );
  }

  Future<void> _handleBulkDelete() async {
    final confirm = await AppNotifications.showConfirmDialog(
      context,
      title: 'Hapus Massal',
      message:
          'Hapus ${_selectedTicketIds.length} tiket yang dipilih secara permanen?',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
    );

    if (confirm == true) {
      final provider = context.read<TicketProvider>();
      int count = _selectedTicketIds.length;
      for (String id in _selectedTicketIds) {
        await provider.deleteTicket(id);
        await AuditService().logAction(
          actionType: 'BULK_DELETE_TICKET',
          targetId: id,
          description: 'Menghapus tiket secara massal',
        );
      }
      AppNotifications.showNotification(
        context,
        title: 'Sukses',
        message: '$count tiket berhasil dihapus.',
        isError: false,
      );
    }
  }

  Widget _buildStatCard(String title, int count, Color fgColor, Color bgColor) {
    final isDark = AppColors.of(context).isDark;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        // Gradient for premium look in dark mode, solid color in light mode
        gradient: isDark
            ? LinearGradient(
                colors: [bgColor.withOpacity(0.9), bgColor.withOpacity(0.6)],
              )
            : null,
        color: isDark ? null : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsChart(List<TicketModel> tickets) {
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    final List<String> monthLabels = [];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);

      final masuk = tickets
          .where(
            (t) =>
                t.createdAt.month == date.month &&
                t.createdAt.year == date.year,
          )
          .length;

      final selesai = tickets.where((t) {
        if (t.status != 'Resolved') return false;
        final d = t.resolvedAt ?? t.createdAt;
        return d.month == date.month && d.year == date.year;
      }).length;

      barGroups.add(
        BarChartGroupData(
          x: 5 - i,
          barRods: [
            BarChartRodData(
              toY: masuk.toDouble(),
              color: AppColors.of(context).primary,
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: selesai.toDouble(),
              color: Colors.green,
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      monthLabels.add(months[date.month - 1]);
    }

    double maxY = 10;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxY) maxY = rod.toY;
      }
    }
    maxY += 5;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tiket Masuk vs Selesai (6 Bulan)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isAnalyticsExpanded) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.of(context).primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(
                  () => _isAnalyticsExpanded = !_isAnalyticsExpanded,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedRotation(
                    turns: _isAnalyticsExpanded ? 0 : -0.5,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 18,
                      color: AppColors.of(context).primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 350),
            firstCurve: Curves.easeOutCubic,
            secondCurve: Curves.easeOutCubic,
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: _isAnalyticsExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, _) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthLabels[value.toInt()],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.of(context).textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}
