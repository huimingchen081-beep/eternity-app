import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static List<String>? _greetings;
  static final Random _random = Random();
  static int _lastGreetingIndex = -1;

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    await _loadGreetings();
  }

  static Future<void> _loadGreetings() async {
    final jsonStr = await rootBundle.loadString('assets/greetings.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    _greetings = [];

    final greetings = data['greetings'] as Map<String, dynamic>;
    for (final category in greetings.keys) {
      final list = greetings[category] as List<dynamic>;
      for (final item in list) {
        _greetings!.add(item as String);
      }
    }
  }

  static String getTodayGreeting() {
    if (_greetings == null || _greetings!.isEmpty) {
      return '今天的你，值得被宇宙记住。';
    }
    int index;
    if (_greetings!.length <= 1) {
      index = 0;
    } else {
      do {
        index = _random.nextInt(_greetings!.length);
      } while (index == _lastGreetingIndex);
    }
    _lastGreetingIndex = index;
    return _greetings![index];
  }

  static Future<void> scheduleDailyGreeting({
    int hour = 20,
    int minute = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminder_enabled') ?? true;
    if (!enabled) return;

    await _plugin.cancelAll();

    const androidDetails = AndroidNotificationDetails(
      'eternity_daily',
      '每日记忆提醒',
      channelDescription: '每天一条暖心话语，提醒你记录生活',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final greeting = getTodayGreeting();

    await _plugin.periodicallyShow(
      0,
      '记忆永恒 ✨',
      greeting,
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'eternity_daily',
      '每日记忆提醒',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      999,
      '记忆永恒 ✨',
      getTodayGreeting(),
      details,
    );
  }

  static Future<void> toggleNotification(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    if (enabled) {
      final hour = prefs.getInt('reminder_hour') ?? 20;
      await scheduleDailyGreeting(hour: hour);
    } else {
      await _plugin.cancelAll();
    }
  }
}
