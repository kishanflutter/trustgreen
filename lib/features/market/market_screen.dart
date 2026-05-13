import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Market',
        description:
            'CoinGecko-powered tickers and a price chart per featured '
            'token (Phase 4 — uses fl_chart).',
      );
}
