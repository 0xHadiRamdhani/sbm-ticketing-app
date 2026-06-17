import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan atau membuat Device ID unik untuk instalasi ini
  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = 'DEV-${DateTime.now().millisecondsSinceEpoch}-${RegExp(r'[0-9]').allMatches(DateTime.now().toString()).join().substring(0, 5)}';
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  // Mendaftarkan perangkat saat ini ke Firestore
  Future<void> registerCurrentDevice(String uid) async {
    try {
      final deviceId = await getOrCreateDeviceId();
      String osName = "Unknown Device";
      if (Platform.isAndroid) osName = "Android Device";
      if (Platform.isIOS) osName = "iOS Device";
      if (Platform.isMacOS) osName = "Mac Device";
      if (Platform.isWindows) osName = "Windows PC";
      if (Platform.isLinux) osName = "Linux PC";

      final osVersion = Platform.operatingSystemVersion;

      String modelName = "Unknown Model";
      try {
        modelName = Platform.localHostname;
      } catch (e) {
        modelName = "Unknown Model";
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceId)
          .set({
        'id': deviceId,
        'deviceName': osName,
        'osVersion': osVersion,
        'lastActive': FieldValue.serverTimestamp(),
        'model': modelName,
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error registering device: $e");
    }
  }

  // Menghapus perangkat dari Firestore (Logout perangkat tertentu)
  Future<void> removeDevice(String uid, String deviceId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceId)
          .delete();
    } catch (e) {
      print("Error removing device: $e");
    }
  }

  // Mengambil stream perangkat aktif milik user
  Stream<List<Map<String, dynamic>>> getActiveDevicesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .orderBy('lastActive', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Listen status perangkat saat ini (untuk auto-logout jika admin/user menghapus sesi)
  Stream<bool> listenToCurrentDeviceStatus(String uid) async* {
    final deviceId = await getOrCreateDeviceId();
    yield* _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
