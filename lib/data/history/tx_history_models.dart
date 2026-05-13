/// Direction of a transaction relative to the active wallet.
enum TxDirection { incoming, outgoing, selfSelf, contract }

/// Asset classification — used to pick the right amount formatter
/// and price-id when rendering the row.
enum TxAssetKind { native, erc20, unknown }

/// Normalised transaction model. Fields below are the **union** of
/// what we get out of Etherscan's `txlist` and `tokentx` endpoints.
class TxHistoryItem {
  const TxHistoryItem({
    required this.hash,
    required this.from,
    required this.to,
    required this.valueRaw,
    required this.timestamp,
    required this.success,
    required this.direction,
    required this.assetKind,
    required this.assetSymbol,
    required this.assetDecimals,
    this.tokenAddress,
    this.gasUsed,
    this.gasPriceWei,
    this.methodId,
  });

  /// 0x-prefixed transaction hash.
  final String hash;

  /// EIP-55 / lowercase hex; do not assume one or the other.
  final String from;
  final String to;

  /// Raw value in the asset's smallest unit (wei for native, base
  /// units for ERC-20).
  final BigInt valueRaw;

  final DateTime timestamp;
  final bool success;

  final TxDirection direction;
  final TxAssetKind assetKind;

  /// Display ticker — `'BNB'`, `'USDT'`, …
  final String assetSymbol;

  /// Decimals for the asset (18 for native EVM, 6/18 for USDT).
  final int assetDecimals;

  /// ERC-20 contract address (null for native).
  final String? tokenAddress;

  /// Gas used by the receipt (null if the explorer omits it).
  final BigInt? gasUsed;

  /// Effective gas price in wei (null if the explorer omits it).
  final BigInt? gasPriceWei;

  /// Optional method-id (`0x...`) for contract calls. Surfaced as a
  /// "Contract interaction" pill when present and assetKind is
  /// [TxAssetKind.native] with `valueRaw == 0`.
  final String? methodId;

  /// Total fee in wei (gasUsed × gasPriceWei) — null if either
  /// component is missing.
  BigInt? get feeWei {
    final g = gasUsed;
    final p = gasPriceWei;
    if (g == null || p == null) return null;
    return g * p;
  }

  /// Counterparty address: `to` for outgoing, `from` for incoming.
  String counterparty(String selfAddress) {
    final lower = selfAddress.toLowerCase();
    return from.toLowerCase() == lower ? to : from;
  }
}
