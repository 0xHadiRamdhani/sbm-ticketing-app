import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/ticket_model.dart';
import '../../../providers/ticket_provider.dart';
import '../../../utils/app_colors.dart';

/// Web Admin Stats Screen - Comprehensive analytics and reporting
class WebAdminStatsScreen extends StatelessWidget {
  const WebAdminStatsScreen({Key? key}) : super(key: key);

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
                'Terjadi kesalahan: ${snap.error}',
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistik & Laporan',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Analisis performa sistem tiket',
                          style: TextStyle(
                            fontSize: 14,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Export to PDF
                          },
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('Export PDF'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Export to Excel
                          },
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: const Text('Export Excel'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // KPI Cards
                _buildKPICards(allTickets, c),
                const SizedBox(height: 32),

                // Charts
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1200) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildMonthlyTrendChart(allTickets, c),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildCategoryPieChart(allTickets, c),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildMonthlyTrendChart(allTickets, c),
                          const SizedBox(height: 24),
                          _buildCategoryPieChart(allTickets, c),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),

                // SLA Performance
                _buildSLAPerformance(allTickets, c),
                const SizedBox(height: 32),

                // Monthly Breakdown Table
                _buildMonthlyBreakdown(allTickets, c),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICards(List<TicketModel> tickets, AppColors c) {
    final total = tickets.length;
    final resolved = tickets.where((t) => t.status == 'Resolved' || t.status == 'Closed').length;
    final resolveRate = total > 0 ? (resolved / total * 100).toStringAsFixed(1) : '0.0';

    // SLA Compliance
    final slaCompliant = tickets.where((t) {
      if (t.targetResolutionAt == null) return false;
      if (t.resolvedAt == null) return false;
      return t.resolvedAt!.isBefore(t.targetResolutionAt!);
    }).length;
    final slaTotal = tickets.where((t) => t.resolvedAt != null).length;
    final slaRate = slaTotal > 0 ? (slaCompliant / slaTotal * 100).toStringAsFixed(1) : '0.0';

    // Average resolution time
    final resolvedTickets = tickets.where((t) => t.resolvedAt != null).toList();
    double avgHours = 0;
    if (resolvedTickets.isNotEmpty) {
      final totalHours = resolvedTickets.fold<int>(
        0,
        (sum, t) => sum + t.resolvedAt!.difference(t.createdAt).inHours,
      );
      avgHours = totalHours / resolvedTickets.length;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = 4;
        if (constraints.maxWidth < 1200) cols = 2;
        if (constraints.maxWidth < 600) cols = 1;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _KPICard(
              title: 'Total Tiket',
              value: '$total',
              subtitle: 'Semua periode',
              icon: Icons.confirmation_num_outlined,
              color: const Color(0xFF1A3A5C),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _KPICard(
              title: 'Resolve Rate',
              value: '$resolveRate%',
              subtitle: '$resolved dari $total tiket',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF66BB6A),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _KPICard(
              title: 'SLA Compliance',
              value: '$slaRate%',
              subtitle: '$slaCompliant dari $slaTotal tiket',
              icon: Icons.timer_outlined,
              color: const Color(0xFF42A5F5),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
            _KPICard(
              title: 'Avg Resolution',
              value: '${avgHours.toStringAsFixed(1)}h',
              subtitle: 'Rata-rata penyelesaian',
              icon: Icons.schedule_outlined,
              color: const Color(0xFFFFA726),
              width: (constraints.maxWidth - (cols - 1) * 16) / cols,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthlyTrendChart(List<TicketModel> tickets, AppColors c) {
    final now = DateTime.now();
    final months = <String>[];
    final data = <double>[];

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      months.add(DateFormat('MMM').format(month));
      
      final count = tickets.where((t) {
        return t.createdAt.year == month.year &&
               t.createdAt.month == month.month;
      }).length;
      data.add(count.toDouble());
    }

    return _WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend Tiket (12 Bulan)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: const Color(0xFF1A3A5C),
                        width: 24,
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
                        style: TextStyle(fontSize: 12, color: c.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          return Text(
                            months[value.toInt()],
                            style: TextStyle(fontSize: 11, color: c.textSecondary),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
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

  Widget _buildCategoryPieChart(List<TicketModel> tickets, AppColors c) {
    final categories = <String, int>{};
    for (var t in tickets) {
      categories[t.category] = (categories[t.category] ?? 0) + 1;
    }

    final colors = [
      const Color(0xFF1A3A5C),
      const Color(0xFF42A5F5),
      const Color(0xFF66BB6A),
      const Color(0xFFFFA726),
    ];

    return _WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown Kategori',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: categories.entries.map((e) {
                        final index = categories.keys.toList().indexOf(e.key);
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          title: '${e.value}',
                          color: colors[index % colors.length],
                          radius: 80,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.entries.map((e) {
                    final index = categories.keys.toList().indexOf(e.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colors[index % colors.length],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSLAPerformance(List<TicketModel> tickets, AppColors c) {
    final escalated = tickets.where((t) => t.escalationLevel > 0).length;
    final total = tickets.length;

    return _WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SLA & Escalation Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _SLABar(
            label: 'Normal (Level 0)',
            count: total - escalated,
            total: total,
            color: const Color(0xFF66BB6A),
          ),
          const SizedBox(height: 16),
          _SLABar(
            label: 'Warning (Level 1)',
            count: tickets.where((t) => t.escalationLevel == 1).length,
            total: total,
            color: const Color(0xFFFFA726),
          ),
          const SizedBox(height: 16),
          _SLABar(
            label: 'Breached (Level 2)',
            count: tickets.where((t) => t.escalationLevel == 2).length,
            total: total,
            color: const Color(0xFFEF5350),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown(List<TicketModel> tickets, AppColors c) {
    final now = DateTime.now();
    final monthlyData = <Map<String, dynamic>>[];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthTickets = tickets.where((t) {
        return t.createdAt.year == month.year &&
               t.createdAt.month == month.month;
      }).toList();

      monthlyData.add({
        'month': DateFormat('MMMM yyyy').format(month),
        'total': monthTickets.length,
        'new': monthTickets.where((t) => t.status == 'New').length,
        'resolved': monthTickets.where((t) => t.status == 'Resolved' || t.status == 'Closed').length,
        'high': monthTickets.where((t) => t.priority == 'High').length,
      });
    }

    return _WebCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown Bulanan (6 Bulan Terakhir)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.divider)),
                ),
                children: [
                  _TableHeader('Bulan'),
                  _TableHeader('Total'),
                  _TableHeader('Baru'),
                  _TableHeader('Selesai'),
                  _TableHeader('High Priority'),
                ],
              ),
              ...monthlyData.map((data) => TableRow(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: c.divider.withOpacity(0.3))),
                ),
                children: [
                  _TableCell(data['month'].toString()),
                  _TableCell(data['total'].toString(), color: c.textPrimary, bold: true),
                  _TableCell(data['new'].toString(), color: const Color(0xFF2196F3)),
                  _TableCell(data['resolved'].toString(), color: const Color(0xFF66BB6A)),
                  _TableCell(data['high'].toString(), color: const Color(0xFFEF5350)),
                ],
              )),
            ],
          ),
        ],
      ),
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

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double width;

  const _KPICard({
    required this.title,
    required this.value,
    required this.subtitle,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SLABar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _SLABar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
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
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            Text(
              '$count tiket (${(percentage * 100).toStringAsFixed(1)}%)',
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
              height: 12,
              decoration: BoxDecoration(
                color: c.isDark
                    ? c.textMuted.withOpacity(0.1)
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
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
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;

  const _TableCell(this.text, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: color ?? c.textPrimary,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
