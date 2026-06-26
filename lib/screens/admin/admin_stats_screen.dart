import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import '../shared/ticket_card.dart';
import '../shared/ios_glass_dropdown.dart';
import '../../utils/app_colors.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({Key? key}) : super(key: key);

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  String? _selectedMonth;
  int? _selectedDay;

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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Statistik & Analitik',
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: Provider.of<TicketProvider>(
          context,
          listen: false,
        ).fetchTickets(role: 'admin'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan memuat data.',
                style: TextStyle(color: c.textSecondary),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada data tiket untuk statistik.',
                style: TextStyle(color: c.textSecondary),
              ),
            );
          }

          final allTickets = snapshot.data!;

          // Apply Filters
          final filteredTickets = allTickets.where((t) {
            bool matchMonth =
                _selectedMonth == null ||
                t.createdAt.month == _months.indexOf(_selectedMonth!);
            bool matchDay =
                _selectedDay == null ||
                t.createdAt.day == _selectedDay;
            return matchMonth && matchDay;
          }).toList();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Section
                  _card(
                    c: c,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 18,
                              color: c.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Tanggal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: IosGlassDropdown<String>(
                                value: _selectedMonth ?? 'Semua Bulan',
                                items: _months,
                                itemLabelBuilder: (m) => m,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedMonth =
                                        val == 'Semua Bulan' ? null : val;
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionHeader(
                    'Tren Tiket',
                    'Grafik 12 bulan terakhir',
                    Icons.bar_chart_rounded,
                    c,
                  ),
                  const SizedBox(height: 12),
                  _buildAnalyticsChart(filteredTickets, c),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'SLA Performance',
                    'Service Level Agreement',
                    Icons.speed_rounded,
                    c,
                  ),
                  const SizedBox(height: 12),
                  _buildSLAAnalytics(filteredTickets, c),
                  const SizedBox(height: 32),
                  _buildSectionHeader(
                    'Detail Bulanan',
                    'Rincian tiket per bulan',
                    Icons.calendar_month_rounded,
                    c,
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyDetails(filteredTickets, c),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Section header with icon + title + subtitle
  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon,
    AppColors c,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: c.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: c.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: c.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  /// Reusable card container
  Widget _card({
    required AppColors c,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.isDark
                ? Colors.transparent
                : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAnalyticsChart(List<TicketModel> tickets, AppColors c) {
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    final List<String> monthLabels = [];

    for (int i = 11; i >= 0; i--) {
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
          x: 11 - i,
          barRods: [
            BarChartRodData(
              toY: masuk.toDouble(),
              color: c.primary,
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: selesai.toDouble(),
              color: const Color(0xFF10B981),
              width: 10,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
          barsSpace: 4,
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

    return _card(
      c: c,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend row
          Row(
            children: [
              _buildLegend('Masuk', c.primary, c),
              const SizedBox(width: 16),
              _buildLegend('Selesai', const Color(0xFF10B981), c),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: maxY,
                groupsSpace: 28,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => c.isDark
                        ? const Color(0xFF253347)
                        : const Color(0xFF1F2937),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rodIndex == 0
                            ? 'Masuk: ${rod.toY.toInt()}'
                            : 'Selesai: ${rod.toY.toInt()}',
                        TextStyle(
                          color: rodIndex == 0
                              ? c.primary
                              : const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() < 0 ||
                            value.toInt() >= monthLabels.length)
                          return const SizedBox();
                        return Transform.translate(
                          offset: const Offset(-12, 0),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              monthLabels[value.toInt()],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: c.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: (maxY / 8).clamp(1, maxY),
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 8).clamp(1, maxY),
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: c.divider, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSLAAnalytics(List<TicketModel> tickets, AppColors c) {
    // Hitung semua tiket yang sudah diselesaikan
    final resolvedTickets = tickets
        .where((t) => t.status == 'Resolved')
        .toList();
    
    // Hitung tiket yang masih aktif tapi sudah melewati target (terlambat)
    final now = DateTime.now();
    final lateActiveTickets = tickets.where((t) {
      // Tiket aktif (belum resolved)
      if (t.status == 'Resolved' || t.status == 'Closed') return false;
      
      // Tentukan target: gunakan targetResolutionAt jika ada, 
      // atau hitung 1 jam dari createdAt sebagai fallback
      DateTime target;
      if (t.targetResolutionAt != null) {
        target = t.targetResolutionAt!;
      } else {
        // Fallback: 1 jam dari waktu pembuatan
        target = t.createdAt.add(const Duration(hours: 1));
      }
      
      // Target sudah terlewat
      return now.isAfter(target);
    }).toList();
    
    int onTimeCount = 0;
    int lateCount = lateActiveTickets.length; // Mulai dengan tiket aktif yang terlambat
    double totalResolutionHours = 0;

    // Hitung tiket yang sudah resolved
    for (var t in resolvedTickets) {
      if (t.resolvedAt != null && t.createdAt != null) {
        final duration = t.resolvedAt!.difference(t.createdAt);
        totalResolutionHours += duration.inMinutes / 60.0;

        // Tentukan target untuk tiket resolved
        DateTime target;
        if (t.targetResolutionAt != null) {
          target = t.targetResolutionAt!;
        } else {
          // Fallback: 1 jam dari waktu pembuatan
          target = t.createdAt.add(const Duration(hours: 1));
        }
        
        // Bandingkan waktu resolved dengan target
        if (t.resolvedAt!.isBefore(target) ||
            t.resolvedAt!.isAtSameMomentAs(target)) {
          onTimeCount++;
        } else {
          lateCount++;
        }
      }
    }

    final totalTracked = onTimeCount + lateCount;
    final int successRate = totalTracked == 0
        ? 0
        : ((onTimeCount / totalTracked) * 100).round();

    final int avgHours = resolvedTickets.isEmpty
        ? 0
        : (totalResolutionHours / resolvedTickets.length).round();

    return _card(
      c: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Big stats at top
          Row(
            children: [
              Expanded(
                child: _buildBigStat(
                  label: 'Tingkat Keberhasilan',
                  value: '$successRate%',
                  icon: Icons.check_circle_rounded,
                  color: successRate >= 80 
                      ? const Color(0xFF10B981) 
                      : successRate >= 60 
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFEF4444),
                  c: c,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBigStat(
                  label: 'Rata-rata Penyelesaian',
                  value: '$avgHours jam',
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF3B82F6),
                  c: c,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: 20),
          // Simple breakdown
          Text(
            'Rincian Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildSimpleStatusRow(
            label: 'Selesai Tepat Waktu',
            count: onTimeCount,
            total: totalTracked,
            color: const Color(0xFF10B981),
            icon: Icons.thumb_up_rounded,
            c: c,
          ),
          const SizedBox(height: 12),
          _buildSimpleStatusRow(
            label: 'Terlambat / Melewati Target',
            count: lateCount,
            total: totalTracked,
            color: const Color(0xFFEF4444),
            icon: Icons.warning_rounded,
            c: c,
          ),
          const SizedBox(height: 12),
          _buildSimpleStatusRow(
            label: 'Total Diselesaikan',
            count: resolvedTickets.length,
            total: resolvedTickets.length,
            color: c.primary,
            icon: Icons.done_all_rounded,
            c: c,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBigStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required AppColors c,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStatusRow({
    required String label,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
    required AppColors c,
    bool isBold = false,
  }) {
    final percentage = total == 0 ? 0 : ((count / total) * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBold ? color.withOpacity(0.08) : c.background,
        borderRadius: BorderRadius.circular(12),
        border: isBold ? Border.all(color: color.withOpacity(0.2)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count tiket',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              if (!isBold)
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 11,
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDetails(List<TicketModel> tickets, AppColors c) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> monthlyData = [];

    for (int i = 11; i >= 0; i--) {
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

      const months = [
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
      monthlyData.add({
        'month': months[date.month - 1],
        'year': date.year.toString(),
        'masuk': masuk,
        'selesai': selesai,
      });
    }

    return _card(
      c: c,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bulan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    _buildColumnLabel('Masuk', c.primary, c),
                    const SizedBox(width: 24),
                    _buildColumnLabel('Selesai', const Color(0xFF10B981), c),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: c.divider, height: 1),
          const SizedBox(height: 4),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: monthlyData.length,
            itemBuilder: (context, index) {
              final data = monthlyData[index];
              final masuk = data['masuk'] as int;
              final selesai = data['selesai'] as int;
              final isCurrentMonth = index == monthlyData.length - 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: isCurrentMonth
                    ? BoxDecoration(
                        color: c.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: c.primary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      )
                    : BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Month + year
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['month'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isCurrentMonth
                                ? c.primary
                                : c.textPrimary,
                          ),
                        ),
                        Text(
                          data['year'],
                          style: TextStyle(
                            fontSize: 11,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    // Values
                    Row(
                      children: [
                        _buildBadgeValue(masuk.toString(), c.primary, c),
                        const SizedBox(width: 16),
                        _buildBadgeValue(
                          selesai.toString(),
                          const Color(0xFF10B981),
                          c,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColumnLabel(String label, Color color, AppColors c) {
    return SizedBox(
      width: 56,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildBadgeValue(String value, Color color, AppColors c) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLegend(String text, Color color, AppColors c) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
