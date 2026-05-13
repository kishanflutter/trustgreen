import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

/// Edge-to-edge dark scaffold that:
///
/// * Uses [AppColors.bg] as the page background.
/// * Avoids the platform AppBar unless [title] is provided.
/// * Inserts a [SafeArea] so content never sits under the status bar
///   / Dynamic Island / home indicator (§2 of the rebuild spec).
class SafeScaffold extends StatelessWidget {
  const SafeScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.backgroundColor = AppColors.bg,
    this.bottom,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color backgroundColor;
  final Widget? bottom;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              leading: leading,
              actions: actions,
              centerTitle: false,
            ),
      body: SafeArea(
        top: title == null,
        bottom: bottom == null,
        child: body,
      ),
      bottomNavigationBar: bottom,
    );
  }
}
