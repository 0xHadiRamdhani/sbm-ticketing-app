import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'requester/requester_dashboard.dart';
import 'technician/technician_dashboard.dart';
import 'admin/admin_dashboard.dart';

class DashboardWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.user == null) {
          return LoginScreen();
        }

        // Role-based routing
        switch (authProvider.user!.role) {
          case 'admin':
            return AdminDashboard();
          case 'technician':
            return TechnicianDashboard();
          case 'student':
          case 'staff':
          default:
            return RequesterDashboard();
        }
      },
    );
  }
}
