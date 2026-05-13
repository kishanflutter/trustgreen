import 'package:flutter/material.dart';

import '../../core/responsive/responsive.dart';
import '../../core/theme/tokens.dart';
import 'safe_scaffold.dart';

/// Generic centered placeholder used while screens are still being
/// implemented. Renders the title, description, and a "TODO" tag so
/// it's obvious in the running app which routes still need work.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.description,
    this.titleInAppBar = true,
    this.actions,
  });

  final String title;
  final String? description;
  final bool titleInAppBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      title: titleInAppBar ? title : null,
      actions: actions,
      body: Center(
        child: PrimaryColumn(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!titleInAppBar) ...[
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (description != null) ...[
                Text(
                  description!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadius.brSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'TODO — implementation pending',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
