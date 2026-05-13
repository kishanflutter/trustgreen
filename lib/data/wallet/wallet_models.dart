import 'dart:convert';

import 'hd_wallet.dart';

/// Non-secret wallet metadata. Persisted as a JSON list under
/// `tg_wallets_index` so we can render the wallet picker without
/// requiring a PIN.
class WalletMeta {
  const WalletMeta({
    required this.id,
    required this.name,
    required this.addressEvm,
    required this.createdAt,
    required this.mnemonicWordCount,
    this.derivationPath = HdWallet.defaultEvmPath,
  });

  /// Stable identifier — used in storage keys.
  final String id;
  final String name;

  /// EIP-55 checksummed EVM address (`0xAbC…`).
  final String addressEvm;

  /// When the wallet was first created / imported.
  final DateTime createdAt;

  /// 12 / 18 / 24, recorded so the UI can label imports correctly.
  final int mnemonicWordCount;

  /// BIP-32 derivation path used for [addressEvm]. Always
  /// `m/44'/60'/0'/0/0` in Phase 2.
  final String derivationPath;

  WalletMeta copyWith({String? name}) => WalletMeta(
        id: id,
        name: name ?? this.name,
        addressEvm: addressEvm,
        createdAt: createdAt,
        mnemonicWordCount: mnemonicWordCount,
        derivationPath: derivationPath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'addressEvm': addressEvm,
        'createdAt': createdAt.toIso8601String(),
        'mnemonicWordCount': mnemonicWordCount,
        'derivationPath': derivationPath,
      };

  factory WalletMeta.fromJson(Map<String, dynamic> json) => WalletMeta(
        id: json['id'] as String,
        name: json['name'] as String,
        addressEvm: json['addressEvm'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        mnemonicWordCount: json['mnemonicWordCount'] as int? ?? 12,
        derivationPath: json['derivationPath'] as String? ??
            HdWallet.defaultEvmPath,
      );

  /// Always returns a **growable, mutable** list — callers
  /// (`WalletRepository.createWallet / delete / rename`) mutate it
  /// in place before writing back. Returning `const []` on the
  /// first-wallet case would throw `Cannot add to an unmodifiable
  /// list` from the repository.
  static List<WalletMeta> listFromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return <WalletMeta>[];
    final parsed = jsonDecode(raw);
    if (parsed is! List) return <WalletMeta>[];
    return parsed
        .whereType<Map<String, dynamic>>()
        .map(WalletMeta.fromJson)
        .toList(growable: true);
  }

  static String listToJsonString(List<WalletMeta> list) =>
      jsonEncode(list.map((w) => w.toJson()).toList());
}

/// Sensitive wallet payload. Never written to disk in plaintext —
/// always wrapped by [WalletCipher] before persisting.
class WalletSecret {
  const WalletSecret({
    required this.mnemonic,
    required this.mnemonicWordCount,
    this.derivationPath = HdWallet.defaultEvmPath,
  });

  final String mnemonic;
  final int mnemonicWordCount;
  final String derivationPath;

  Map<String, dynamic> toJson() => {
        'mnemonic': mnemonic,
        'mnemonicWordCount': mnemonicWordCount,
        'derivationPath': derivationPath,
      };

  factory WalletSecret.fromJson(Map<String, dynamic> json) => WalletSecret(
        mnemonic: json['mnemonic'] as String,
        mnemonicWordCount: json['mnemonicWordCount'] as int? ?? 12,
        derivationPath: json['derivationPath'] as String? ??
            HdWallet.defaultEvmPath,
      );

  String encodeJson() => jsonEncode(toJson());

  factory WalletSecret.decodeJson(String raw) =>
      WalletSecret.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
