class Wallet {
  final double balance;
  final String currency;

  Wallet({
    required this.balance,
    required this.currency,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': balance,
      'currency': currency,
    };
  }
}

class WalletTransaction {
  final String id;
  final String type; // 'credit' or 'debit'
  final double amount;
  final String description;
  final DateTime date;
  final String status;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.status,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      status: json['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}

class WalletResponse {
  final Wallet wallet;
  final List<WalletTransaction> transactions;

  WalletResponse({
    required this.wallet,
    required this.transactions,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    print('💰 [WALLET MODEL] Parsing wallet response from JSON:');
    print('💰 [WALLET MODEL] JSON keys: ${json.keys.toList()}');
    print('💰 [WALLET MODEL] wallet: ${json['wallet']}');
    print('💰 [WALLET MODEL] transactions: ${json['transactions']}');
    
    final wallet = Wallet.fromJson(json['wallet'] ?? {});
    print('💰 [WALLET MODEL] Parsed wallet balance: ${wallet.balance}');
    print('💰 [WALLET MODEL] Parsed wallet currency: ${wallet.currency}');
    
    return WalletResponse(
      wallet: wallet,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => WalletTransaction.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ChargeWalletRequest {
  final double amount;
  final String paymentMethod; // 'credit_card' or 'bank_transfer'
  final String? description;

  ChargeWalletRequest({
    required this.amount,
    required this.paymentMethod,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
      if (description != null) 'description': description,
    };
  }
}

class ChargeWalletResponse {
  final String message;
  final WalletTransaction transaction;
  final double newBalance;

  ChargeWalletResponse({
    required this.message,
    required this.transaction,
    required this.newBalance,
  });

  factory ChargeWalletResponse.fromJson(Map<String, dynamic> json) {
    return ChargeWalletResponse(
      message: json['message'] ?? '',
      transaction: WalletTransaction.fromJson(json['transaction'] ?? {}),
      newBalance: (json['newBalance'] ?? 0).toDouble(),
    );
  }
}

