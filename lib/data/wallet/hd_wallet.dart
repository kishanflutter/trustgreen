import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
// The bip39 1.0.6 package does not re-export its English wordlist
// through the top-level library, so we reach in directly. Pinned in
// pubspec.lock; any future bump that exports the list properly is
// strictly compatible.
// ignore: implementation_imports
import 'package:bip39/src/wordlists/english.dart' show WORDLIST;
import 'package:web3dart/credentials.dart';

import '../auth/crypto_utils.dart';

/// Allowed mnemonic word counts per BIP-39 §4. The Expo source uses
/// 12 by default; the Flutter rebuild supports the full triplet.
enum MnemonicLength {
  words12(12, 128),
  words18(18, 192),
  words24(24, 256);

  const MnemonicLength(this.wordCount, this.entropyBits);

  final int wordCount;
  final int entropyBits;

  static MnemonicLength fromWordCount(int n) {
    for (final v in MnemonicLength.values) {
      if (v.wordCount == n) return v;
    }
    throw ArgumentError('Unsupported mnemonic word count: $n');
  }

  static MnemonicLength? tryFromWordCount(int n) {
    for (final v in MnemonicLength.values) {
      if (v.wordCount == n) return v;
    }
    return null;
  }
}

/// BIP-39 + BIP-32 HD wallet helper. Mirrors the behaviour of
/// `lib/wallet-storage.ts` in the Expo source.
class HdWallet {
  HdWallet._({required this.mnemonic, required this.length});

  /// Default EVM derivation path (`m / 44' / 60' / 0' / 0 / 0`) — the
  /// path used by MetaMask, Trust Wallet, and the Expo source.
  static const String defaultEvmPath = "m/44'/60'/0'/0/0";

  final String mnemonic;
  final MnemonicLength length;

  /// Generates a fresh wallet with the requested word count.
  factory HdWallet.generate({MnemonicLength length = MnemonicLength.words12}) {
    final words = bip39.generateMnemonic(strength: length.entropyBits);
    return HdWallet._(mnemonic: words, length: length);
  }

  /// Restores a wallet from an existing mnemonic. Throws
  /// [FormatException] if the phrase is not a valid BIP-39 mnemonic
  /// of a supported length.
  factory HdWallet.fromMnemonic(String mnemonic) {
    final cleaned = normaliseMnemonic(mnemonic);
    if (!bip39.validateMnemonic(cleaned)) {
      throw const FormatException(
        'Invalid BIP-39 mnemonic — checksum or wordlist mismatch.',
      );
    }
    final wordCount = cleaned.split(' ').length;
    final length = MnemonicLength.tryFromWordCount(wordCount);
    if (length == null) {
      throw FormatException(
        'Unsupported mnemonic word count: $wordCount. Allowed: 12, 18, 24.',
      );
    }
    return HdWallet._(mnemonic: cleaned, length: length);
  }

  /// `true` iff the trimmed, normalised mnemonic passes BIP-39
  /// validation. Word-by-word checks happen in
  /// [validateAgainstWordlist] for the import screen's live feedback.
  static bool isValid(String mnemonic) {
    try {
      return bip39.validateMnemonic(normaliseMnemonic(mnemonic));
    } catch (_) {
      return false;
    }
  }

  /// Live-typing helper for the import screen. Returns a per-word
  /// validity list. Words not present in the BIP-39 English wordlist
  /// are flagged `false`. Empty input → empty list.
  static List<bool> validateAgainstWordlist(String input) {
    final words = normaliseMnemonic(input).split(' ').where((w) => w.isNotEmpty);
    final result = <bool>[];
    for (final w in words) {
      result.add(_englishWordSet.contains(w));
    }
    return result;
  }

  /// Lazy memoised set of the BIP-39 English wordlist (`O(1)` lookup).
  static final Set<String> _englishWordSet = WORDLIST.toSet().cast<String>();

  /// BIP-39 English wordlist as a list (preserves position-based
  /// ordering used by the verify-seed screen for distractor picks).
  static List<String> get englishWordlist =>
      List<String>.unmodifiable(WORDLIST.cast<String>());

  /// Words in the mnemonic.
  List<String> get words => mnemonic.split(' ');

  /// Lowercases, trims, and collapses whitespace runs.
  static String normaliseMnemonic(String input) =>
      input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Derives the private key bytes for [path]. Defaults to the EVM
  /// account 0 / change 0 / index 0 path used by every reference
  /// wallet.
  Uint8List privateKey({String path = defaultEvmPath}) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath(path);
    final pk = child.privateKey;
    if (pk == null) {
      throw StateError('Failed to derive private key at $path');
    }
    return pk;
  }

  /// EIP-55 checksummed EVM address (`0xAbC…`) for [path].
  String evmAddress({String path = defaultEvmPath}) {
    final pk = privateKey(path: path);
    final eth = EthPrivateKey.fromHex(CryptoUtils.toHex(pk));
    return eth.address.hexEip55;
  }
}
