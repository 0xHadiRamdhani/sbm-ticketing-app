import 'package:flutter/material.dart';
import '../settings_screen.dart';
import '../shared/ticket_card.dart';
import 'admin_tickets_screen.dart';
import 'user_management_screen.dart';
import 'admin_stats_screen.dart';
import 'audit_log_screen.dart';
import 'notification_templates_screen.dart';
import 'export_reports_screen.dart';
import '../shared/impersonation_banner.dart';

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: buildSbmAppBar(
        onSettingsTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsScreen()),
          );
        },
      ),
      // Admin dashboard fokus pada daftar tiket (sama seperti Requester & Technician)
      body: Column(
        children: [
          const ImpersonationBanner(),
          Expanded(child: AdminTicketsScreen()),
        ],
      ),
    );
  }
}
