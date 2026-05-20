import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../providers/language_provider.dart';
import 'admin_stats_screen.dart';
import 'audit_log_screen.dart';
import 'notification_templates_screen.dart';
import 'active_devices_screen.dart';
import 'export_reports_screen.dart';
import 'user_management_screen.dart';
import '../../services/audit_service.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import '../shared/ticket_card.dart';

class AdminTicketsScreen extends StatefulWidget {
  @override
  _AdminTicketsScreenState createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  String? _selectedCategory;
  String? _selectedPriority;
  String? _selectedStatus; // null means 'All'
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  final Set<String> _selectedTicketIds = {};
  bool _isSelectionMode = false;

  final _filters = ['Semua', 'Open', 'In Progress', 'Resolved', 'Pending'];

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
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.of(context).background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.of(context).border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: AppColors.of(context).surface,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.of(context).textMuted,
                            size: 20,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.of(context).textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          value: _selectedCategory ?? 'Semua Kategori',
                          items: _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategory = val == 'Semua Kategori'
                                  ? null
                                  : val;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.of(context).background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.of(context).border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          dropdownColor: AppColors.of(context).surface,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.of(context).textMuted,
                            size: 20,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.of(context).textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          value: _selectedPriority ?? 'Semua Prioritas',
                          items: _priorities
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedPriority = val == 'Semua Prioritas'
                                  ? null
                                  : val;
                            });
                          },
                        ),
                      ),
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
                _buildQuickAction(
                  context,
                  icon: Icons.edit_notifications_outlined,
                  label: 'Templat',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationTemplatesScreen(),
                    ),
                  ),
                ),
                // const SizedBox(width: 12),
                // _buildQuickAction(
                //   context,
                //   icon: Icons.file_download_outlined,
                //   label: 'Ekspor',
                //   onTap: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => const ExportReportsScreen(),
                //     ),
                //   ),
                // ),
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
                bool matchSearch =
                    _searchQuery.isEmpty ||
                    t.ticketId.toLowerCase().contains(_searchQuery) ||
                    (t.location ?? '').toLowerCase().contains(_searchQuery) ||
                    t.category.toLowerCase().contains(_searchQuery) ||
                    (t.description).toLowerCase().contains(_searchQuery);
                return matchCategory &&
                    matchPriority &&
                    matchStatus &&
                    matchSearch;
              }).toList();

              // Stats
              int total = filteredTickets.length;
              int open = filteredTickets
                  .where((t) => t.status == 'Open')
                  .length;
              int inProgress = filteredTickets
                  .where((t) => t.status == 'In Progress')
                  .length;
              int resolved = filteredTickets
                  .where((t) => t.status == 'Resolved')
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
                            AppColors.of(context).isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
                            AppColors.of(context).isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          ),
                          _buildStatCard(
                            'Open',
                            open,
                            AppColors.of(context).isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                            AppColors.of(context).isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                          ),
                          _buildStatCard(
                            'In Progress',
                            inProgress,
                            AppColors.of(context).isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                            AppColors.of(context).isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
                          ),
                          _buildStatCard(
                            'Resolved',
                            resolved,
                            AppColors.of(context).isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                            AppColors.of(context).isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                                padding: const EdgeInsets.all(16),
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
    setState(() {
      _isSelectionMode = false;
      _selectedTicketIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedTicketIds.length} tiket berhasil diupdate.'),
      ),
    );
  }

  Future<void> _handleBulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Massal'),
        content: Text(
          'Hapus ${_selectedTicketIds.length} tiket yang dipilih secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
      setState(() {
        _isSelectionMode = false;
        _selectedTicketIds.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$count tiket berhasil dihapus.')));
    }
  }

  Widget _buildStatCard(String title, int count, Color fgColor, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withValues(alpha: 0.1)),
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
}
