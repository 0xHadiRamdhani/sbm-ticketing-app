import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized before accessing any Firebase service in background
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// The Android notification channel used for all ticket notifications.
  /// Must match the channel_id in showNotification() and in AndroidManifest meta-data.
  static const AndroidNotificationChannel _ticketChannel = AndroidNotificationChannel(
    'ticket_channel_id',         // id
    'Ticket Notifications',      // name
    description: 'Notifications for ticket updates and new incoming tickets',
    importance: Importance.max,  // Importance.max = heads-up + lock screen
    playSound: true,
    showBadge: true,
    enableLights: true,
    enableVibration: true,
  );

  Future<void> init() async {
    // ── Android: create the notification channel explicitly ──────────────
    // This must be done before showing any notification.
    // Without this, Android 8+ falls back to a default low-importance channel
    // and notifications will NOT appear on the lock screen.
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_ticketChannel);
    }

    // ── Plugin initialisation ────────────────────────────────────────────
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // TODO: navigate to the relevant ticket screen using response.payload
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // ── Android 13+ runtime permission request ───────────────────────────
    // POST_NOTIFICATIONS is a runtime permission from API 33 onward.
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // ── Firebase Cloud Messaging (FCM) ───────────────────────────────────
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request permission (critical on iOS; harmless on Android)
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Register background handler BEFORE any other FCM setup
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Show a local notification when an FCM message arrives in the foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          showNotification(
            id: message.notification.hashCode,
            title: message.notification!.title ?? 'Notifikasi Baru',
            body: message.notification!.body ?? '',
          );
        }
      });

      // Log the FCM token (save this to Firestore to enable server-side push)
      final String? token = await messaging.getToken();
      debugPrint("FCM Token: $token");
    } catch (e) {
      debugPrint("Error initializing FCM: $e");
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _ticketChannel.id,
      _ticketChannel.name,
      channelDescription: _ticketChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      // LOCK SCREEN: show full content on the lock screen
      visibility: NotificationVisibility.public,
      ticker: title,
      playSound: true,
      enableLights: true,
      enableVibration: true,
      showWhen: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }
}
