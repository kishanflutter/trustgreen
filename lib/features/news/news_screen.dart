import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'News',
        description:
            'Crypto news list backed by the env-configured news API '
            '(Phase 4).',
      );
}
