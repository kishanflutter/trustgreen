import 'package:web3dart/web3dart.dart';

import '../auth/crypto_utils.dart';
import '../chains/chain_config.dart';
import '../rpc/erc20.dart';
import '../rpc/rpc_service.dart';
import '../wallet/hd_wallet.dart';
import '../wallet/wallet_models.dart';
import '../wallet/wallet_repository.dart';

/// Which "asset" the user is moving in a Send flow.
enum SendAsset { native, usdt }

/// Immutable description of a transfer the user is about to sign.
/// Built by the Send screen, passed to [TxPipeline.signAndBroadcast].
class SendRequest {
  const SendRequest({
    required this.asset,
    required this.chain,
    required this.fromWallet,
    required this.toAddress,
    required this.amountRaw,
  });

  final SendAsset asset;
  final ChainDefinition chain;
  final WalletMeta fromWallet;

  /// EIP-55 / lowercase hex; the pipeline normalises both forms.
  final String toAddress;

  /// Amount in the asset's smallest unit (wei for native, USDT
  /// scaled by `chain.usdt.decimals`).
  final BigInt amountRaw;
}

class BroadcastResult {
  const BroadcastResult({required this.txHash, required this.chain});

  final String txHash;
  final ChainDefinition chain;

  String get explorerUrl => chain.txExplorerUrl(txHash);
}

/// Builds + signs + broadcasts a [SendRequest] using the user's
/// just-verified PIN to decrypt the wallet secret.
///
/// **All decrypted material (mnemonic, private key bytes) is local
/// to this method and discarded as soon as the broadcast completes
/// or fails.** Callers must not hold the PIN beyond the immediate
/// invocation.
class TxPipeline {
  TxPipeline({
    required WalletRepository walletRepo,
    required RpcService rpc,
  })  : _walletRepo = walletRepo,
        _rpc = rpc;

  final WalletRepository _walletRepo;
  final RpcService _rpc;

  Future<BroadcastResult> signAndBroadcast({
    required SendRequest request,
    required String pin,
  }) async {
    final secret = await _walletRepo.readSecret(
      walletId: request.fromWallet.id,
      pin: pin,
    );
    if (secret == null) {
      throw const SendException(
        'Could not decrypt wallet. Wrong PIN or storage corrupted.',
      );
    }

    // Derive private key from mnemonic. Stays in memory only for
    // the lifetime of this call.
    final hd = HdWallet.fromMnemonic(secret.mnemonic);
    final pkBytes = hd.privateKey(path: secret.derivationPath);
    final credentials = EthPrivateKey.fromHex(CryptoUtils.toHex(pkBytes));

    final tx = await _buildTransaction(request: request);

    try {
      final hash = await _rpc.sendTransaction(
        chain: request.chain,
        credentials: credentials,
        tx: tx,
      );
      return BroadcastResult(txHash: hash, chain: request.chain);
    } catch (e) {
      throw SendException('Could not broadcast transaction: $e');
    }
  }

  Future<Transaction> _buildTransaction({
    required SendRequest request,
  }) async {
    final to = EthereumAddress.fromHex(request.toAddress);

    if (request.asset == SendAsset.native) {
      return Transaction(
        to: to,
        value: EtherAmount.inWei(request.amountRaw),
      );
    }

    // ERC-20 transfer — build calldata, set value=0.
    final token = Erc20Contract(request.chain.usdt.address);
    final data = token.encodeTransfer(
      to: request.toAddress,
      value: request.amountRaw,
    );
    return Transaction(
      to: EthereumAddress.fromHex(request.chain.usdt.address),
      value: EtherAmount.zero(),
      data: data,
    );
  }
}

/// Surfaced to the UI as a single rendered error message.
class SendException implements Exception {
  const SendException(this.message);
  final String message;

  @override
  String toString() => message;
}
