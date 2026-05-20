import 'package:flutter/material.dart';
import '../settings_screen.dart';
import '../shared/ticket_card.dart';
import '../../utils/app_colors.dart';
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
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        context: context,
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
