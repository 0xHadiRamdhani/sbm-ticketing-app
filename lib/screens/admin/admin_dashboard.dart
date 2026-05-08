import 'package:flutter/material.dart';
import '../settings_screen.dart';
import '../shared/ticket_card.dart';
import 'admin_tickets_screen.dart';
import 'user_management_screen.dart';

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
        extraActions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded, color: Color(0xFF1A3A5C), size: 24),
            tooltip: 'Manajemen User',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserManagementScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Admin dashboard fokus pada daftar tiket (sama seperti Requester & Technician)
      body: AdminTicketsScreen(),
    );
  }
}
