import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../shared/ticket_card.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: buildSbmAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A3A5C)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Audit Log Aktivitas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                  ),
                ),
              ],
            ),
          ),
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
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A3A5C)),
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
                    final data = logs[index].data() as Map<String, dynamic>;
                    return _buildLogItem(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : DateTime.now();
    final type = data['action_type'] ?? 'UNKNOWN';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['description'] ?? '',
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                data['admin_email'] ?? 'System',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const Spacer(),
              if (data['target_id'] != null)
                Text(
                  'ID: #${data['target_id'].toString().substring(0, 5).toUpperCase()}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ],
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
