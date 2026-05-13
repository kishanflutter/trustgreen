import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env/app_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait-only (§2.1.10 of the rebuild spec).
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  // Edge-to-edge dark system chrome.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Load .env. Missing file is non-fatal for first-launch DX — falls
  // back to defaults baked into AppEnv.
  try {
    await AppEnv.load();
  } catch (_) {
    // The .env asset is registered in pubspec.yaml; if it's missing
    // we still want the app to render with sane defaults.
  }

  runApp(const ProviderScope(child: TrustGreenApp()));
}
