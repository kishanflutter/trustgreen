import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

import '../chains/chain_config.dart';
import 'erc20.dart';

/// Lightweight raw balance result that keeps both the on-chain
/// integer and the chain-decimals it should be scaled by. Saves the
/// UI layer from re-resolving decimals.
class TokenAmount {
  const TokenAmount({required this.raw, required this.decimals});

  final BigInt raw;
  final int decimals;

  /// Returns the human-readable decimal string with at most
  /// [maxFraction] fractional digits. Trailing zeros are trimmed
  /// once enough precision is shown.
  String format({int maxFraction = 6}) {
    if (raw == BigInt.zero) return '0';
    final scale = BigInt.from(10).pow(decimals);
    final whole = raw ~/ scale;
    final remainder = raw % scale;
    if (remainder == BigInt.zero) return whole.toString();

    final remainderStr = remainder.toString().padLeft(decimals, '0');
    final fraction = remainderStr.length > maxFraction
        ? remainderStr.substring(0, maxFraction)
        : remainderStr;
    final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');
    if (trimmed.isEmpty) return whole.toString();
    return '$whole.$trimmed';
  }

  /// Returns the raw value cast to a `double` for USD math. This is
  /// lossy for very large balances but acceptable for portfolio
  /// totals shown to users (well within IEEE-754 precision for any
  /// realistic wallet).
  double toDoubleUnits() {
    if (raw == BigInt.zero) return 0;
    final scale = BigInt.from(10).pow(decimals);
    final whole = (raw ~/ scale).toDouble();
    final remainder = raw % scale;
    final remainderDouble = remainder.toDouble() / scale.toDouble();
    return whole + remainderDouble;
  }

  static final TokenAmount zeroNative =
      TokenAmount(raw: BigInt.zero, decimals: 18);

  /// Parses a user-typed decimal string (`"1.25"`, `"0.001"`) into a
  /// [TokenAmount] scaled by [decimals]. Returns `null` for invalid
  /// or out-of-range inputs.
  static TokenAmount? tryParseDecimal(String input, int decimals) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(trimmed)) return null;

    final parts = trimmed.split('.');
    final wholePart = parts[0];
    final fracPart = parts.length > 1 ? parts[1] : '';
    if (fracPart.length > decimals) return null;

    final paddedFrac = fracPart.padRight(decimals, '0');
    final combined = '$wholePart$paddedFrac';
    final raw = BigInt.tryParse(combined);
    if (raw == null) return null;
    return TokenAmount(raw: raw, decimals: decimals);
  }
}

/// Fee/gas snapshot used by the send-tx review screen.
class FeeQuote {
  const FeeQuote({
    required this.gasLimit,
    required this.gasPrice,
    required this.chainSymbol,
    required this.chainDecimals,
  });

  /// Gas units the transaction will consume.
  final BigInt gasLimit;

  /// Gas price (legacy / type-0) in wei.
  final EtherAmount gasPrice;

  final String chainSymbol;
  final int chainDecimals;

  /// Total fee in wei as a [BigInt].
  BigInt get totalWei => gasLimit * gasPrice.getInWei;

  TokenAmount get totalAmount =>
      TokenAmount(raw: totalWei, decimals: chainDecimals);
}

/// Per-chain [Web3Client] pool. Web3 RPC connections are heavy and
/// can hold an HTTP keep-alive socket — share one client per chain
/// across the app and dispose them on shutdown.
class RpcService {
  RpcService._();

  static final RpcService instance = RpcService._();

  final Map<String, Web3Client> _clients = {};
  final Map<String, http.Client> _httpClients = {};

  /// Returns the cached client for [chain] or creates a new one. The
  /// underlying [http.Client] is owned by this service.
  Web3Client clientFor(ChainDefinition chain) {
    return _clients.putIfAbsent(chain.id, () {
      final httpClient = http.Client();
      _httpClients[chain.id] = httpClient;
      return Web3Client(chain.rpcUrl, httpClient);
    });
  }

  /// Fetches the native coin balance for [address] on [chain].
  Future<TokenAmount> getNativeBalance({
    required ChainDefinition chain,
    required String address,
  }) async {
    final client = clientFor(chain);
    final balance = await client.getBalance(EthereumAddress.fromHex(address));
    return TokenAmount(
      raw: balance.getInWei,
      decimals: chain.decimals,
    );
  }

  /// Fetches the ERC-20 token balance for [address] on [chain].
  /// Uses the configured token decimals so we don't pay an extra RPC
  /// round-trip just to learn what we already know.
  Future<TokenAmount> getTokenBalance({
    required ChainDefinition chain,
    required String tokenAddress,
    required int tokenDecimals,
    required String address,
  }) async {
    final client = clientFor(chain);
    final token = Erc20Contract(tokenAddress);
    final raw = await token.balanceOf(client, address);
    return TokenAmount(raw: raw, decimals: tokenDecimals);
  }

  /// Returns the current legacy gas price advertised by the RPC.
  Future<EtherAmount> getGasPrice(ChainDefinition chain) {
    return clientFor(chain).getGasPrice();
  }

  /// Estimates gas usage for a transaction (native or contract call).
  /// Adds a safe `* 1.2` headroom and a `21_000` floor for native
  /// sends so chains with slightly variable cost don't get
  /// underestimated.
  Future<BigInt> estimateGas({
    required ChainDefinition chain,
    required String from,
    required String to,
    BigInt? value,
    List<int>? data,
  }) async {
    final client = clientFor(chain);
    try {
      final estimate = await client.estimateGas(
        sender: EthereumAddress.fromHex(from),
        to: EthereumAddress.fromHex(to),
        value: value == null ? null : EtherAmount.inWei(value),
        data: data == null ? null : Uint8List.fromList(data),
      );
      final withBuffer = (estimate * BigInt.from(120)) ~/ BigInt.from(100);
      final floor = data == null ? BigInt.from(21000) : BigInt.from(45000);
      return withBuffer < floor ? floor : withBuffer;
    } catch (_) {
      return data == null ? BigInt.from(21000) : BigInt.from(65000);
    }
  }

  /// Builds, signs and broadcasts a transaction. Returns the tx
  /// hash on success. Throws [RpcException] from web3dart on RPC
  /// errors so callers can branch on it.
  Future<String> sendTransaction({
    required ChainDefinition chain,
    required Credentials credentials,
    required Transaction tx,
  }) async {
    final client = clientFor(chain);
    return client.sendTransaction(
      credentials,
      tx,
      chainId: chain.chainId,
    );
  }

  /// Pings the RPC by reading `eth_blockNumber`. Useful for the
  /// dashboard pull-to-refresh / network-status indicator.
  Future<int> getBlockNumber(ChainDefinition chain) {
    return clientFor(chain).getBlockNumber();
  }

  /// Best-effort cleanup. Called from app shutdown / tests.
  Future<void> dispose() async {
    for (final c in _clients.values) {
      await c.dispose();
    }
    for (final h in _httpClients.values) {
      h.close();
    }
    _clients.clear();
    _httpClients.clear();
  }
}

