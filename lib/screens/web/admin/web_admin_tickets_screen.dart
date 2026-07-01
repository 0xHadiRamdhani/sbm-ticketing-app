import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/ticket_model.dart';
import '../../../providers/ticket_provider.dart';
import '../../../utils/app_colors.dart';
import 'web_admin_ticket_detail_screen.dart';

/// Web Admin Tickets Screen — Premium Desktop Table UI
class WebAdminTicketsScreen extends StatefulWidget {
  const WebAdminTicketsScreen({Key? key}) : super(key: key);

  @override
  State<WebAdminTicketsScreen> createState() => _WebAdminTicketsScreenState();
}

class _WebAdminTicketsScreenState extends State<WebAdminTicketsScreen> {
  String? _selectedStatus;
  String? _selectedPriority;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  Set<String> _selectedTickets = {};

  final _statuses = ['New', 'Assigned', 'In Progress', 'Pending', 'Resolved', 'Closed'];
  final _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: StreamBuilder<List<TicketModel>>(
        stream: Provider.of<TicketProvider>(context, listen: false).fetchTickets(role: 'admin'),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: const Color(0xFF3B82F6), strokeWidth: 2.5));
          }

          final allTickets = snap.data ?? [];
          final filtered = _filterTickets(allTickets);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(allTickets, c),
              _buildFilterRow(c),
              if (_selectedTickets.isNotEmpty) _buildBulkActionBar(c),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(c)
                    : _buildTable(filtered, c),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(List<TicketModel> allTickets, AppColors c) {
    final newCount = allTickets.where((t) => t.status == 'New').length;
    final inProgCount = allTickets.where((t) => t.status == 'In Progress').length;
    final resolvedCount = allTickets.where((t) => t.status == 'Resolved').length;

    return Container(
      padding: const EdgeInsets.fromLTRB(36, 28, 36, 24),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border.withOpacity(0.6))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Manajemen Tiket', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text('${allTickets.length} total tiket terdaftar', style: TextStyle(fontSize: 15, color: c.textSecondary)),
                ],
              ),
              const Spacer(),
              // Quick stat chips
              Wrap(
                spacing: 10,
                children: [
                  _TopStatChip(label: 'Baru', count: newCount, color: const Color(0xFF6366F1)),
                  _TopStatChip(label: 'Diproses', count: inProgCount, color: const Color(0xFFF59E0B)),
                  _TopStatChip(label: 'Resolved', count: resolvedCount, color: const Color(0xFF10B981)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(AppColors c) {
    final hasFilter = _selectedStatus != null || _selectedPriority != null || _searchQuery.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: c.border.withOpacity(0.5))),
      ),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: TextStyle(fontSize: 13, color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari tiket (ID, kategori, lokasi)...',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: c.textMuted, size: 19),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: Icon(Icons.close_rounded, size: 16, color: c.textMuted),
                        onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); })
                    : null,
                filled: true,
                fillColor: c.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status dropdown
          _FilterDropdown(
            label: 'Status',
            value: _selectedStatus,
            items: _statuses,
            onChanged: (v) => setState(() => _selectedStatus = v),
            icon: Icons.flag_outlined,
          ),
          const SizedBox(width: 10),

          // Priority dropdown
          _FilterDropdown(
            label: 'Prioritas',
            value: _selectedPriority,
            items: _priorities,
            onChanged: (v) => setState(() => _selectedPriority = v),
            icon: Icons.speed_outlined,
          ),
          const SizedBox(width: 10),

          // Clear filters
          if (hasFilter)
            TextButton.icon(
              onPressed: () => setState(() {
                _selectedStatus = null;
                _selectedPriority = null;
                _searchCtrl.clear();
                _searchQuery = '';
              }),
              icon: const Icon(Icons.filter_list_off_rounded, size: 16),
              label: const Text('Reset'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            ),

          const Spacer(),
          Text('${_filterTickets([]).length} hasil', style: TextStyle(fontSize: 12, color: c.textMuted)),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: c.textSecondary, size: 20),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(AppColors c) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_box_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text('${_selectedTickets.length} tiket dipilih', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const Spacer(),
          _BulkButton(icon: Icons.delete_outline_rounded, label: 'Hapus', color: Colors.white, bgColor: Colors.red.withOpacity(0.25), onTap: () {}),
          const SizedBox(width: 8),
          _BulkButton(icon: Icons.close_rounded, label: 'Batal', color: Colors.white, bgColor: Colors.white.withOpacity(0.15),
            onTap: () => setState(() => _selectedTickets.clear())),
        ],
      ),
    );
  }

  Widget _buildTable(List<TicketModel> tickets, AppColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(c.isDark ? 0.15 : 0.04), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: c.isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: c.divider)),
              ),
              child: Row(
                children: [
                  SizedBox(width: 44, child: Checkbox(
                    value: _selectedTickets.length == tickets.length && tickets.isNotEmpty,
                    onChanged: (v) => setState(() => v == true
                        ? _selectedTickets = tickets.map((t) => t.ticketId).toSet()
                        : _selectedTickets.clear()),
                    activeColor: const Color(0xFF3B82F6),
                  )),
                  _HeaderCell('ID Tiket', flex: 2),
                  _HeaderCell('Kategori & Deskripsi', flex: 4),
                  _HeaderCell('Lokasi', flex: 2),
                  _HeaderCell('Status', flex: 2),
                  _HeaderCell('Prioritas', flex: 2),
                  _HeaderCell('Tanggal', flex: 2),
                ],
              ),
            ),
            // Table rows
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              itemBuilder: (ctx, i) {
                final t = tickets[i];
                return _TicketTableRow(
                  ticket: t,
                  isSelected: _selectedTickets.contains(t.ticketId),
                  isLast: i == tickets.length - 1,
                  onToggle: (v) => setState(() => v == true
                      ? _selectedTickets.add(t.ticketId)
                      : _selectedTickets.remove(t.ticketId)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 20),
          Text('Tidak ada tiket ditemukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 8),
          Text('Coba ubah filter atau kata kunci pencarian', style: TextStyle(fontSize: 13, color: c.textSecondary)),
        ],
      ),
    );
  }

  List<TicketModel> _filterTickets(List<TicketModel> tickets) {
    // If called with empty list (for count), get from stream - not ideal but works for count display
    return tickets.where((t) {
      if (_selectedStatus != null && t.status != _selectedStatus) return false;
      if (_selectedPriority != null && t.priority != _selectedPriority) return false;
      if (_searchQuery.isNotEmpty) {
        return t.ticketId.toLowerCase().contains(_searchQuery) ||
            t.category.toLowerCase().contains(_searchQuery) ||
            (t.location ?? '').toLowerCase().contains(_searchQuery) ||
            t.description.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();
  }
}

// ─────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  const _HeaderCell(this.label, {required this.flex});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Expanded(
      flex: flex,
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.3)),
    );
  }
}

