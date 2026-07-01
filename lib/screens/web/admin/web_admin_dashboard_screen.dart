import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/ticket_model.dart';
import '../../../providers/ticket_provider.dart';
import '../../../utils/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'web_admin_ticket_detail_screen.dart';

/// Web-optimized Admin Dashboard — Premium Desktop UI
class WebAdminDashboardScreen extends StatelessWidget {
  const WebAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: StreamBuilder<List<TicketModel>>(
        stream: Provider.of<TicketProvider>(context, listen: false).fetchTickets(role: 'admin'),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: const Color(0xFF3B82F6), strokeWidth: 2.5),
                  const SizedBox(height: 16),
                  Text('Memuat data...', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text('Terjadi kesalahan sistem.', style: TextStyle(color: c.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }

          final allTickets = snap.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard Admin',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Selamat datang kembali — ${DateFormat('EEEE, d MMMM yyyy').format(DateTime.now())}',
                            style: TextStyle(fontSize: 15, color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _PremiumBadge(label: '${allTickets.where((t) => t.status == "New").length} Tiket Baru', color: const Color(0xFF3B82F6)),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Stat Cards ────────────────────────────────────────────
                _buildStatCards(allTickets, c),
                const SizedBox(height: 28),

                // ── Charts Row ────────────────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1100) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildTrendChart(allTickets, c)),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildStatusBreakdown(allTickets, c)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildTrendChart(allTickets, c),
                          const SizedBox(height: 24),
                          _buildStatusBreakdown(allTickets, c),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 28),

                // ── Recent Tickets ─────────────────────────────────────────
                _buildRecentTickets(allTickets, c),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCards(List<TicketModel> tickets, AppColors c) {
    final total = tickets.length;
    final newTickets = tickets.where((t) => t.status == 'New').length;
    final inProgress = tickets.where((t) => t.status == 'In Progress').length;
    final resolved = tickets.where((t) => t.status == 'Resolved').length;
    final closed = tickets.where((t) => t.status == 'Closed').length;

    final cards = [
      _StatCardData('Total Tiket', '$total', Icons.confirmation_num_outlined, const Color(0xFF3B82F6), 'Semua periode'),
      _StatCardData('Tiket Baru', '$newTickets', Icons.fiber_new_rounded, const Color(0xFF6366F1), 'Menunggu proses'),
      _StatCardData('Dalam Proses', '$inProgress', Icons.pending_actions_rounded, const Color(0xFFF59E0B), 'Sedang ditangani'),
      _StatCardData('Menunggu', '$resolved', Icons.check_circle_outline, const Color(0xFF10B981), 'Perlu konfirmasi'),
      _StatCardData('Selesai', '$closed', Icons.done_all_rounded, const Color(0xFF94A3B8), 'Telah ditutup'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = cards.length;
        if (constraints.maxWidth < 1400) cols = 4;
        if (constraints.maxWidth < 1100) cols = 3;
        if (constraints.maxWidth < 800) cols = 2;
        if (constraints.maxWidth < 450) cols = 1;

        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: cards.map((d) {
            final cardWidth = (constraints.maxWidth - (cols - 1) * 18) / cols;
            return _StatCard(data: d, width: cardWidth);
          }).toList(),
        );
      },
    );
  }

  Widget _buildTrendChart(List<TicketModel> tickets, AppColors c) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      return DateFormat('MMM').format(DateTime(now.year, now.month - (5 - i), 1));
    });
    final created = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return tickets.where((t) => t.createdAt.year == m.year && t.createdAt.month == m.month).length.toDouble();
    });
    final resolved = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return tickets.where((t) => (t.status == 'Resolved' || t.status == 'Closed') && t.createdAt.year == m.year && t.createdAt.month == m.month).length.toDouble();
    });

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trend Tiket', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.3)),
                    Text('6 Bulan Terakhir', style: TextStyle(fontSize: 12, color: c.textMuted)),
                  ],
                ),
              ),
              // Legend
              Row(children: [
                _LegendDot(color: const Color(0xFF3B82F6), label: 'Masuk'),
                const SizedBox(width: 16),
                _LegendDot(color: const Color(0xFF10B981), label: 'Selesai'),
              ]),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(6, (i) => BarChartGroupData(
                  x: i,
                  barsSpace: 4,
                  barRods: [
                    BarChartRodData(toY: created[i], color: const Color(0xFF3B82F6), width: 14,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      backDrawRodData: BackgroundBarChartRodData(show: true, toY: (created.reduce((a, b) => a > b ? a : b) + 2), color: Colors.transparent)),
                    BarChartRodData(toY: resolved[i], color: const Color(0xFF10B981), width: 14,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ],
                )),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 36,
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(fontSize: 11, color: c.textMuted)),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i >= 0 && i < months.length) return Padding(padding: const EdgeInsets.only(top: 8), child: Text(months[i], style: TextStyle(fontSize: 12, color: c.textSecondary)));
                      return const SizedBox();
                    },
                  )),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: c.divider.withOpacity(0.5), strokeWidth: 1),
                ),
                groupsSpace: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(List<TicketModel> tickets, AppColors c) {
    final statusMap = {
      'New': tickets.where((t) => t.status == 'New').length,
      'In Progress': tickets.where((t) => t.status == 'In Progress').length,
      'Resolved': tickets.where((t) => t.status == 'Resolved').length,
      'Closed': tickets.where((t) => t.status == 'Closed').length,
      'Pending': tickets.where((t) => t.status == 'Pending').length,
    };
    final statusColors = {
      'New': const Color(0xFF6366F1),
      'In Progress': const Color(0xFFF59E0B),
      'Resolved': const Color(0xFF10B981),
      'Closed': const Color(0xFF94A3B8),
      'Pending': const Color(0xFFEF4444),
    };
    final total = tickets.length;

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Tiket', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.3)),
          Text('Distribusi saat ini', style: TextStyle(fontSize: 14, color: c.textMuted)),
          const SizedBox(height: 32),
          ...statusMap.entries.map((e) {
            final pct = total == 0 ? 0.0 : e.value / total;
            final col = statusColors[e.key]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Text(e.key, style: TextStyle(fontSize: 15, color: c.textPrimary, fontWeight: FontWeight.w500)),
                      ]),
                      Text('${e.value} (${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(fontSize: 14, color: c.textSecondary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: col.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(col),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentTickets(List<TicketModel> tickets, AppColors c) {
    final recent = (tickets.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt))).take(8).toList();

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tiket Terbaru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.3)),
                Text('8 tiket paling baru', style: TextStyle(fontSize: 14, color: c.textMuted)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                ),
                child: const Text('Lihat Semua', style: TextStyle(fontSize: 14, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (recent.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(children: [
                  Icon(Icons.inbox_outlined, size: 56, color: c.textMuted),
                  const SizedBox(height: 12),
                  Text('Belum ada tiket', style: TextStyle(color: c.textSecondary, fontSize: 14)),
                ]),
              ),
            )
          else
            Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('Kategori / Judul', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.3))),
                      Expanded(flex: 2, child: Text('Lokasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.3))),
                      Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.3))),
                      Expanded(flex: 1, child: Text('Prioritas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.3))),
                      Expanded(flex: 1, child: Text('Tanggal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.textMuted, letterSpacing: 0.3))),
                    ],
                  ),
                ),
                ...recent.map((t) => _TicketRow(ticket: t)),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// DATA MODELS & SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────

class _StatCardData {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _StatCardData(this.title, this.value, this.icon, this.color, this.subtitle);
}

class _StatCard extends StatefulWidget {
  final _StatCardData data;
  final double width;
  const _StatCard({required this.data, required this.width});
  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: widget.width,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hovered ? widget.data.color.withOpacity(0.4) : c.border),
          boxShadow: [
            BoxShadow(
              color: _hovered ? widget.data.color.withOpacity(0.12) : Colors.black.withOpacity(c.isDark ? 0.15 : 0.04),
              blurRadius: _hovered ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: widget.data.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.data.icon, color: widget.data.color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data.value,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(widget.data.title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textSecondary)),
                  Text(widget.data.subtitle,
                    style: TextStyle(fontSize: 13, color: c.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  const _PremiumCard({required this.child});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PremiumBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: c.textSecondary)),
      ],
    );
  }
}

