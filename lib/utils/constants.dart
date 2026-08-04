class AppConstants {
  static const String appName = 'Eternity';
  static const String appNameCN = '记忆永恒';
  static const String packageName = 'com.huiqin.eternity';

  // IAP Products
  static const String iapAppleProductId = 'eternity.unlock';
  static const String iapGoogleProductId = 'eternity-unlock';
  static const String iapPriceDisplay = '\$1.99';

  // Storage limits
  static const int maxTextLength = 10000;
  static const int maxImagesPerEntry = 10;
  static const int maxVideoSeconds = 3;
  static const int maxAudioSeconds = 300;
  static const int maxLocalStorageMB = 500;

  // Volcano Engine ASR (inactive - app stores voice locally, no transcription needed)
  static const String volcAppId = '';
  static const String volcAccessKeyId = '';
  static const String volcSecretAccessKey = '';
  static const String volcASRHost = 'openspeech.bytedance.com';
  static const String volcASRPath = '/api/v1/asr';

  // Push notification
  static const String notificationChannelId = 'eternity_daily';
  static const String notificationChannelName = 'Daily Memory Reminder';
  static const int defaultReminderHour = 20;
  static const int defaultReminderMinute = 0;

  // Universe
  static const int totalPlanets = 5000;
  static const double universeScale = 2.5;
  static const double minZoom = 0.3;
  static const double maxZoom = 5.0;

  // Languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'nl', 'name': 'Nederlands', 'flag': '🇳🇱'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'th', 'name': 'ไทย', 'flag': '🇹🇭'},
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    {'code': 'ms', 'name': 'Bahasa Melayu', 'flag': '🇲🇾'},
    {'code': 'fil', 'name': 'Filipino', 'flag': '🇵🇭'},
    {'code': 'pl', 'name': 'Polski', 'flag': '🇵🇱'},
    {'code': 'uk', 'name': 'Українська', 'flag': '🇺🇦'},
  ];

  // Privacy policy URL
  static const String privacyUrl = 'https://www.wnzgai.com/eternity-privacy';

  // Cloud storage tiers
  static const String cloudBasicProductId = 'eternity-cloud-basic';
  static const String cloudUnlimitedProductId = 'eternity-cloud-unlimited';
}
