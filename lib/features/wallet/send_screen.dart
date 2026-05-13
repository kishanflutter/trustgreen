import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

import '../../core/responsive/responsive.dart';
import '../../core/routing/route_paths.dart';
import '../../core/theme/tokens.dart';
import '../../data/chains/chain_config.dart';
import '../../data/rpc/erc20.dart';
import '../../data/rpc/rpc_service.dart';
import '../../data/tx/send_pipeline.dart';
import '../../shared/widgets/chain_logo.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/safe_scaffold.dart';
import '../../state/balance_providers.dart';
import '../../state/chain_providers.dart';
import '../../state/wallet_providers.dart';
import '../auth/pin_confirm_sheet.dart';
import 'qr_scan_screen.dart';
import 'send_review_sheet.dart';

class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key, this.initialRecipient});

  /// Pre-fills the recipient field — used when entering Send from
  /// the QR scan tile (`/wallet/send?recipient=0x…`).
  final String? initialRecipient;

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  SendAsset _asset = SendAsset.native;
  final TextEditingController _recipient = TextEditingController();
  final TextEditingController _amount = TextEditingController();

  Timer? _feeDebouncer;
  FeeQuote? _feeQuote;
  String? _feeError;
  bool _feeLoading = false;

  bool _broadcasting = false;
  String? _broadcastError;

  @override
  void initState() {
    super.initState();
    _recipient.addListener(_onInputChanged);
    _amount.addListener(_onInputChanged);
    final pre = widget.initialRecipient;
    if (pre != null && pre.isNotEmpty) {
      _recipient.text = pre;
    }
  }

  @override
  void dispose() {
    _feeDebouncer?.cancel();
    _recipient.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    setState(() {
      _broadcastError = null;
    });
    _scheduleFeeEstimate();
  }

  bool get _recipientValid {
    final raw = _recipient.text.trim();
    if (!RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(raw)) return false;
    try {
      EthereumAddress.fromHex(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  ChainDefinition get _chain => ref.read(activeChainProvider);

  int get _assetDecimals => _asset == SendAsset.native
      ? _chain.decimals
      : _chain.usdt.decimals;

  String get _assetSymbol => _asset == SendAsset.native
      ? _chain.symbol
      : _chain.usdt.symbol;

  TokenAmount? get _parsedAmount =>
      TokenAmount.tryParseDecimal(_amount.text, _assetDecimals);

  void _scheduleFeeEstimate() {
    _feeDebouncer?.cancel();
    if (!_recipientValid || _parsedAmount == null) {
      setState(() {
        _feeQuote = null;
        _feeError = null;
        _feeLoading = false;
      });
      return;
    }
    _feeDebouncer = Timer(const Duration(milliseconds: 400), _estimateFee);
  }

  Future<void> _estimateFee() async {
    final wallet = ref.read(activeWalletProvider).valueOrNull;
    if (wallet == null) return;
    final chain = _chain;
    final amount = _parsedAmount;
    if (amount == null) return;

    setState(() {
      _feeLoading = true;
      _feeError = null;
    });

    try {
      final rpc = ref.read(rpcServiceProvider);
      final gasPrice = await rpc.getGasPrice(chain);

      BigInt gasLimit;
      if (_asset == SendAsset.native) {
        gasLimit = await rpc.estimateGas(
          chain: chain,
          from: wallet.addressEvm,
          to: _recipient.text.trim(),
          value: amount.raw,
        );
      } else {
        final token = Erc20Contract(chain.usdt.address);
        final data = token.encodeTransfer(
          to: _recipient.text.trim(),
          value: amount.raw,
        );
        gasLimit = await rpc.estimateGas(
          chain: chain,
          from: wallet.addressEvm,
          to: chain.usdt.address,
          data: data,
        );
      }

      if (!mounted) return;
      setState(() {
        _feeQuote = FeeQuote(
          gasLimit: gasLimit,
          gasPrice: gasPrice,
          chainSymbol: chain.symbol,
          chainDecimals: chain.decimals,
        );
        _feeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _feeError = 'Gas estimate failed: $e';
        _feeQuote = null;
        _feeLoading = false;
      });
    }
  }

  Future<void> _onMax() async {
    final native = ref.read(nativeBalanceProvider(BalanceKey(
      chainId: _chain.id,
      address: ref.read(activeWalletProvider).valueOrNull?.addressEvm ?? '',
    ))).valueOrNull;
    final usdt = ref.read(usdtBalanceProvider(BalanceKey(
      chainId: _chain.id,
      address: ref.read(activeWalletProvider).valueOrNull?.addressEvm ?? '',
    ))).valueOrNull;

    if (_asset == SendAsset.native) {
      if (native == null) return;
      // Reserve ~21000 * current gasPrice for the transfer itself.
      try {
        final gp = await ref.read(rpcServiceProvider).getGasPrice(_chain);
        final reserve = BigInt.from(21000) * gp.getInWei;
        final raw = native.raw - reserve;
        if (raw <= BigInt.zero) {
          _amount.text = '0';
          return;
        }
        final amount = TokenAmount(raw: raw, decimals: native.decimals);
        _amount.text = amount.format(maxFraction: 8);
      } catch (_) {
        _amount.text = native.format(maxFraction: 8);
      }
    } else {
      if (usdt == null) return;
      _amount.text = usdt.format(maxFraction: 6);
    }
  }

  Future<void> _onPaste() async {
    final clip = await Clipboard.getData('text/plain');
    final text = clip?.text?.trim();
    if (text == null || text.isEmpty) return;
    _recipient.text = text;
  }

  Future<void> _onScan() async {
    final scanned = await QrScanScreen.open(context);
    if (scanned == null || scanned.isEmpty) return;
    _recipient.text = scanned;
  }

  bool get _canContinue =>
      _recipientValid &&
      _parsedAmount != null &&
      _parsedAmount!.raw > BigInt.zero &&
      !_feeLoading &&
      !_broadcasting;

  Future<void> _onContinue() async {
    final wallet = ref.read(activeWalletProvider).valueOrNull;
    if (wallet == null) return;
    final amount = _parsedAmount!;

    final balanceKey =
        BalanceKey(chainId: _chain.id, address: wallet.addressEvm);
    final native = ref.read(nativeBalanceProvider(balanceKey)).valueOrNull;
    final usdt = ref.read(usdtBalanceProvider(balanceKey)).valueOrNull;

    final overBalance = _asset == SendAsset.native
        ? (native != null && amount.raw > native.raw)
        : (usdt != null && amount.raw > usdt.raw);

    if (overBalance) {
      setState(() {
        _broadcastError = 'Amount exceeds available balance.';
      });
      return;
    }

    // Pull final fee quote if we don't have one yet.
    if (_feeQuote == null) await _estimateFee();
    if (!mounted) return;
    final fee = _feeQuote;
    if (fee == null) return;

    final priceIds = <String>{
      if (_chain.coingeckoId != null) _chain.coingeckoId!,
      _chain.usdt.coingeckoId,
    }.toList();
    final prices = ref.read(usdPricesProvider(priceIds)).valueOrNull ??
        const <String, double>{};

    final confirmed = await showSendReviewSheet(
      context,
      from: wallet,
      chain: _chain,
      asset: _asset,
      to: _recipient.text.trim(),
      amount: amount,
      fee: fee,
      prices: prices,
    );
    if (!mounted || confirmed != true) return;

    final pin = await showPinConfirmSheet(
      context,
      title: 'Confirm with PIN',
      subtitle: 'Re-enter your PIN to sign this transaction.',
    );
    if (!mounted || pin == null) return;

    setState(() {
      _broadcasting = true;
      _broadcastError = null;
    });

    try {
      final pipeline = ref.read(txPipelineProvider);
      final result = await pipeline.signAndBroadcast(
        request: SendRequest(
          asset: _asset,
          chain: _chain,
          fromWallet: wallet,
          toAddress: _recipient.text.trim(),
          amountRaw: amount.raw,
        ),
        pin: pin,
      );

      if (!mounted) return;
      // Invalidate balances so the dashboard reflects the spend.
      invalidateAllBalances(ref);
      context.pushReplacement(
        '${RoutePaths.wallet}/tx-pending?hash=${result.txHash}',
      );
    } on SendException catch (e) {
      if (!mounted) return;
      setState(() {
        _broadcasting = false;
        _broadcastError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _broadcasting = false;
        _broadcastError = 'Unexpected error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chain = _chain;
    final wallet = ref.watch(activeWalletProvider).valueOrNull;

    final balanceKey = wallet == null
        ? null
        : BalanceKey(chainId: chain.id, address: wallet.addressEvm);

    final native = balanceKey == null
        ? null
        : ref.watch(nativeBalanceProvider(balanceKey)).valueOrNull;
    final usdt = balanceKey == null
        ? null
        : ref.watch(usdtBalanceProvider(balanceKey)).valueOrNull;

    final priceIds = <String>{
      if (chain.coingeckoId != null) chain.coingeckoId!,
      chain.usdt.coingeckoId,
    }.toList();
    final prices = ref.watch(usdPricesProvider(priceIds)).valueOrNull ??
        const <String, double>{};

    return SafeScaffold(
      title: 'Send',
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: ContentColumn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NetworkChip(chain: chain),
                const SizedBox(height: AppSpacing.lg),
                _AssetSegmentedSelector(
                  chain: chain,
                  selected: _asset,
                  onChanged: (a) {
                    setState(() {
                      _asset = a;
                      _amount.clear();
                      _feeQuote = null;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(label: 'Recipient'),
                const SizedBox(height: AppSpacing.xs),
                _RecipientField(
                  controller: _recipient,
                  onPaste: _onPaste,
                  onScan: _onScan,
                  isValid: _recipient.text.isEmpty || _recipientValid,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel(label: 'Amount'),
                const SizedBox(height: AppSpacing.xs),
                _AmountField(
                  controller: _amount,
                  symbol: _assetSymbol,
                  onMax: _onMax,
                  decimals: _assetDecimals,
                ),
                const SizedBox(height: AppSpacing.xs),
                _AmountFooter(
                  parsed: _parsedAmount,
                  asset: _asset,
                  chain: chain,
                  nativeBalance: native,
                  usdtBalance: usdt,
                  prices: prices,
                ),
                const SizedBox(height: AppSpacing.lg),
                _FeeCard(
                  quote: _feeQuote,
                  loading: _feeLoading,
                  error: _feeError,
                  chain: chain,
                  prices: prices,
                ),
                if (_broadcastError != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _broadcastError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: _broadcasting ? 'Broadcasting…' : 'Continue',
                  onPressed: _canContinue ? _onContinue : null,
                  loading: _broadcasting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({required this.chain});
  final ChainDefinition chain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ChainLogo(logoKey: chain.logoKey, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Network',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  chain.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSegmentedSelector extends StatelessWidget {
  const _AssetSegmentedSelector({
    required this.chain,
    required this.selected,
    required this.onChanged,
  });

  final ChainDefinition chain;
  final SendAsset selected;
  final ValueChanged<SendAsset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentChip(
              label: chain.symbol,
              isSelected: selected == SendAsset.native,
              onTap: () => onChanged(SendAsset.native),
            ),
          ),
          Expanded(
            child: _SegmentChip(
              label: chain.usdt.symbol,
              isSelected: selected == SendAsset.usdt,
              onTap: () => onChanged(SendAsset.usdt),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: AppRadius.brSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brSm,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
}

class _RecipientField extends StatelessWidget {
  const _RecipientField({
    required this.controller,
    required this.onPaste,
    required this.onScan,
    required this.isValid,
  });

  final TextEditingController controller;
  final Future<void> Function() onPaste;
  final Future<void> Function() onScan;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: isValid ? AppColors.border : AppColors.error,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                hintText: '0x…',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Paste',
            onPressed: onPaste,
            icon: const Icon(
              Icons.content_paste_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          IconButton(
            tooltip: 'Scan QR',
            onPressed: onScan,
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.symbol,
    required this.onMax,
    required this.decimals,
  });

  final TextEditingController controller;
  final String symbol;
  final VoidCallback onMax;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: Text(
              symbol,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onMax,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
              ),
            ),
            child: const Text('MAX'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }
}

class _AmountFooter extends StatelessWidget {
  const _AmountFooter({
    required this.parsed,
    required this.asset,
    required this.chain,
    required this.nativeBalance,
    required this.usdtBalance,
    required this.prices,
  });

  final TokenAmount? parsed;
  final SendAsset asset;
  final ChainDefinition chain;
  final TokenAmount? nativeBalance;
  final TokenAmount? usdtBalance;
  final Map<String, double> prices;

  @override
  Widget build(BuildContext context) {
    final priceId = asset == SendAsset.native
        ? chain.coingeckoId
        : chain.usdt.coingeckoId;
    final price = priceId == null ? null : prices[priceId];

    String usdText = '';
    if (parsed != null && price != null) {
      final usd = parsed!.toDoubleUnits() * price;
      usdText = '≈ \$${usd.toStringAsFixed(2)}';
    }

    final balance =
        asset == SendAsset.native ? nativeBalance : usdtBalance;
    final balanceText = balance == null
        ? 'Balance —'
        : 'Balance ${balance.format(maxFraction: 6)} '
            '${asset == SendAsset.native ? chain.symbol : chain.usdt.symbol}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              usdText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            balanceText,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  const _FeeCard({
    required this.quote,
    required this.loading,
    required this.error,
    required this.chain,
    required this.prices,
  });

  final FeeQuote? quote;
  final bool loading;
  final String? error;
  final ChainDefinition chain;
  final Map<String, double> prices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_gas_station_outlined,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text(
            'Network fee',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (loading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else if (error != null)
            const Text(
              'Estimate failed',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            )
          else if (quote == null)
            const Text(
              '—',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            _FeeText(quote: quote!, chain: chain, prices: prices),
        ],
      ),
    );
  }
}

class _FeeText extends StatelessWidget {
  const _FeeText({
    required this.quote,
    required this.chain,
    required this.prices,
  });

  final FeeQuote quote;
  final ChainDefinition chain;
  final Map<String, double> prices;

  @override
  Widget build(BuildContext context) {
    final nativeFee = quote.totalAmount.format(maxFraction: 6);
    final price = chain.coingeckoId == null
        ? null
        : prices[chain.coingeckoId];
    final usd = price == null
        ? ''
        : ' (~\$${(quote.totalAmount.toDoubleUnits() * price).toStringAsFixed(4)})';
    return Text(
      '$nativeFee ${chain.symbol}$usd',
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
