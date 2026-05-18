import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import '../shared/ticket_card.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Statistik & Analitik',
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: Provider.of<TicketProvider>(context, listen: false).fetchTickets(role: 'admin'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1A3A5C)));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan memuat data.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada data tiket untuk statistik.'));
          }

          final allTickets = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Volume Keluhan Bulanan', 'Tren jumlah tiket dalam 6 bulan terakhir'),
                const SizedBox(height: 16),
                _buildChartCard(
                  child: _buildVolumeChart(allTickets),
                ),
                
                const SizedBox(height: 32),
                
                _buildSectionHeader('Kecepatan Penyelesaian', 'Rata-rata waktu (jam) untuk penyelesaian tiket'),
                const SizedBox(height: 16),
                _buildChartCard(
                  child: _buildResolutionTimeChart(allTickets),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard({required Widget child}) {
    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildVolumeChart(List<TicketModel> tickets) {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    final List<String> monthLabels = [];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthTickets = tickets.where((t) => 
        t.createdAt.month == date.month && t.createdAt.year == date.year
      ).toList();
      
      spots.add(FlSpot((5 - i).toDouble(), monthTickets.length.toDouble()));
      monthLabels.add(_getMonthName(date.month).toUpperCase());
    }

    double maxVal = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxVal < 5) maxVal = 5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxVal / 3).clamp(1, 100),
          getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1.5),
          getDrawingVerticalLine: (value) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= monthLabels.length) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    monthLabels[value.toInt()],
                    style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxVal / 2).clamp(1, 100),
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(value.toInt().toString(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                );
              },
              reservedSize: 28,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 5, minY: 0, maxY: maxVal + (maxVal * 0.2),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF1A3A5C)]),
            barWidth: 3.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: const Color(0xFF1A73E8), strokeColor: Colors.white, strokeWidth: 2),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [const Color(0xFF1A73E8).withOpacity(0.15), const Color(0xFF1A3A5C).withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionTimeChart(List<TicketModel> tickets) {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    final List<String> monthLabels = [];

    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final resolvedThisMonth = tickets.where((t) => 
        t.status == 'Resolved' && t.resolvedAt != null &&
        t.resolvedAt!.month == date.month && t.resolvedAt!.year == date.year
      ).toList();

      double avgHours = 0;
      if (resolvedThisMonth.isNotEmpty) {
        final totalHours = resolvedThisMonth.fold<double>(0, (sum, t) {
          return sum + (t.resolvedAt!.difference(t.createdAt).inMinutes / 60.0);
        });
        avgHours = totalHours / resolvedThisMonth.length;
      }
      
      spots.add(FlSpot((5 - i).toDouble(), avgHours));
      monthLabels.add(_getMonthName(date.month).toUpperCase());
    }

    double maxVal = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    if (maxVal < 10) maxVal = 10;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxVal / 3).clamp(1, 100),
          getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1.5),
          getDrawingVerticalLine: (value) => FlLine(color: const Color(0xFFF1F5F9), strokeWidth: 1.5),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= monthLabels.length) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(monthLabels[value.toInt()], style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxVal / 2).clamp(1, 100),
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text('${value.toInt()}h', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 5, minY: 0, maxY: maxVal + (maxVal * 0.2),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
            barWidth: 3.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 4, color: const Color(0xFFF59E0B), strokeColor: Colors.white, strokeWidth: 2),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(colors: [const Color(0xFFF59E0B).withOpacity(0.15), const Color(0xFFD97706).withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }
}
