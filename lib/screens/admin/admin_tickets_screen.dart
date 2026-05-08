import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final List<String> _categories = [
    'Semua Kategori',
    'Hardware',
    'Software',
    'Jaringan',
    'Fasilitas',
    'Lainnya'
  ];
  final List<String> _priorities = ['Semua Prioritas', 'Low', 'Medium', 'High', 'Critical'];

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
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 20),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                      value: _selectedCategory ?? 'Semua Kategori',
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val == 'Semua Kategori' ? null : val;
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
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 20),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                      value: _selectedPriority ?? 'Semua Prioritas',
                      items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPriority = val == 'Semua Prioritas' ? null : val;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Stream Data ────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<TicketModel>>(
            stream: Provider.of<TicketProvider>(context, listen: false).fetchTickets(role: 'admin'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A5C)));
              }
              if (snapshot.hasError) {
                return const DashboardEmptyState(icon: Icons.error_outline, message: 'Terjadi kesalahan sistem.');
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const DashboardEmptyState(icon: Icons.inbox_outlined, message: 'Tidak ada data tiket.');
              }

              final allTickets = snapshot.data!;
              
              // Apply Filters
              final filteredTickets = allTickets.where((t) {
                bool matchCategory = _selectedCategory == null || t.category == _selectedCategory;
                bool matchPriority = _selectedPriority == null || t.priority == _selectedPriority;
                return matchCategory && matchPriority;
              }).toList();

              // Stats
              int total = filteredTickets.length;
              int open = filteredTickets.where((t) => t.status == 'Open').length;
              int inProgress = filteredTickets.where((t) => t.status == 'In Progress').length;
              int resolved = filteredTickets.where((t) => t.status == 'Resolved').length;

              return Column(
                children: [
                  // ── Statistics Cards ────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatCard('Total', total, const Color(0xFF0F172A), const Color(0xFFF1F5F9)),
                          _buildStatCard('Open', open, const Color(0xFFDC2626), const Color(0xFFFEF2F2)),
                          _buildStatCard('In Progress', inProgress, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                          _buildStatCard('Resolved', resolved, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
                        ],
                      ),
                    ),
                  ),

                  // ── Ticket List ─────────────────────────────────────────────
                  Expanded(
                    child: Container(
                      color: const Color(0xFFF8FAFC),
                      child: filteredTickets.isEmpty 
                        ? const DashboardEmptyState(icon: Icons.search_off_rounded, message: 'Tidak ada tiket yang sesuai filter.')
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTickets.length,
                            itemBuilder: (context, index) {
                              return TicketCard(ticket: filteredTickets[index]);
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
