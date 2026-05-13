import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../state/providers.dart';
import 'boot_screen.dart';

/// Resolves the first destination once secure-storage reads finish.
/// Mirrors `app/index.tsx` from the Expo source:
///
/// 1. No PIN  → `/auth/pin`
/// 2. No wallets → `/auth/create-import`
/// 3. PIN set, locked → `/auth/pin?mode=unlock`
/// 4. Otherwise → `/wallet`
class BootController extends ConsumerStatefulWidget {
  const BootController({super.key});

  @override
  ConsumerState<BootController> createState() => _BootControllerState();
}

class _BootControllerState extends ConsumerState<BootController> {
  bool _decided = false;

  @override
  Widget build(BuildContext context) {
    final hasPinAsync = ref.watch(hasPinProvider);
    final hasWalletAsync = ref.watch(hasAnyWalletProvider);
    final session = ref.watch(sessionProvider);

    if (!_decided && hasPinAsync.hasValue && hasWalletAsync.hasValue) {
      final pinExists = hasPinAsync.value!;
      final walletsExist = hasWalletAsync.value!;
      _decided = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!pinExists) {
          context.go(RoutePaths.pin);
        } else if (!walletsExist) {
          context.go(RoutePaths.createImport);
        } else if (!session.unlocked) {
          context.go('${RoutePaths.pin}?mode=unlock');
        } else {
          context.go(RoutePaths.wallet);
        }
      });
    }

    return const BootScreen();
  }
}
