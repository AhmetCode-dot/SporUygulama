import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/notification_preferences.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Timezone initialize
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      // Local notifications initialization
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // FCM permissions
      await _requestPermissions();

      // FCM token al ve kaydet
      await _saveFCMToken();

      // FCM message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

      _initialized = true;
    } catch (e) {
      print('Notification initialization error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional notification permission');
    } else {
      print('User declined or has not accepted notification permission');
    }
  }

  Future<void> _saveFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        // Token'ı Firestore'da sakla (kullanıcı ID'si ile)
        // Şimdilik token'ı sadece alıyoruz, ileride user_notification_tokens koleksiyonuna kaydedebiliriz
        print('FCM Token: $token');
      }
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Uygulama açıkken bildirim geldiğinde
    _showLocalNotification(
      title: message.notification?.title ?? 'Bildirim',
      body: message.notification?.body ?? '',
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Uygulama arka plandayken bildirim tıklandığında
    print('Background message: ${message.messageId}');
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Bildirim tıklandığında
    print('Notification tapped: ${response.payload}');
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'workout_channel',
      'Antrenman Bildirimleri',
      channelDescription: 'Antrenman hatırlatıcıları ve bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Günlük hatırlatıcı zamanla
  Future<void> scheduleDailyReminder({
    required String userId,
    required String time, // "HH:mm" formatında
    required List<int> days, // 1-7 (Pazartesi-Pazar)
  }) async {
    try {
      // Önce mevcut bildirimleri iptal et
      await cancelAllNotifications();

      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      for (final day in days) {
        // Haftanın gününe göre tarih hesapla
        final now = tz.TZDateTime.now(tz.local);
        var scheduledDate = _getNextWeekday(now, day, hour, minute);

        // Eğer bugün o günse ve saat geçtiyse, gelecek haftaya al
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }

        const androidDetails = AndroidNotificationDetails(
          'workout_channel',
          'Antrenman Bildirimleri',
          channelDescription: 'Antrenman hatırlatıcıları',
          importance: Importance.high,
          priority: Priority.high,
        );

        const iosDetails = DarwinNotificationDetails();

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _localNotifications.zonedSchedule(
          day, // Unique ID
          'Antrenman Zamanı! 💪',
          'Bugün antrenman yapmayı unutma!',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } catch (e) {
      print('Error scheduling reminder: $e');
    }
  }

  tz.TZDateTime _getNextWeekday(
    tz.TZDateTime now,
    int weekday,
    int hour,
    int minute,
  ) {
    // weekday: 1=Pazartesi, 7=Pazar
    // Dart'ta weekday: 1=Pazartesi, 7=Pazar
    var daysUntilWeekday = weekday - now.weekday;
    if (daysUntilWeekday < 0) {
      daysUntilWeekday += 7;
    }

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: daysUntilWeekday));

    return scheduledDate;
  }

  // Streak uyarısı gönder
  Future<void> sendStreakWarning(String userId, int streak) async {
    await _showLocalNotification(
      title: 'Serin Tehlikede! 🔥',
      body: '$streak günlük serin bozulmasın! Bugün antrenman yapmayı unutma.',
      payload: 'streak_warning',
    );
  }

  // Haftalık özet gönder
  Future<void> sendWeeklySummary({
    required String userId,
    required int workouts,
    required int totalMinutes,
    required int streak,
  }) async {
    await _showLocalNotification(
      title: 'Haftalık Özet 📊',
      body: 'Bu hafta $workouts antrenman yaptın, toplam $totalMinutes dakika! Serin: $streak gün 🔥',
      payload: 'weekly_summary',
    );
  }

  // Rozet kazanma bildirimi
  Future<void> sendAchievementNotification({
    required String badgeName,
    required String badgeIcon,
  }) async {
    await _showLocalNotification(
      title: '$badgeIcon Rozet Kazandın!',
      body: '$badgeName rozetini kazandın!',
      payload: 'achievement',
    );
  }

  // Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Test bildirimi gönder (hemen)
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test Bildirimi ✅',
      body: 'Bildirimler çalışıyor! Bu bir test bildirimidir.',
      payload: 'test',
    );
  }

  // Kullanıcının bildirim tercihlerini kaydet
  Future<void> saveNotificationPreferences(
    String userId,
    NotificationPreferences preferences,
  ) async {
    try {
      await _firestore
          .collection('notification_preferences')
          .doc(userId)
          .set(preferences.toMap());

      // Eğer günlük hatırlatıcı açıksa, zamanla
      if (preferences.dailyRemindersEnabled &&
          preferences.reminderTime != null) {
        await scheduleDailyReminder(
          userId: userId,
          time: preferences.reminderTime!,
          days: preferences.reminderDays,
        );
      } else {
        await cancelAllNotifications();
      }
    } catch (e) {
      throw Exception('Bildirim tercihleri kaydedilemedi: ${e.toString()}');
    }
  }

  // Kullanıcının bildirim tercihlerini getir
  Future<NotificationPreferences?> getNotificationPreferences(
    String userId,
  ) async {
    try {
      final doc = await _firestore
          .collection('notification_preferences')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return NotificationPreferences.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Bildirim tercihleri yüklenemedi: ${e.toString()}');
    }
  }
}

