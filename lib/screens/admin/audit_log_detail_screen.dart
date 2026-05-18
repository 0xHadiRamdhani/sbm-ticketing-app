import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../shared/ticket_card.dart';

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
    final timestamp = logData['timestamp'] != null 
        ? (logData['timestamp'] as Timestamp).toDate() 
        : DateTime.now();
    final type = logData['action_type'] ?? 'UNKNOWN';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Informasi Detail',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
              ),
            ),
            const SizedBox(height: 16),

            // Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.tag_rounded, 'Log ID', logId.substring(0, 8).toUpperCase()),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(Icons.calendar_today_rounded, 'Waktu Kejadian', DateFormat('dd MMMM yyyy, HH:mm:ss').format(timestamp)),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(Icons.person_outline_rounded, 'Dilakukan Oleh (Email)', logData['admin_email'] ?? 'System'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(Icons.badge_outlined, 'Admin ID', logData['admin_id'] ?? '-'),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(Icons.my_location_rounded, 'Target ID', logData['target_id'] ?? '-'),
                ],
              ),
            ),

            if (logData['details'] != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Data Tambahan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  logData['details'].toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
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
