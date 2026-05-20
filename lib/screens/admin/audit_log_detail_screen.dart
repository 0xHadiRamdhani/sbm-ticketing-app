import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../shared/ticket_card.dart';
import '../../utils/app_colors.dart';

class AuditLogDetailScreen extends StatelessWidget {
  final Map<String, dynamic> logData;
  final String logId;

  const AuditLogDetailScreen({
    Key? key,
    required this.logData,
    required this.logId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final timestamp = logData['timestamp'] != null 
        ? (logData['timestamp'] as Timestamp).toDate() 
        : DateTime.now();
    final type = logData['action_type'] ?? 'UNKNOWN';

    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Detail Log Audit',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(
                    color: c.isDark ? Colors.transparent : Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getActionColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getActionColor(type),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    logData['description'] ?? 'Tidak ada deskripsi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Informasi Detail',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.isDark ? c.primary : const Color(0xFF1A3A5C),
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.tag_rounded, 'Log ID', logId.substring(0, 8).toUpperCase(), c),
                  Divider(height: 24, color: c.border),
                  _buildDetailRow(Icons.calendar_today_rounded, 'Waktu Kejadian', DateFormat('dd MMMM yyyy, HH:mm:ss').format(timestamp), c),
                  Divider(height: 24, color: c.border),
                  _buildDetailRow(Icons.person_outline_rounded, 'Dilakukan Oleh (Email)', logData['admin_email'] ?? 'System', c),
                  Divider(height: 24, color: c.border),
                  _buildDetailRow(Icons.badge_outlined, 'Admin ID', logData['admin_id'] ?? '-', c),
                  Divider(height: 24, color: c.border),
                  _buildDetailRow(Icons.my_location_rounded, 'Target ID', logData['target_id'] ?? '-', c),
                ],
              ),
            ),

            if (logData['details'] != null) ...[
              const SizedBox(height: 24),
              Text(
                'Data Tambahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.isDark ? c.primary : const Color(0xFF1A3A5C),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                  border: c.isDark ? Border.all(color: c.border) : null,
                ),
                child: Text(
                  logData['details'].toString(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: c.isDark ? const Color(0xFF38BDF8) : const Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, AppColors c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: c.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getActionColor(String type) {
    if (type.contains('DELETE')) return Colors.red;
    if (type.contains('UPDATE')) return Colors.orange;
    if (type.contains('CREATE')) return Colors.green;
    return const Color(0xFF1A3A5C);
  }
}
