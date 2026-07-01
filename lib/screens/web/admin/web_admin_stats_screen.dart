import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/ticket_model.dart';
import '../../../providers/ticket_provider.dart';
import '../../../utils/app_colors.dart';

class WebAdminStatsScreen extends StatelessWidget {
  const WebAdminStatsScreen({Key? key}) : super(key: key);

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
          final tickets = snap.data ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(c),
                const SizedBox(height: 28),
                _buildKPIs(tickets, c),
                const SizedBox(height: 28),
                LayoutBuilder(builder: (ctx, box) {
                  if (box.maxWidth >= 1100) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(flex: 3, child: _buildTrendChart(tickets, c)),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildCategoryChart(tickets, c)),
                    ]);
                  }
                  return Column(children: [_buildTrendChart(tickets, c), const SizedBox(height: 24), _buildCategoryChart(tickets, c)]);
                }),
                const SizedBox(height: 28),
                LayoutBuilder(builder: (ctx, box) {
                  if (box.maxWidth >= 1100) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: _buildSLA(tickets, c)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildMonthlyTable(tickets, c)),
                    ]);
                  }
                  return Column(children: [_buildSLA(tickets, c), const SizedBox(height: 24), _buildMonthlyTable(tickets, c)]);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Statistik & Laporan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.6)),
          const SizedBox(height: 6),
          Text('Analisis performa sistem tiket helpdesk', style: TextStyle(fontSize: 15, color: c.textSecondary)),
        ])),
        Row(children: [
          _ExportButton(icon: Icons.picture_as_pdf_outlined, label: 'Export PDF', onTap: () {}),
          const SizedBox(width: 10),
          _ExportButton(icon: Icons.table_chart_outlined, label: 'Export Excel', onTap: () {}),
        ]),
      ],
    );
  }

  Widget _buildKPIs(List<TicketModel> tickets, AppColors c) {
    final total = tickets.length;
    final resolved = tickets.where((t) => t.status == 'Resolved' || t.status == 'Closed').length;
    final rate = total > 0 ? (resolved / total * 100).toStringAsFixed(1) : '0.0';
    final slaOk = tickets.where((t) => t.resolvedAt != null && t.targetResolutionAt != null && t.resolvedAt!.isBefore(t.targetResolutionAt!)).length;
    final slaTotal = tickets.where((t) => t.resolvedAt != null).length;
    final slaRate = slaTotal > 0 ? (slaOk / slaTotal * 100).toStringAsFixed(1) : '0.0';
    final resolvedList = tickets.where((t) => t.resolvedAt != null).toList();
    double avgH = 0;
    if (resolvedList.isNotEmpty) avgH = resolvedList.fold<int>(0, (s, t) => s + t.resolvedAt!.difference(t.createdAt).inHours) / resolvedList.length;

    final kpis = [
      _KPI('Total Tiket', '$total', 'Semua periode', Icons.confirmation_num_outlined, const Color(0xFF3B82F6)),
      _KPI('Resolve Rate', '$rate%', '$resolved dari $total tiket', Icons.check_circle_outline_rounded, const Color(0xFF10B981)),
      _KPI('SLA Compliance', '$slaRate%', '$slaOk dari $slaTotal tiket', Icons.timer_outlined, const Color(0xFF6366F1)),
      _KPI('Avg Resolution', '${avgH.toStringAsFixed(1)}h', 'Rata-rata waktu selesai', Icons.schedule_outlined, const Color(0xFFF59E0B)),
    ];

    return LayoutBuilder(builder: (ctx, box) {
      int cols = 4;
      if (box.maxWidth < 1100) cols = 2;
      if (box.maxWidth < 600) cols = 1;
      return Wrap(spacing: 18, runSpacing: 18, children: kpis.map((k) {
        return _KPICard(kpi: k, width: (box.maxWidth - (cols - 1) * 18) / cols);
      }).toList());
    });
  }

  Widget _buildTrendChart(List<TicketModel> tickets, AppColors c) {
    final now = DateTime.now();
    final months = List.generate(12, (i) => DateFormat('MMM').format(DateTime(now.year, now.month - (11 - i), 1)));
    final data = List.generate(12, (i) {
      final m = DateTime(now.year, now.month - (11 - i), 1);
      return tickets.where((t) => t.createdAt.year == m.year && t.createdAt.month == m.month).length.toDouble();
    });

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CardTitle('Trend Tiket (12 Bulan)', 'Volume tiket per bulan', c),
      const SizedBox(height: 24),
      SizedBox(height: 220, child: BarChart(BarChartData(
        barGroups: data.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
          BarChartRodData(toY: e.value,
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            width: 18, borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
        ])).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: TextStyle(fontSize: 11, color: c.textMuted)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i >= 0 && i < months.length) return Padding(padding: const EdgeInsets.only(top: 8), child: Text(months[i], style: TextStyle(fontSize: 10, color: c.textMuted)));
              return const SizedBox();
            })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: c.divider.withOpacity(0.4), strokeWidth: 1)),
      ))),
    ]));
  }

  Widget _buildCategoryChart(List<TicketModel> tickets, AppColors c) {
    final cats = <String, int>{};
    for (var t in tickets) cats[t.category] = (cats[t.category] ?? 0) + 1;
    final colors = [const Color(0xFF3B82F6), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFF6366F1), const Color(0xFFEF4444)];

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CardTitle('Breakdown Kategori', 'Distribusi per jenis laporan', c),
      const SizedBox(height: 24),
      if (cats.isEmpty) Center(child: Text('Belum ada data', style: TextStyle(color: c.textMuted)))
      else Row(children: [
        Expanded(child: SizedBox(height: 200, child: PieChart(PieChartData(
          sections: cats.entries.map((e) {
            final i = cats.keys.toList().indexOf(e.key);
            return PieChartSectionData(value: e.value.toDouble(), title: '${e.value}', color: colors[i % colors.length],
              radius: 70, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white));
          }).toList(),
          sectionsSpace: 3, centerSpaceRadius: 36,
        )))),
        const SizedBox(width: 20),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: cats.entries.map((e) {
            final i = cats.keys.toList().indexOf(e.key);
            final col = colors[i % colors.length];
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Text(e.key, style: TextStyle(fontSize: 12, color: c.textPrimary)),
              const SizedBox(width: 8),
              Text('${e.value}', style: TextStyle(fontSize: 12, color: c.textMuted, fontWeight: FontWeight.bold)),
            ]));
          }).toList()),
      ]),
    ]));
  }

  Widget _buildSLA(List<TicketModel> tickets, AppColors c) {
    final total = tickets.length;
    final levels = [
      ['Normal (Level 0)', tickets.where((t) => t.escalationLevel == 0).length, const Color(0xFF10B981)],
      ['Warning (Level 1)', tickets.where((t) => t.escalationLevel == 1).length, const Color(0xFFF59E0B)],
      ['Breached (Level 2)', tickets.where((t) => t.escalationLevel >= 2).length, const Color(0xFFEF4444)],
    ];

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CardTitle('SLA & Eskalasi', 'Tingkat kepatuhan resolusi tiket', c),
      const SizedBox(height: 24),
      ...levels.map((l) {
        final label = l[0] as String;
        final count = l[1] as int;
        final col = l[2] as Color;
        final pct = total == 0 ? 0.0 : count / total;
        return Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.textPrimary)),
            ]),
            Text('$count (${(pct * 100).toStringAsFixed(0)}%)', style: TextStyle(fontSize: 12, color: c.textSecondary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(
            value: pct, backgroundColor: col.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(col), minHeight: 8,
          )),
        ]));
      }).toList(),
    ]));
  }

  Widget _buildMonthlyTable(List<TicketModel> tickets, AppColors c) {
    final now = DateTime.now();
    final rows = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      final mTickets = tickets.where((t) => t.createdAt.year == m.year && t.createdAt.month == m.month).toList();
      return {
        'month': DateFormat('MMM yyyy').format(m),
        'total': mTickets.length,
        'new': mTickets.where((t) => t.status == 'New').length,
        'resolved': mTickets.where((t) => t.status == 'Resolved' || t.status == 'Closed').length,
        'high': mTickets.where((t) => t.priority == 'High').length,
      };
    });

    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CardTitle('Breakdown Bulanan', '6 bulan terakhir', c),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: c.border)),
        child: Column(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(color: c.isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
            child: Row(children: [
              Expanded(flex: 3, child: Text('Bulan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textMuted))),
              ...[['Total', 1], ['Baru', 1], ['Selesai', 1], ['High', 1]].map((h) =>
                Expanded(flex: h[1] as int, child: Text(h[0] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.textMuted), textAlign: TextAlign.center))),
            ]),
          ),
          ...rows.asMap().entries.map((e) {
            final r = e.value;
            final isLast = e.key == rows.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: c.divider.withOpacity(0.5))),
                borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(10)) : null,
              ),
              child: Row(children: [
                Expanded(flex: 3, child: Text(r['month'].toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: c.textPrimary))),
                Expanded(child: Text(r['total'].toString(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: c.textPrimary), textAlign: TextAlign.center)),
                Expanded(child: Text(r['new'].toString(), style: const TextStyle(fontSize: 15, color: Color(0xFF6366F1), fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(child: Text(r['resolved'].toString(), style: const TextStyle(fontSize: 15, color: Color(0xFF10B981), fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(child: Text(r['high'].toString(), style: const TextStyle(fontSize: 15, color: Color(0xFFEF4444), fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              ]),
            );
          }).toList(),
        ]),
      ),
    ]));
  }
}

