import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:medlistapp/utils/constants.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/models/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DatabaseService _dbService = DatabaseService();
  bool _initialized = false;

  // Initialize notification service
  Future<bool> initialize() async {
    if (_initialized) return true;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized ?? false) {
      // Create notification channels for Android
      await _createNotificationChannels();
      _initialized = true;
    }

    return initialized ?? false;
  }

  // Create notification channels (Android)
  Future<void> _createNotificationChannels() async {
    // Expiry alerts channel
    const expiryChannel = AndroidNotificationChannel(
      AppConstants.expiryAlertChannelId,
      AppConstants.expiryAlertChannelName,
      description: 'Notifications for medications expiring soon',
      importance: Importance.high,
      playSound: true,
    );

    // Low stock alerts channel
    const lowStockChannel = AndroidNotificationChannel(
      AppConstants.lowStockAlertChannelId,
      AppConstants.lowStockAlertChannelName,
      description: 'Notifications for low stock items',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // System alerts channel
    const systemChannel = AndroidNotificationChannel(
      AppConstants.systemAlertChannelId,
      AppConstants.systemAlertChannelName,
      description: 'System notifications and alerts',
      importance: Importance.defaultImportance,
      playSound: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(expiryChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(lowStockChannel);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(systemChannel);
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // Show expiry alert notification
  Future<void> showExpiryAlert({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryAlertsEnabled = prefs.getBool('expiry_alerts_enabled') ?? true;
    
    if (!expiryAlertsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.expiryAlertChannelId,
      AppConstants.expiryAlertChannelName,
      channelDescription: 'Notifications for medications expiring soon',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
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

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: data != null ? data.toString() : null,
    );

    // Save to database
    final notification = AppNotification(
      type: NotificationType.expiry,
      title: title,
      body: body,
      data: data,
      sentAt: DateTime.now(),
    );
    await _dbService.insertNotification(notification);
  }

  // Show low stock alert notification
  Future<void> showLowStockAlert({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lowStockAlertsEnabled = prefs.getBool('low_stock_alerts_enabled') ?? true;
    
    if (!lowStockAlertsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.lowStockAlertChannelId,
      AppConstants.lowStockAlertChannelName,
      channelDescription: 'Notifications for low stock items',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
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

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000 + 100000,
      title,
      body,
      details,
      payload: data != null ? data.toString() : null,
    );

    // Save to database
    final notification = AppNotification(
      type: NotificationType.lowStock,
      title: title,
      body: body,
      data: data,
      sentAt: DateTime.now(),
    );
    await _dbService.insertNotification(notification);
  }

  // Show system alert notification
  Future<void> showSystemAlert({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final systemAlertsEnabled = prefs.getBool('system_alerts_enabled') ?? true;
    
    if (!systemAlertsEnabled) return;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.systemAlertChannelId,
      AppConstants.systemAlertChannelName,
      channelDescription: 'System notifications and alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000 + 200000,
      title,
      body,
      details,
      payload: data != null ? data.toString() : null,
    );

    // Save to database
    final notification = AppNotification(
      type: NotificationType.system,
      title: title,
      body: body,
      data: data,
      sentAt: DateTime.now(),
    );
    await _dbService.insertNotification(notification);
  }

  /// Show a medication-related notification (e.g. contraindication found).
  Future<void> showMedicationAlert({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.systemAlertChannelId,
      AppConstants.systemAlertChannelName,
      channelDescription: 'Medication-related alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
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

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000 + 300000,
      title,
      body,
      details,
      payload: data != null ? data.toString() : null,
    );

    final notification = AppNotification(
      type: NotificationType.system,
      title: title,
      body: body,
      data: data,
      sentAt: DateTime.now(),
    );
    await _dbService.insertNotification(notification);
  }

  /// Get count of unread notifications.
  Future<int> getUnreadCount() async {
    try {
      return await _dbService.getUnreadNotificationCount();
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAllAsRead() async {
    await _dbService.markAllNotificationsAsRead();
  }

  Future<void> markAsReadByCategory(String category) async {
    await _dbService.markNotificationsAsReadByCategory(category);
  }

  Future<int> getUnreadCountByCategory(String category) async {
    try {
      return await _dbService.getUnreadCountByCategory(category);
    } catch (_) {
      return 0;
    }
  }

  Future<void> scheduleDailyCheck(DateTime scheduledTime) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.systemAlertChannelId,
      AppConstants.systemAlertChannelName,
      channelDescription: 'Daily check reminder',
      importance: Importance.low,
      priority: Priority.low,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      999999,
      'Daily Check',
      'Checking for expiring medications and low stock...',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific page
    // This will be handled by the app's navigation logic
  }

  // Get notification history
  Future<List<AppNotification>> getNotificationHistory({
    NotificationType? type,
    int? limit,
  }) async {
    if (type != null) {
      final notifications = await _dbService.getNotificationsByType(type);
      return limit != null ? notifications.take(limit).toList() : notifications;
    }
    final notifications = await _dbService.getAllNotifications();
    return limit != null ? notifications.take(limit).toList() : notifications;
  }
}

