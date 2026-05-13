import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/env/app_env.dart';
import 'state/chain_providers.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash on-screen while we run the rest of
  // initialisation; we hand off in `app.dart` on the first frame
  // of `BootScreen` so there is no flash between native and Flutter.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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

  // Hydrate the persisted "active chain" selection before mounting
  // the provider scope so the dashboard never flashes on the wrong
  // network on cold start.
  final prefs = await SharedPreferences.getInstance();
  final activeChainId = await loadInitialActiveChainId();

  runApp(
    ProviderScope(
      overrides: [
        activeChainControllerProvider.overrideWith(
          (ref) => ActiveChainController(prefs, activeChainId),
        ),
      ],
      child: const TrustGreenApp(),
    ),
  );
}
