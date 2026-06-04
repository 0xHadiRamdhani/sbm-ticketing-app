import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/device_service.dart';
import '../../services/audit_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_notifications.dart';
import '../shared/ticket_card.dart';

class ActiveDevicesScreen extends StatefulWidget {
  const ActiveDevicesScreen({super.key});

  @override
  State<ActiveDevicesScreen> createState() => _ActiveDevicesScreenState();
}

class _ActiveDevicesScreenState extends State<ActiveDevicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceService _deviceService = DeviceService();
  String _searchQuery = '';

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'Tidak diketahui';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja aktif';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _platformIcon(String deviceName) {
    final n = deviceName.toLowerCase();
    if (n.contains('android')) return Icons.phone_android_rounded;
    if (n.contains('ios')) return Icons.phone_iphone_rounded;
    if (n.contains('mac')) return Icons.laptop_mac_rounded;
    if (n.contains('windows')) return Icons.computer_rounded;
    if (n.contains('linux')) return Icons.terminal_rounded;
    return Icons.devices_rounded;
  }

  Color _platformColor(String deviceName) {
    final n = deviceName.toLowerCase();
    if (n.contains('android')) return const Color(0xFF3DDC84);
    if (n.contains('ios')) return const Color(0xFF555555);
    if (n.contains('mac')) return const Color(0xFF555555);
    if (n.contains('windows')) return const Color(0xFF0078D4);
    return const Color(0xFF6C757D);
  }

  Future<void> _revokeDevice(String uid, String userName, String deviceId, String deviceName) async {
    final confirm = await AppNotifications.showConfirmDialog(
      context,
      title: 'Paksa Logout?',
      message: 'Perangkat "$deviceName" milik $userName akan dikeluarkan dari sesi aktif. User perlu login ulang pada perangkat tersebut.',
      confirmLabel: 'Paksa Logout',
      cancelLabel: 'Batal',
      isDestructive: true,
    );

    if (confirm == true) {
      await _deviceService.removeDevice(uid, deviceId);
      await AuditService().logAction(
        actionType: 'REVOKE_DEVICE',
        targetId: uid,
        description: 'Mencabut akses perangkat "$deviceName" milik $userName',
      );
      if (mounted) {
        AppNotifications.showNotification(
          context,
          title: 'Sukses',
          message: 'Perangkat "$deviceName" berhasil dikeluarkan',
          isError: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final currentUser = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: 'Perangkat Aktif',
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              onSubmitted: (v) => setState(() => _searchQuery = v.toLowerCase()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama pengguna...',
                hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: c.textMuted, size: 20),
                filled: true,
                fillColor: c.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              style: TextStyle(color: c.textPrimary),
            ),
          ),

          // Users + Devices List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, usersSnapshot) {
                if (usersSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: c.primary));
                }
                if (!usersSnapshot.hasData || usersSnapshot.data!.docs.isEmpty) {
                  return _emptyState(c, Icons.people_alt_outlined, 'Tidak ada pengguna terdaftar');
                }

                final users = usersSnapshot.data!.docs.where((doc) {
                  final name = (doc.data() as Map<String, dynamic>)['name']?.toString().toLowerCase() ?? '';
                  return _searchQuery.isEmpty || name.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final uid = users[index].id;
                    final userName = userData['name'] ?? 'Tanpa Nama';
                    final userEmail = userData['email'] ?? '';
                    final userRole = userData['role'] ?? 'student';
                    final isCurrentUser = uid == currentUser?.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrentUser ? c.primary.withValues(alpha: 0.4) : c.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: c.isDark ? 0.1 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding: EdgeInsets.zero,
                        shape: const Border(),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: c.primary,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            if (isCurrentUser)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Anda',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: c.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userEmail,
                              style: TextStyle(color: c.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            _RoleBadge(role: userRole, c: c),
                          ],
                        ),
                        trailing: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('users')
                              .doc(uid)
                              .collection('devices')
                              .snapshots(),
                          builder: (ctx, devSnap) {
                            final count = devSnap.data?.docs.length ?? 0;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: count > 0
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : c.border.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$count perangkat',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: count > 0 ? Colors.green.shade700 : c.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.expand_more_rounded, color: c.textMuted),
                              ],
                            );
                          },
                        ),
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('users')
                                .doc(uid)
                                .collection('devices')
                                .orderBy('lastActive', descending: true)
                                .snapshots(),
                            builder: (ctx, devSnapshot) {
                              if (devSnapshot.connectionState == ConnectionState.waiting) {
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator(color: c.primary, strokeWidth: 2)),
                                );
                              }

                              if (!devSnapshot.hasData || devSnapshot.data!.docs.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: c.background,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.devices_other_outlined, color: c.textMuted, size: 20),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Tidak ada perangkat aktif',
                                          style: TextStyle(color: c.textMuted, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final devices = devSnapshot.data!.docs;
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                child: Column(
                                  children: devices.map((devDoc) {
                                    final dev = devDoc.data() as Map<String, dynamic>;
                                    final deviceId = dev['id'] ?? devDoc.id;
                                    final deviceName = dev['deviceName'] ?? 'Perangkat Tidak Dikenal';
                                    final osVersion = dev['osVersion'] ?? '';
                                    final model = dev['model'] ?? '';
                                    final lastActive = dev['lastActive'] as Timestamp?;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: c.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: c.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _platformColor(deviceName).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              _platformIcon(deviceName),
                                              color: _platformColor(deviceName),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  deviceName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: c.textPrimary,
                                                  ),
                                                ),
                                                if (model.isNotEmpty)
                                                  Text(
                                                    model,
                                                    style: TextStyle(color: c.textMuted, fontSize: 11),
                                                  ),
                                                if (osVersion.isNotEmpty)
                                                  Text(
                                                    osVersion.length > 60
                                                        ? '${osVersion.substring(0, 60)}...'
                                                        : osVersion,
                                                    style: TextStyle(color: c.textMuted, fontSize: 10),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.circle,
                                                      size: 8,
                                                      color: Colors.green.shade500,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Terakhir aktif: ${_formatTimestamp(lastActive)}',
                                                      style: TextStyle(
                                                        color: c.textSecondary,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Tombol Revoke
                                          GestureDetector(
                                            onTap: () => _revokeDevice(uid, userName, deviceId, deviceName),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.logout_rounded,
                                                color: Colors.red.shade600,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppColors c, IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: c.textMuted),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: c.textMuted, fontSize: 15)),
        ],
      ),
    );
  }
}

// Badge untuk role
class _RoleBadge extends StatelessWidget {
  final String role;
  final AppColors c;

  const _RoleBadge({required this.role, required this.c});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (role) {
      case 'admin':
        bgColor = const Color(0xFFDC2626).withValues(alpha: 0.1);
        textColor = const Color(0xFFDC2626);
        label = 'ADMIN';
        break;
      case 'technician':
        bgColor = const Color(0xFF0EA5E9).withValues(alpha: 0.1);
        textColor = const Color(0xFF0EA5E9);
        label = 'TEKNISI';
        break;
      case 'staff':
        bgColor = const Color(0xFF7C3AED).withValues(alpha: 0.1);
        textColor = const Color(0xFF7C3AED);
        label = 'STAF';
        break;
      default:
        bgColor = const Color(0xFF16A34A).withValues(alpha: 0.1);
        textColor = const Color(0xFF16A34A);
        label = 'MAHASISWA';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
