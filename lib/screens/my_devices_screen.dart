import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/device_service.dart';
import '../utils/app_notifications.dart';
import '../utils/app_colors.dart';
import 'shared/ticket_card.dart';

class MyDevicesScreen extends StatefulWidget {
  const MyDevicesScreen({super.key});

  @override
  State<MyDevicesScreen> createState() => _MyDevicesScreenState();
}

class _MyDevicesScreenState extends State<MyDevicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceService _deviceService = DeviceService();
  String? _currentDeviceId;

  @override
  void initState() {
    super.initState();
    _loadCurrentDeviceId();
  }

  Future<void> _loadCurrentDeviceId() async {
    final id = await _deviceService.getOrCreateDeviceId();
    if (mounted) setState(() => _currentDeviceId = id);
  }

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

  Future<void> _removeDevice(String uid, String deviceId, String deviceName, bool isCurrentDevice) async {
    if (isCurrentDevice) {
      AppNotifications.showNotification(
        context,
        title: 'Info',
        message: 'Tidak bisa menghapus perangkat yang sedang digunakan.',
        isError: true,
      );
      return;
    }

    final confirm = await AppNotifications.showConfirmDialog(
      context,
      title: 'Hapus Perangkat?',
      message: 'Perangkat "$deviceName" akan dihapus dari daftar sesi aktif Anda.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      isDestructive: true,
    );

    if (confirm == true) {
      await _deviceService.removeDevice(uid, deviceId);
      if (mounted) {
        AppNotifications.showNotification(
          context,
          title: 'Sukses',
          message: 'Perangkat "$deviceName" dihapus',
          isError: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = context.watch<LanguageProvider>();
    final uid = context.read<AuthProvider>().user?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: c.background,
        appBar: buildSbmAppBar(showBackButton: true, onBackPressed: () => Navigator.pop(context), titleText: lang.translate('Perangkat Aktif', 'Active Devices')),
        body: Center(child: Text(lang.translate('Tidak ada sesi aktif', 'No active session'), style: TextStyle(color: c.textMuted))),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: buildSbmAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        titleText: lang.translate('Perangkat Aktif Saya', 'My Active Devices'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(uid)
            .collection('devices')
            .orderBy('lastActive', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: c.primary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.devices_other_outlined, size: 64, color: c.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada perangkat terdaftar.',
                    style: TextStyle(color: c.textMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login ulang untuk mendaftarkan perangkat ini.',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final devices = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: c.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ini adalah daftar perangkat yang pernah login dengan akun Anda. Hapus perangkat yang tidak Anda kenal.',
                        style: TextStyle(color: c.textPrimary, fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              ...devices.map((devDoc) {
                final dev = devDoc.data() as Map<String, dynamic>;
                final deviceId = dev['id'] ?? devDoc.id;
                final deviceName = dev['deviceName'] ?? 'Perangkat Tidak Dikenal';
                final osVersion = dev['osVersion'] ?? '';
                final model = dev['model'] ?? '';
                final lastActive = dev['lastActive'] as Timestamp?;
                final isCurrentDevice = deviceId == _currentDeviceId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrentDevice ? c.primary.withValues(alpha: 0.5) : c.border,
                      width: isCurrentDevice ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: c.isDark ? 0.1 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _platformColor(deviceName).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _platformIcon(deviceName),
                            color: _platformColor(deviceName),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      deviceName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isCurrentDevice)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: c.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        lang.translate('Perangkat Ini', 'This Device'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: c.primary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (model.isNotEmpty)
                                Text(model, style: TextStyle(color: c.textMuted, fontSize: 12)),
                              if (osVersion.isNotEmpty)
                                Text(
                                  osVersion.length > 55 ? '${osVersion.substring(0, 55)}...' : osVersion,
                                  style: TextStyle(color: c.textMuted, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: Colors.green.shade500),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Terakhir aktif: ${_formatTimestamp(lastActive)}',
                                    style: TextStyle(color: c.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeDevice(uid, deviceId, deviceName, isCurrentDevice),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCurrentDevice
                                  ? c.border.withValues(alpha: 0.3)
                                  : Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCurrentDevice ? Icons.lock_outline_rounded : Icons.delete_outline_rounded,
                              color: isCurrentDevice ? c.textMuted : Colors.red.shade600,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
