import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/env/app_env.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/safe_scaffold.dart';

/// In-app WebView with a Chrome-style URL bar and a bottom nav
/// row (back / forward / refresh / open externally / home).
///
/// Use cases:
/// - browse a dApp without leaving the wallet
/// - open block-explorer / CoinGecko coin pages
/// - tap a news article (we still hand off the *first* deep-link
///   intent to the system browser for safety; this tab is for
///   intentional in-app browsing)
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  late final WebViewController _controller;
  final TextEditingController _urlBar = TextEditingController();

  double _progress = 0;
  bool _canBack = false;
  bool _canForward = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = AppEnv.browserHomeUrl;
    _urlBar.text = _currentUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _progress = p / 100);
          },
          onPageStarted: _refreshNavState,
          onPageFinished: (url) {
            _refreshNavState(url);
            if (!mounted) return;
            setState(() => _progress = 0);
          },
          onWebResourceError: (_) {},
        ),
      )
      ..loadRequest(Uri.parse(_currentUrl));
  }

  Future<void> _refreshNavState(String url) async {
    final back = await _controller.canGoBack();
    final forward = await _controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canBack = back;
      _canForward = forward;
      _currentUrl = url;
      _urlBar.text = url;
    });
  }

  @override
  void dispose() {
    _urlBar.dispose();
    super.dispose();
  }

  Future<void> _submit(String input) async {
    final url = _normalise(input);
    if (url == null) return;
    await _controller.loadRequest(Uri.parse(url));
  }

  /// Adds a scheme if missing; rejects strings that obviously aren't
  /// URLs and turns them into a Google search instead.
  String? _normalise(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.contains(' ') || !t.contains('.')) {
      return 'https://www.google.com/search?q=${Uri.encodeQueryComponent(t)}';
    }
    return 'https://$t';
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      title: 'Browser',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: _UrlBar(
              controller: _urlBar,
              onSubmit: _submit,
              onClear: () {
                _urlBar.clear();
              },
            ),
          ),
          if (_progress > 0 && _progress < 1)
            LinearProgressIndicator(
              value: _progress,
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: Colors.transparent,
            )
          else
            const SizedBox(height: 2),
          Expanded(child: WebViewWidget(controller: _controller)),
          SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  _NavButton(
                    icon: Icons.arrow_back_rounded,
                    enabled: _canBack,
                    onTap: () => _controller.goBack(),
                  ),
                  _NavButton(
                    icon: Icons.arrow_forward_rounded,
                    enabled: _canForward,
                    onTap: () => _controller.goForward(),
                  ),
                  _NavButton(
                    icon: Icons.refresh_rounded,
                    enabled: true,
                    onTap: () => _controller.reload(),
                  ),
                  _NavButton(
                    icon: Icons.home_rounded,
                    enabled: true,
                    onTap: () => _controller
                        .loadRequest(Uri.parse(AppEnv.browserHomeUrl)),
                  ),
                  _NavButton(
                    icon: Icons.open_in_new_rounded,
                    enabled: _currentUrl.isNotEmpty,
                    onTap: () async {
                      final uri = Uri.tryParse(_currentUrl);
                      if (uri == null) return;
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlBar extends StatelessWidget {
  const _UrlBar({
    required this.controller,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Icon(
              Icons.public_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: onSubmit,
              decoration: const InputDecoration(
                hintText: 'Search or enter URL',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IconButton(
        onPressed: enabled ? onTap : null,
        icon: Icon(
          icon,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
    );
  }
}
