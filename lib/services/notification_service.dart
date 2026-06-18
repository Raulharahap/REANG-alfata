import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// PENTING: Fungsi ini HARUS berada di luar kelas (top-level)
// Ini adalah "penjaga" yang berjalan saat aplikasi Anda mati/ditutup.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Pastikan Firebase diinisialisasi
  await Firebase.initializeApp();
  debugPrint("Notifikasi background diterima: ${message.notification?.title}");
  // Di sini kita tidak perlu menampilkan notifikasi lokal
  // karena FCM akan menampilkannya secara otomatis saat app ditutup.
}

class NotificationService {
  // Buat instance singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Kunci global untuk navigasi
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Inisialisasi Notifikasi Lokal (untuk menampilkan notif saat app terbuka)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
          '@drawable/notification_icon',
        ); // Icon yang kita buat tadi
    // (Tambahkan iOS/macOS settings jika perlu)
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle klik notifikasi LOKAL (saat app terbuka)
        _handleNotificationClick(response.payload);
      },
    );

    // 2. Buat Channel Notifikasi (WAJIB untuk Android 8.0+)
    await _createNotificationChannel();

    // 3. Inisialisasi Firebase Messaging
    // Minta izin (untuk iOS & Web, Android 13+)
    await _firebaseMessaging.requestPermission();

    // 4. Setup Listener untuk Notifikasi FOREGROUND (saat app terbuka)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notifikasi FOREGROUND diterima!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        // Tampilkan notifikasi LOKAL
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // ID channel (harus sama)
              'Notifikasi Penting',
              channelDescription: 'Channel untuk notifikasi penting.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/notification_icon',
            ),
          ),
          payload: message.data['sender_id'], // Kirim data 'sender_id'
        );
      }
    });

    // 5. Setup Handler untuk klik notifikasi BACKGROUND/TERMINATED
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Juga cek jika aplikasi dibuka dari notifikasi yang sudah mati
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data['sender_id']);
    }

    // Handler untuk saat app di background tapi tidak mati, lalu user klik notif
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data['sender_id']);
    });
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // ID
      'Notifikasi Penting', // Judul
      description: 'Channel untuk notifikasi penting.', // Deskripsi
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // --- FUNGSI INTI: APA YANG TERJADI SAAT NOTIF DI-KLIK ---
  void _handleNotificationClick(String? payload) {
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Notifikasi diklik! Membawa data: $payload');
      // Di sini kita bisa navigasi ke halaman chat
      // (Kita akan implementasi ini di langkah selanjutnya setelah semuanya berjalan)
      // Contoh: navigatorKey.currentState?.pushNamed('/chat', arguments: payload);
    }
  }
}
