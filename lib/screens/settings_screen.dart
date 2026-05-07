import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'about_screen.dart';
import 'help_center_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Akun'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.blue[800]),
                  title: Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fitur Profil Saya akan segera hadir!')),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          _buildSectionHeader('Umum'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.notifications_none_outlined, color: Colors.blue[800]),
                  title: Text('Pemberitahuan', style: TextStyle(fontWeight: FontWeight.w500)),
                  value: _notificationsEnabled,
                  activeColor: Colors.blue[800],
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? 'Pemberitahuan diaktifkan' : 'Pemberitahuan dimatikan'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: Icon(Icons.help_outline, color: Colors.blue[800]),
                  title: Text('Pusat Bantuan', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HelpCenterScreen()),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined, color: Colors.blue[800]),
                  title: Text('Kebijakan Privasi', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Halaman Kebijakan Privasi sedang dalam pengembangan.')),
                    );
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blue[800]),
                  title: Text('Tentang Aplikasi', style: TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AboutScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          _buildSectionHeader('Tindakan'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red[700]),
                  title: Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red[700])),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Konfirmasi Keluar'),
                        content: Text('Apakah Anda yakin ingin keluar dari akun ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Batal', style: TextStyle(color: Colors.grey[700])),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close settings screen
                              authProvider.logout();
                            },
                            child: Text('Keluar'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
