import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'web/web_wrapper.dart';
import 'web/web_admin_login_screen.dart';
import 'admin/admin_dashboard.dart';
import 'technician/technician_dashboard.dart';
import 'requester/requester_dashboard.dart';

/// Routes authenticated users based on platform and role.
/// Web: Shows web UI for admin, mobile dashboards for others
/// Mobile: Shows role-specific mobile dashboards
class DashboardWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If not authenticated
        if (authProvider.user == null) {
          // On web, show admin login screen
          if (kIsWeb) {
            return const WebAdminLoginScreen();
          }
          // On mobile, show regular login screen
          return LoginScreen();
        }

        // If authenticated, route based on platform and role
        final role = authProvider.user?.role ?? 'student';
        
        // Web platform: only admin gets web UI, others get mobile dashboards
        if (kIsWeb) {
          if (role == 'admin') {
            return const WebWrapper();
          }
          // Non-admin on web still use mobile-style dashboards
          return _getMobileDashboardForRole(role);
        }
        
        // Mobile platform: always use mobile dashboards
        return _getMobileDashboardForRole(role);
      },
    );
  }

  Widget _getMobileDashboardForRole(String role) {
    switch (role) {
      case 'admin':
        return AdminDashboard();
      case 'technician':
        return TechnicianDashboard();
      case 'student':
      case 'staff':
      default:
        return RequesterDashboard();
    }
  }
}
