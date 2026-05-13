import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../data/auth/pin_service.dart';
import '../../shared/widgets/numeric_pad.dart';
import '../../shared/widgets/pin_boxes.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/onboarding_provider.dart';
import '../../state/providers.dart';

/// PIN entry screen. Two flavours, picked from `?mode=` query:
///
/// * `null`     — first-launch **setup** (enter → confirm → commit).
/// * `'unlock'` — returning user, verify against the stored hash.
class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key, this.mode});

  final String? mode;

  bool get isUnlock => mode == 'unlock';

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

enum _SetupStage { enter, confirm }

class _PinScreenState extends ConsumerState<PinScreen> {
  static const int _pinLength = PinService.defaultPinLength;

  String _input = '';
  String _firstEntry = '';
  _SetupStage _stage = _SetupStage.enter;
  bool _busy = false;
  bool _error = false;
  String? _errorText;
  int _attempts = 0;

  void _onDigit(int d) {
    if (_busy || _input.length >= _pinLength) return;
    setState(() {
      _input = '$_input$d';
      _error = false;
      _errorText = null;
    });
    if (_input.length == _pinLength) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_busy || _input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = false;
      _errorText = null;
    });
  }

  Future<void> _onPinComplete() async {
    if (widget.isUnlock) {
      await _handleUnlock();
    } else {
      await _handleSetup();
    }
  }

  Future<void> _handleSetup() async {
    if (_stage == _SetupStage.enter) {
      setState(() {
        _firstEntry = _input;
        _input = '';
        _stage = _SetupStage.confirm;
      });
      return;
    }
    // confirm
    if (_input != _firstEntry) {
      setState(() {
        _error = true;
        _errorText = 'PINs do not match. Try again.';
        _input = '';
        _firstEntry = '';
        _stage = _SetupStage.enter;
      });
      return;
    }

    setState(() => _busy = true);
    try {
      final pinService = ref.read(pinServiceProvider);
      await pinService.setPin(_firstEntry);
      ref.read(onboardingProvider.notifier).setPendingPin(_firstEntry);
      ref.invalidate(hasPinProvider);
      if (!mounted) return;
      context.go(RoutePaths.createImport);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = true;
        _errorText = 'Could not save PIN: $e';
        _input = '';
        _firstEntry = '';
        _stage = _SetupStage.enter;
      });
    }
  }

  Future<void> _handleUnlock() async {
    setState(() => _busy = true);
    final entered = _input;
    try {
      final pinService = ref.read(pinServiceProvider);
      final ok = await pinService.verifyPin(entered);
      if (!mounted) return;
      if (ok) {
        ref.read(sessionProvider.notifier).unlock();
        context.go(RoutePaths.wallet);
        return;
      }
      _attempts += 1;
      setState(() {
        _busy = false;
        _error = true;
        _errorText = _attempts >= 3
            ? 'Incorrect PIN ($_attempts attempts). Take a breath.'
            : 'Incorrect PIN. Try again.';
        _input = '';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = true;
        _errorText = 'Unlock failed: $e';
        _input = '';
      });
    }
  }

  void _backToFirstEntry() {
    setState(() {
      _input = '';
      _firstEntry = '';
      _stage = _SetupStage.enter;
      _error = false;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    final title = widget.isUnlock
        ? 'Welcome back'
        : (_stage == _SetupStage.enter
            ? 'Set your PIN'
            : 'Confirm your PIN');

    final subtitle = widget.isUnlock
        ? 'Enter your PIN to unlock Trust Green.'
        : (_stage == _SetupStage.enter
            ? 'Create a $_pinLength-digit PIN. You\'ll use it every '
                'time you reopen the app.'
            : 'Re-enter the same PIN to confirm.');

    return SafeScaffold(
      body: SafeArea(
        child: PrimaryColumn(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              SizedBox(height: responsive.font(48, maxScale: 1.2)),
              PinBoxes(
                length: _pinLength,
                filled: _input.length,
                error: _error,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 28,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _busy
                      ? Row(
                          key: const ValueKey('busy'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              widget.isUnlock
                                  ? 'Verifying…'
                                  : 'Securing your PIN…',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : (_errorText == null
                          ? const SizedBox.shrink()
                          : Text(
                              _errorText!,
                              key: ValueKey(_errorText),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            )),
                ),
              ),
              const Spacer(),
              NumericPad(
                enabled: !_busy,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
              const SizedBox(height: AppSpacing.md),
              if (!widget.isUnlock && _stage == _SetupStage.confirm && !_busy)
                TextButton(
                  onPressed: _backToFirstEntry,
                  child: const Text('Re-enter PIN'),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