class _TicketRow extends StatefulWidget {
  final TicketModel ticket;
  const _TicketRow({required this.ticket});
  @override
  State<_TicketRow> createState() => _TicketRowState();
}

class _TicketRowState extends State<_TicketRow> {
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF3B82F6).withOpacity(0.04) : Colors.transparent,
          border: Border(bottom: BorderSide(color: c.divider.withOpacity(0.5))),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => WebAdminTicketDetailScreen(ticket: t)));
            },
            child: Row(
              children: [
                Expanded(flex: 3, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(t.description, style: TextStyle(fontSize: 13, color: c.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                )),
                Expanded(flex: 2, child: Text(t.location ?? '-', style: TextStyle(fontSize: 14, color: c.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Expanded(flex: 2, child: _StatusPill(status: t.status)),
                Expanded(flex: 1, child: _PriorityChip(priority: t.priority)),
                Expanded(flex: 1, child: Text(DateFormat('dd MMM').format(t.createdAt), style: TextStyle(fontSize: 14, color: c.textMuted))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final Map<String, Color> colors = {
      'New': const Color(0xFF6366F1),
      'Assigned': const Color(0xFFF59E0B),
      'In Progress': const Color(0xFF3B82F6),
      'Pending': const Color(0xFFEF4444),
      'Resolved': const Color(0xFF10B981),
      'Closed': const Color(0xFF94A3B8),
    };
    final col = colors[status] ?? const Color(0xFF94A3B8);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: col.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 12, color: col, fontWeight: FontWeight.w600)),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  const _PriorityChip({required this.priority});
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: col),
        const SizedBox(width: 6),
        Text(priority, style: TextStyle(fontSize: 13, color: col, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
