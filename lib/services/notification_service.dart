import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );
  }

  /// Schedule daily reminder with warm language-specific message
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String language,
  }) async {
    await _plugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminder_enabled') ?? true;
    if (!enabled) return;

    final title = _getTitle(language);
    final body = _getBody(language);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: 'Daily memory recording reminder',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule repeating daily notification
    await _plugin.periodicallyShow(
      0, // id
      title,
      body,
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Show an instant notification (e.g., after purchasing)
  static Future<void> showInstant({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(1, title, body, details);
  }

  static String _getTitle(String lang) {
    switch (lang) {
      case 'zh':
        return '今天的星光，又亮了一颗 ✨';
      case 'ja':
        return '今日の星がまた一つ輝きます ✨';
      case 'ko':
        return '오늘의 별이 또 하나 빛납니다 ✨';
      case 'fr':
        return 'Une étoile brille encore aujourd\'hui ✨';
      case 'de':
        return 'Ein weiterer Stern leuchtet heute ✨';
      case 'es':
        return 'Otra estrella brilla hoy ✨';
      case 'pt':
        return 'Mais uma estrela brilha hoje ✨';
      case 'ru':
        return 'Ещё одна звезда сияет сегодня ✨';
      case 'ar':
        return 'نجم جديد يضيء اليوم ✨';
      case 'it':
        return 'Un\'altra stella brilla oggi ✨';
      default:
        return 'Another star lights up today ✨';
    }
  }

  static String _getBody(String lang) {
    final bodies = [
      'Record this moment and let it live forever in the universe.',
      '此刻的你，就是未来的回忆。点亮今天的星球吧。',
      '宇宙记得每一束光，就像永生记得你的每一天。',
      '今天的你，值得被永恒记住。',
      '每一个平凡的瞬间，都是宇宙中独一无二的星光。',
    ];

    switch (lang) {
      case 'zh':
        return bodies[3];
      case 'ja':
        return 'この瞬間を宇宙に刻もう。今日の星を灯してください。';
      case 'ko':
        return '이 순간을 우주에 새기세요. 오늘의 별을 밝혀주세요.';
      case 'fr':
        return 'Enregistrez ce moment pour qu\'il vive éternellement dans l\'univers.';
      case 'de':
        return 'Halte diesen Moment fest und lass ihn im Universum weiterleben.';
      case 'es':
        return 'Registra este momento y déjalo vivir para siempre en el universo.';
      case 'pt':
        return 'Registre este momento e deixe-o viver para sempre no universo.';
      case 'ru':
        return 'Запишите этот момент, и пусть он живёт вечно во вселенной.';
      case 'ar':
        return 'سجل هذه اللحظة ودعها تعيش إلى الأبد في الكون.';
      default:
        return bodies[0];
    }
  }
}
