import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/ticket_model.dart';
import '../../../providers/ticket_provider.dart';
import '../../../utils/app_colors.dart';
import '../../shared/ticket_card.dart';

/// Web Admin Tickets Screen - Full ticket management with filters
class WebAdminTicketsScreen extends StatefulWidget {
  const WebAdminTicketsScreen({Key? key}) : super(key: key);

  @override
  State<WebAdminTicketsScreen> createState() => _WebAdminTicketsScreenState();
}

class _WebAdminTicketsScreenState extends State<WebAdminTicketsScreen> {
  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedCategory;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final _statuses = ['New', 'Assigned', 'In Progress', 'Pending', 'Resolved', 'Closed'];
  final _priorities = ['Low', 'Medium', 'High'];
  final _categories = ['IT', 'Fasilitas', 'Akademik', 'Lainnya'];

  Set<String> _selectedTickets = {};
  bool _selectAll = false;

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
        stream: Provider.of<TicketProvider>(context, listen: false)
            .fetchTickets(role: 'admin'),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTickets = snap.data ?? [];
          final filteredTickets = _filterTickets(allTickets);

          return Column(
            children: [
              _buildFilterBar(c),
              _buildStatsBar(allTickets, c),
              if (_selectedTickets.isNotEmpty) _buildBulkActions(c),
              Expanded(
                child: filteredTickets.isEmpty
                    ? _buildEmptyState(c)
                    : _buildTicketsList(filteredTickets, c),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  style: TextStyle(fontSize: 14, color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari tiket (ID, kategori, lokasi)...',
                    hintStyle: TextStyle(color: c.textMuted),
                    prefixIcon: Icon(Icons.search, color: c.textMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, size: 18, color: c.textMuted),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: c.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Refresh button
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: c.textPrimary),
                onPressed: () => setState(() {}),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filter
                _FilterDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  items: _statuses,
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(width: 12),

                // Priority filter
                _FilterDropdown(
                  label: 'Prioritas',
                  value: _selectedPriority,
                  items: _priorities,
                  onChanged: (v) => setState(() => _selectedPriority = v),
                ),
                const SizedBox(width: 12),

                // Category filter
                _FilterDropdown(
                  label: 'Kategori',
                  value: _selectedCategory,
                  items: _categories,
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(width: 12),

                // Clear filters
                if (_selectedStatus != null ||
                    _selectedPriority != null ||
                    _selectedCategory != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedPriority = null;
                        _selectedCategory = null;
                      });
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(List<TicketModel> tickets, AppColors c) {
    final newCount = tickets.where((t) => t.status == 'New').length;
    final inProgressCount = tickets.where((t) => t.status == 'In Progress').length;
    final resolvedCount = tickets.where((t) => t.status == 'Resolved').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1A2332) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          _StatChip(label: 'Total', count: tickets.length, color: c.primary),
          const SizedBox(width: 12),
          _StatChip(label: 'Baru', count: newCount, color: const Color(0xFF2196F3)),
          const SizedBox(width: 12),
          _StatChip(label: 'Diproses', count: inProgressCount, color: const Color(0xFFFFA726)),
          const SizedBox(width: 12),
          _StatChip(label: 'Resolved', count: resolvedCount, color: const Color(0xFF66BB6A)),
        ],
      ),
    );
  }

  Widget _buildBulkActions(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: c.primary.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Text(
            '${_selectedTickets.length} tiket dipilih',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _bulkAssign(),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Assign'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _bulkDelete(),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() {
              _selectedTickets.clear();
              _selectAll = false;
            }),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList(List<TicketModel> tickets, AppColors c) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 300));
      },
      color: c.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          final isSelected = _selectedTickets.contains(ticket.ticketId);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: CheckboxListTile(
              value: isSelected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedTickets.add(ticket.ticketId);
                  } else {
                    _selectedTickets.remove(ticket.ticketId);
                  }
                });
              },
              title: TicketCard(ticket: ticket),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: c.textMuted),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tiket ditemukan',
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  List<TicketModel> _filterTickets(List<TicketModel> tickets) {
    return tickets.where((t) {
      // Status filter
      if (_selectedStatus != null && t.status != _selectedStatus) return false;

      // Priority filter
      if (_selectedPriority != null && t.priority != _selectedPriority) return false;

      // Category filter
      if (_selectedCategory != null && t.category != _selectedCategory) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery;
        return t.ticketId.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query) ||
            (t.location ?? '').toLowerCase().contains(query) ||
            t.description.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  void _bulkAssign() {
    // TODO: Show assign dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk assign ${_selectedTickets.length} tickets')),
    );
  }

  void _bulkDelete() {
    // TODO: Show delete confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bulk delete ${_selectedTickets.length} tickets')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: value != null ? c.primary.withOpacity(0.1) : c.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value != null ? c.primary : c.border,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
        underline: const SizedBox(),
        isDense: true,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 13)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
