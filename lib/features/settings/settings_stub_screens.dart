import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';

class ChainsSettingsScreen extends StatelessWidget {
  const ChainsSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Networks',
        description: 'Add, edit, and switch RPC endpoints per chain.',
      );
}

class WalletsSettingsScreen extends StatelessWidget {
  const WalletsSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Wallets',
        description: 'List of wallets with rename / remove / set-active.',
      );
}

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Security',
        description: 'Change PIN, auto-lock interval, biometrics toggle.',
      );
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Privacy',
        description: 'Analytics opt-out, screenshot blocking, etc.',
      );
}

class ExportSettingsScreen extends StatelessWidget {
  const ExportSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Export',
        description:
            'Reveal seed phrase / private key after PIN re-entry. '
            'Screen-capture blocked while sensitive data is visible.',
      );
}

class TransactionsSettingsScreen extends StatelessWidget {
  const TransactionsSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Transactions',
        description: 'Cross-chain transaction history with filters.',
      );
}

class PhonebookSettingsScreen extends StatelessWidget {
  const PhonebookSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Phonebook',
        description: 'Manage saved recipient addresses and labels.',
      );
}

class ContactSettingsScreen extends StatelessWidget {
  const ContactSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Contact us',
        description: 'Email and direct links to support.',
      );
}

class SupportSettingsScreen extends StatelessWidget {
  const SupportSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Support',
        description: 'Open a support ticket / knowledge base shortcuts.',
      );
}

class FaqSettingsScreen extends StatelessWidget {
  const FaqSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'FAQ',
        description: 'Frequently asked questions.',
      );
}

class SocialSettingsScreen extends StatelessWidget {
  const SocialSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
        title: 'Social',
        description: 'Telegram, X (Twitter), Discord links.',
      );
}
