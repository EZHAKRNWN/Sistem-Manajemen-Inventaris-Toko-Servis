import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Helper pengelola notifikasi lokal perangkat (Local Push Notifications).
/// Fitur ini memenuhi kriteria projek PAM untuk sistem notifikasi offline tanpa dependensi Firebase.
/// Digunakan untuk memberikan alert ketika:
/// 1. Berhasil login ke sistem
/// 2. Tiket perbaikan selesai atau stok suku cadang menipis
/// 3. Sesi login kedaluwarsa (401 Unauthorized)
/// 4. Formulir saran & kesan berhasil tersimpan
class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi konfigurasi notifikasi untuk platform Android dan iOS
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );
  }

  /// Meminta izin notifikasi runtime ke sistem operasi (diperlukan pada Android 13+ dan iOS)
  Future<void> requestPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Menampilkan banner notifikasi lokal secara instan pada status bar perangkat
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'smartfix_alerts_channel',
          'SmartFix Inventory Alerts',
          channelDescription:
              'Notifications for stock alerts and repair status updates',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}
