import 'dart:typed_data';

import 'package:web3dart/web3dart.dart';

/// Minimal ERC-20 ABI covering the four methods this app uses:
/// `balanceOf`, `decimals`, `symbol`, and `transfer`. Encoded as
/// JSON so it can be loaded by [ContractAbi.fromJson].
const String _erc20AbiJson = '''
[
  {
    "constant": true,
    "inputs": [{"name": "_owner", "type": "address"}],
    "name": "balanceOf",
    "outputs": [{"name": "balance", "type": "uint256"}],
    "type": "function",
    "stateMutability": "view"
  },
  {
    "constant": true,
    "inputs": [],
    "name": "decimals",
    "outputs": [{"name": "", "type": "uint8"}],
    "type": "function",
    "stateMutability": "view"
  },
  {
    "constant": true,
    "inputs": [],
    "name": "symbol",
    "outputs": [{"name": "", "type": "string"}],
    "type": "function",
    "stateMutability": "view"
  },
  {
    "constant": false,
    "inputs": [
      {"name": "_to", "type": "address"},
      {"name": "_value", "type": "uint256"}
    ],
    "name": "transfer",
    "outputs": [{"name": "", "type": "bool"}],
    "type": "function",
    "stateMutability": "nonpayable"
  }
]
''';

/// Wraps a deployed ERC-20 token contract. Stateless helpers that
/// only depend on a [Web3Client] passed at call time so callers can
/// reuse a single connection across token interactions.
class Erc20Contract {
  Erc20Contract(this.address)
      : _contract = DeployedContract(
          ContractAbi.fromJson(_erc20AbiJson, 'IERC20'),
          EthereumAddress.fromHex(address),
        );

  final String address;
  final DeployedContract _contract;

  DeployedContract get contract => _contract;

  ContractFunction get balanceOfFn => _contract.function('balanceOf');
  ContractFunction get decimalsFn => _contract.function('decimals');
  ContractFunction get symbolFn => _contract.function('symbol');
  ContractFunction get transferFn => _contract.function('transfer');

  /// Reads `balanceOf(owner)` and returns the raw uint256 value.
  /// Caller is responsible for scaling by the token's `decimals`.
  Future<BigInt> balanceOf(Web3Client client, String owner) async {
    final result = await client.call(
      contract: _contract,
      function: balanceOfFn,
      params: [EthereumAddress.fromHex(owner)],
    );
    final v = result.first;
    if (v is BigInt) return v;
    return BigInt.parse(v.toString());
  }

  Future<int> decimals(Web3Client client) async {
    final result = await client.call(
      contract: _contract,
      function: decimalsFn,
      params: const [],
    );
    final v = result.first;
    if (v is BigInt) return v.toInt();
    return int.parse(v.toString());
  }

  Future<String> symbol(Web3Client client) async {
    final result = await client.call(
      contract: _contract,
      function: symbolFn,
      params: const [],
    );
    return result.first.toString();
  }

  /// Encodes a `transfer(to, value)` call. Returns the raw calldata
  /// bytes — caller wires this into [Transaction.callContract] or a
  /// manually-built [Transaction] for signing.
  Uint8List encodeTransfer({
    required String to,
    required BigInt value,
  }) {
    return transferFn.encodeCall([
      EthereumAddress.fromHex(to),
      value,
    ]);
  }
}
