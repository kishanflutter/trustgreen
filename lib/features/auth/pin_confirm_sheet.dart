import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../data/auth/pin_service.dart';
import '../../shared/widgets/numeric_pad.dart';
import '../../shared/widgets/pin_boxes.dart';
import '../../state/providers.dart';

/// Modal bottom sheet that asks the user to re-enter their PIN
/// before a destructive / signing operation (e.g. broadcasting a
/// transaction).
///
/// Returns the **plaintext PIN** on success so the caller can use
/// it to decrypt the wallet blob — never persisted by this widget.
/// Returns `null` if the user dismisses the sheet.
Future<String?> showPinConfirmSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.lg),
      ),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: PinConfirmSheet(title: title, subtitle: subtitle),
    ),
  );
}

/// Internal widget. Prefer calling [showPinConfirmSheet] from app
/// code; the class is only public so it can be unit-tested in
/// isolation.
class PinConfirmSheet extends ConsumerStatefulWidget {
  const PinConfirmSheet({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  ConsumerState<PinConfirmSheet> createState() => _PinConfirmSheetState();
}

class _PinConfirmSheetState extends ConsumerState<PinConfirmSheet> {
  static const int _pinLength = PinService.defaultPinLength;

  String _input = '';
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
      _verify();
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

  Future<void> _verify() async {
    setState(() => _busy = true);
    final entered = _input;
    try {
      final svc = ref.read(pinServiceProvider);
      final ok = await svc.verifyPin(entered);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(entered);
        return;
      }
      _attempts += 1;
      setState(() {
        _busy = false;
        _error = true;
        _errorText = _attempts >= 3
            ? 'Incorrect PIN ($_attempts attempts).'
            : 'Incorrect PIN. Try again.';
        _input = '';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = true;
        _errorText = 'Verification failed: $e';
        _input = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            PinBoxes(
              length: _pinLength,
              filled: _input.length,
              error: _error,
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 24,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _busy
                    ? Row(
                        key: const ValueKey('busy'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Verifying…',
                            style: TextStyle(
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
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          )),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            NumericPad(
              enabled: !_busy,
              onDigit: _onDigit,
              onBackspace: _onBackspace,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
