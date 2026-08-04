import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force fullscreen immersive dark mode
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF050510),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize notification service
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  try {
    final appState = AppState();
    await appState.init();

    // Schedule daily greeting notification
    try {
      await NotificationService.scheduleDailyGreeting(
        hour: await appState.getReminderHour(),
      );
    } catch (e) {
      debugPrint('Schedule daily notification failed: $e');
    }

    runApp(
      ChangeNotifierProvider.value(
        value: appState,
        child: const EternityApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('App init failed: $e\n$stack');
    final errorText = e.toString();
    final displayText = errorText.length > 200
        ? '${errorText.substring(0, 200)}...'
        : errorText;
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(
        backgroundColor: const Color(0xFF050510),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('初始化失败',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 8),
                Text(displayText,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
