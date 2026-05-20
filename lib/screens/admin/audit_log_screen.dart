import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../shared/ticket_card.dart';
import 'audit_log_detail_screen.dart';
import '../../utils/app_colors.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Audit Log Aktivitas',
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('audit_logs')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Gagal memuat log: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: c.primary),
                  );
                }

                final logs = snapshot.data?.docs ?? [];
                
                if (logs.isEmpty) {
                  return const DashboardEmptyState(
                    icon: Icons.history_rounded, 
                    message: 'Belum ada aktivitas tercatat.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final doc = logs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildLogItem(context, data, doc.id, c);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, Map<String, dynamic> data, String logId, AppColors c) {
    final timestamp = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();
    final type = data['action_type'] ?? 'UNKNOWN';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AuditLogDetailScreen(
                  logData: data,
                  logId: logId,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getActionColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type.replaceAll('_', ' '),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getActionColor(type)),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(timestamp),
                      style: TextStyle(fontSize: 11, color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['description'] ?? '',
                  style: TextStyle(fontSize: 14, color: c.textPrimary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: c.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      data['admin_email'] ?? 'System',
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                    const Spacer(),
                    if (data['target_id'] != null)
                      Text(
                        'ID: #${data['target_id'].toString().substring(0, 5).toUpperCase()}',
                        style: TextStyle(fontSize: 11, color: c.textMuted, fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getActionColor(String type) {
    if (type.contains('DELETE')) return Colors.red;
    if (type.contains('UPDATE')) return Colors.orange;
    if (type.contains('CREATE')) return Colors.green;
    return const Color(0xFF1A3A5C);
  }
}
