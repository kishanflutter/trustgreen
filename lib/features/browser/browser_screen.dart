import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class BrowserScreen extends StatelessWidget {
  const BrowserScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Browser',
        description:
            'In-app browser (webview_flutter) with a URL bar, history, '
            'and safe-area handling (Phase 4).',
      );
}
