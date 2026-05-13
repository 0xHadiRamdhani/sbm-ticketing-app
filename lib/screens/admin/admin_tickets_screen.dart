import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_stats_screen.dart';
import 'audit_log_screen.dart';
import 'notification_templates_screen.dart';
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
  final Set<String> _selectedTicketIds = {};
  bool _isSelectionMode = false;

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
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Filter Section ───────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                      value: _selectedCategory ?? 'Semua Kategori',
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
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
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                      value: _selectedPriority ?? 'Semua Prioritas',
                      items: _priorities
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
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
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1A3A5C)),
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
                return matchCategory && matchPriority && matchStatus;
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
                    color: Colors.white,
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
                            const Color(0xFF0F172A),
                            const Color(0xFFF1F5F9),
                          ),
                          _buildStatCard(
                            'Open',
                            open,
                            const Color(0xFFDC2626),
                            const Color(0xFFFEF2F2),
                          ),
                          _buildStatCard(
                            'In Progress',
                            inProgress,
                            const Color(0xFFD97706),
                            const Color(0xFFFFFBEB),
                          ),
                          _buildStatCard(
                            'Resolved',
                            resolved,
                            const Color(0xFF16A34A),
                            const Color(0xFFF0FDF4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Status Filter Chips ──────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Semua', null),
                          const SizedBox(width: 8),
                          _buildFilterChip('Open', 'Open'),
                          const SizedBox(width: 8),
                          _buildFilterChip('In Progress', 'In Progress'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Resolved', 'Resolved'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Pending', 'Pending'),
                        ],
                      ),
                    ),
                  ),
                  _buildBulkActionBar(),
                  // ── Ticket List ─────────────────────────────────────────────
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF8FAFC),
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
                              color: const Color(0xFF1A3A5C),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1A3A5C)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
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
        color: const Color(0xFF1A3A5C),
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

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = status;
        });
      },
      checkmarkColor: Colors.white,
      selectedColor: const Color(0xFF1A3A5C),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1A3A5C) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color fgColor, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor.withOpacity(0.8),
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
