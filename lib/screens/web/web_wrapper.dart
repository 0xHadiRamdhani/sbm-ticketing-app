import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import 'web_layout.dart';
import 'admin/web_admin_dashboard_screen.dart';
import 'admin/web_admin_tickets_screen.dart';
import 'admin/web_admin_stats_screen.dart';
import 'admin/web_admin_users_screen.dart';

/// Entry point for the responsive web UI — role-aware.
/// Shows different nav items and pages based on user role.
class WebWrapper extends StatefulWidget {
  const WebWrapper({Key? key}) : super(key: key);

  @override
  State<WebWrapper> createState() => _WebWrapperState();
}

class _WebWrapperState extends State<WebWrapper> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false)
          .checkAndEscalateTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().user?.role ?? 'student';

    // Select pages based on role
    final pages = _getPagesForRole(role);

    // Ensure _selectedIndex is within bounds when role changes
    if (_selectedIndex >= pages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedIndex = 0);
      });
    }

    return WebLayout(
      selectedIndex: _selectedIndex,
      onNavSelected: (i) => setState(() => _selectedIndex = i),
      child: pages[_selectedIndex],
    );
  }

  List<Widget> _getPagesForRole(String role) {
    switch (role) {
      case 'admin':
        return const [
          WebAdminDashboardScreen(),
          WebAdminTicketsScreen(),
          WebAdminStatsScreen(),
          WebAdminUsersScreen(),
        ];
      case 'technician':
        return const [
          WebAdminDashboardScreen(), // Temporary placeholder
          // TODO: Add technician pages
        ];
      case 'student':
      case 'staff':
      default:
        return const [
          WebAdminDashboardScreen(), // Temporary placeholder
          // TODO: Add requester pages
        ];
    }
  }
}
