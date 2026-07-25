import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
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

  // Initialize app state
  final appState = AppState();
  await appState.init();

  // Initialize notification service
  // await NotificationService.init();

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: const EternityApp(),
    ),
  );
}