class _TicketTableRow extends StatefulWidget {
  final TicketModel ticket;
  final bool isSelected;
  final bool isLast;
  final ValueChanged<bool?> onToggle;
  const _TicketTableRow({required this.ticket, required this.isSelected, required this.isLast, required this.onToggle});
  @override
  State<_TicketTableRow> createState() => _TicketTableRowState();
}

class _TicketTableRowState extends State<_TicketTableRow> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = widget.ticket;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.06)
              : _hovered ? const Color(0xFF3B82F6).withOpacity(0.03) : Colors.transparent,
          border: Border(
            left: BorderSide(color: widget.isSelected ? const Color(0xFF3B82F6) : Colors.transparent, width: 4),
            bottom: widget.isLast ? BorderSide.none : BorderSide(color: c.divider.withOpacity(0.5)),
          ),
          borderRadius: widget.isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => WebAdminTicketDetailScreen(ticket: t)));
            },
            child: Row(
              children: [
                SizedBox(width: 44, child: Checkbox(value: widget.isSelected, onChanged: widget.onToggle, activeColor: const Color(0xFF3B82F6))),
                Expanded(flex: 2, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text('#${t.ticketId.substring(0, 8)}', style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
                )),
                Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(t.description, style: TextStyle(fontSize: 13, color: c.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Expanded(flex: 2, child: Text(t.location ?? '-', style: TextStyle(fontSize: 15, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: _StatusBadge(status: t.status)),
                Expanded(flex: 2, child: _PriorityBadge(priority: t.priority)),
                Expanded(flex: 2, child: Text(DateFormat('dd MMM yyyy').format(t.createdAt), style: TextStyle(fontSize: 14, color: c.textMuted))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colors = {
      'New': const Color(0xFF6366F1), 'Assigned': const Color(0xFFF59E0B),
      'In Progress': const Color(0xFF3B82F6), 'Pending': const Color(0xFFEF4444),
      'Resolved': const Color(0xFF10B981), 'Closed': const Color(0xFF94A3B8),
    };
    final col = colors[status] ?? const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withOpacity(0.3))),
      child: Text(status, style: TextStyle(fontSize: 13, color: col, fontWeight: FontWeight.w700)),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});
  @override
  Widget build(BuildContext context) {
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
      Icon(icon, size: 16, color: col),
      const SizedBox(width: 6),
      Text(priority, style: TextStyle(fontSize: 14, color: col, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;
  const _FilterDropdown({required this.label, required this.value, required this.items, required this.onChanged, required this.icon});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isActive = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3B82F6).withOpacity(0.08) : c.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? const Color(0xFF3B82F6).withOpacity(0.4) : c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: isActive ? const Color(0xFF3B82F6) : c.textMuted),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: value,
            hint: Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
            underline: const SizedBox(),
            isDense: true,
            style: TextStyle(fontSize: 13, color: isActive ? const Color(0xFF3B82F6) : c.textPrimary, fontWeight: FontWeight.w500),
            dropdownColor: c.surface,
            items: [
              DropdownMenuItem(value: null, child: Text('Semua $label', style: TextStyle(color: c.textSecondary))),
              ...items.map((item) => DropdownMenuItem(value: item, child: Text(item))),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TopStatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _TopStatChip({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
        Text('$count', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _BulkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _BulkButton({required this.icon, required this.label, required this.color, required this.bgColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
