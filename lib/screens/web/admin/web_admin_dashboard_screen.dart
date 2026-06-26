import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/ticket_model.dart';
import '../../../providers/ticket_provider.dart';
import '../../../utils/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';

/// Web-optimized Admin Dashboard
/// Responsive dengan desktop layout: stat cards, charts, dan recent activity
class WebAdminDashboardScreen extends StatelessWidget {
  const WebAdminDashboardScreen({Key? key}) : super(key: key);

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
          if (snap.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan sistem.',
                style: TextStyle(color: c.textSecondary),
              ),
            );
          }

          final allTickets = snap.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Dashboard Admin',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ringkasan sistem tiket dan aktivitas terkini',
                  style: TextStyle(
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Stat Cards
                _buildStatCards(allTickets, c),
                const SizedBox(height: 32),

                // Charts Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1200) {
                      // Desktop: 2 columns
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTrendChart(allTickets, c),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildPriorityBreakdown(allTickets, c),
                          ),
                        ],
                      );
                    } else {
                      // Mobile: stacked
                      return Column(
                        children: [
                          _buildTrendChart(allTickets, c),
                          const SizedBox(height: 24),
                          _buildPriorityBreakdown(allTickets, c),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Recent Tickets
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
    final inProgress =
        tickets.where((t) => t.status == 'In Progress').length;
    final resolved = tickets.where((t) => t.status == 'Resolved').length;
    final closed = tickets.where((t) => t.status == 'Closed').length;

    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = 5;
        if (constraints.maxWidth < 1400) cols = 4;
        if (constraints.maxWidth < 1000) cols = 3;
        if (constraints.maxWidth < 700) cols = 2;
        if (constraints.maxWidth < 400) cols = 1;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _StatCard(
              title: 'Total Tiket',
              value: '$total',
              icon: Icons.confirmation_num_outlined,
              color: const Color(0xFF1A3A5C),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _StatCard(
              title: 'Tiket Baru',
              value: '$newTickets',
              icon: Icons.fiber_new_rounded,
              color: const Color(0xFF2196F3),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _StatCard(
              title: 'Dalam Proses',
              value: '$inProgress',
              icon: Icons.pending_actions_outlined,
              color: const Color(0xFFFFA726),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _StatCard(
              title: 'Menunggu Konfirmasi',
              value: '$resolved',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF66BB6A),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _StatCard(
              title: 'Selesai',
              value: '$closed',
              icon: Icons.done_all_rounded,
              color: const Color(0xFF9E9E9E),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendChart(List<TicketModel> tickets, AppColors c) {
    // Group by month (last 6 months)
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final month = DateTime(now.year, now.month - i, 1);
      return DateFormat('MMM').format(month);
    }).reversed.toList();

    final data = List.generate(6, (i) {
      final month = DateTime(now.year, now.month - (5 - i), 1);
      return tickets
          .where((t) =>
              t.createdAt.year == month.year &&
              t.createdAt.month == month.month)
          .length
          .toDouble();
    });

    return _WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Tiket (6 Bulan Terakhir)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: const Color(0xFF1A3A5C),
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: c.divider,
                    strokeWidth: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown(List<TicketModel> tickets, AppColors c) {
    final high = tickets.where((t) => t.priority == 'High').length;
    final medium = tickets.where((t) => t.priority == 'Medium').length;
    final low = tickets.where((t) => t.priority == 'Low').length;
    final total = tickets.length;

    return _WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown Prioritas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _PriorityBar(
            label: 'High',
            count: high,
            total: total,
            color: const Color(0xFFEF5350),
            icon: Icons.arrow_upward_rounded,
          ),
          const SizedBox(height: 16),
          _PriorityBar(
            label: 'Medium',
            count: medium,
            total: total,
            color: const Color(0xFFFFA726),
            icon: Icons.remove_rounded,
          ),
          const SizedBox(height: 16),
          _PriorityBar(
            label: 'Low',
            count: low,
            total: total,
            color: const Color(0xFF66BB6A),
            icon: Icons.arrow_downward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTickets(List<TicketModel> tickets, AppColors c) {
    // Sort by created date, take top 10
    final recent = (tickets.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .take(10)
        .toList();

    return _WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiket Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all tickets
                },
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: c.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: c.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada tiket',
                      style: TextStyle(color: c.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.divider)),
                  ),
                  children: [
                    _TableHeader('Kategori'),
                    _TableHeader('Lokasi'),
                    _TableHeader('Status'),
                    _TableHeader('Prioritas'),
                    _TableHeader('Waktu'),
                  ],
                ),
                ...recent.map((t) => _buildTicketRow(t, c)),
              ],
            ),
        ],
      ),
    );
  }

  TableRow _buildTicketRow(TicketModel ticket, AppColors c) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider.withOpacity(0.3))),
      ),
      children: [
        _TableCell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                ticket.description.length > 50
                    ? '${ticket.description.substring(0, 50)}...'
                    : ticket.description,
                style: TextStyle(fontSize: 12, color: c.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _TableCell(
          child: Text(
            ticket.location ?? '-',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _TableCell(child: _PillBadge(label: ticket.status)),
        _TableCell(child: _PriorityBadge(priority: ticket.priority)),
        _TableCell(
          child: Text(
            DateFormat('dd MMM').format(ticket.createdAt),
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────

class _WebCard extends StatelessWidget {
  final Widget child;
  const _WebCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _PriorityBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final percentage = total == 0 ? 0.0 : (count / total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '$count tiket',
              style: TextStyle(
                fontSize: 13,
                color: c.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: c.isDark
                    ? c.textMuted.withOpacity(0.1)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: c.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final Widget child;
  const _TableCell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: child,
    );
  }
}

class _PillBadge extends StatelessWidget {
  final String label;
  const _PillBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (label) {
      case 'New':
        bg = const Color(0xFF2196F3);
        fg = Colors.white;
        break;
      case 'Assigned':
        bg = const Color(0xFFFF9800);
        fg = Colors.white;
        break;
      case 'In Progress':
        bg = const Color(0xFFFFA726);
        fg = Colors.white;
        break;
      case 'Pending':
        bg = const Color(0xFFFF5722);
        fg = Colors.white;
        break;
      case 'Resolved':
        bg = const Color(0xFF66BB6A);
        fg = Colors.white;
        break;
      case 'Closed':
        bg = const Color(0xFF9E9E9E);
        fg = Colors.white;
        break;
      default:
        bg = Colors.grey;
        fg = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Color col;
    IconData ico;
    switch (priority) {
      case 'Low':
        col = const Color(0xFF66BB6A);
        ico = Icons.arrow_downward_rounded;
        break;
      case 'Medium':
        col = const Color(0xFFFFA726);
        ico = Icons.remove_rounded;
        break;
      case 'High':
        col = const Color(0xFFEF5350);
        ico = Icons.arrow_upward_rounded;
        break;
      default:
        col = c.textMuted;
        ico = Icons.help_outline;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ico, size: 14, color: col),
        const SizedBox(width: 4),
        Text(
          priority,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: col,
          ),
        ),
      ],
    );
  }
}