// ── Shared ──────────────────────────────────────────────────────────────────

class _KPI {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _KPI(this.title, this.value, this.subtitle, this.icon, this.color);
}

class _KPICard extends StatefulWidget {
  final _KPI kpi;
  final double width;
  const _KPICard({required this.kpi, required this.width});
  @override
  State<_KPICard> createState() => _KPICardState();
}

class _KPICardState extends State<_KPICard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final k = widget.kpi;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: widget.width,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: c.surface, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hovered ? k.color.withOpacity(0.4) : c.border),
          boxShadow: [BoxShadow(color: _hovered ? k.color.withOpacity(0.12) : Colors.black.withOpacity(c.isDark ? 0.15 : 0.04), blurRadius: _hovered ? 24 : 12, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: k.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(k.icon, color: k.color, size: 26)),
            const Spacer(),
            Text(k.value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.5)),
          ]),
          const SizedBox(height: 18),
          Text(k.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textSecondary)),
          const SizedBox(height: 4),
          Text(k.subtitle, style: TextStyle(fontSize: 13, color: c.textMuted)),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: c.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: c.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(c.isDark ? 0.15 : 0.05), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title, subtitle;
  final AppColors c;
  const _CardTitle(this.title, this.subtitle, this.c);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.textPrimary, letterSpacing: -0.3)),
    const SizedBox(height: 4),
    Text(subtitle, style: TextStyle(fontSize: 14, color: c.textMuted)),
  ]);
}

class _ExportButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ExportButton({required this.icon, required this.label, required this.onTap});
  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        child: OutlinedButton.icon(
          onPressed: widget.onTap,
          icon: Icon(widget.icon, size: 17),
          label: Text(widget.label),
          style: OutlinedButton.styleFrom(
            foregroundColor: _hovered ? const Color(0xFF3B82F6) : c.textSecondary,
            side: BorderSide(color: _hovered ? const Color(0xFF3B82F6) : c.border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}
