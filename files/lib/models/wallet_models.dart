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

class BankAccount {
  final String id;
  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String iban;
  final String branch;
  final String instructions;
  final bool isActive;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    required this.iban,
    required this.branch,
    required this.instructions,
    required this.isActive,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['_id'] ?? json['id'] ?? '',
      bankName: json['bankName'] ?? '',
      accountHolder: json['accountHolder'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      iban: json['iban'] ?? '',
      branch: json['branch'] ?? '',
      instructions: json['instructions'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'accountHolder': accountHolder,
      'accountNumber': accountNumber,
      'iban': iban,
      'branch': branch,
      'instructions': instructions,
      'isActive': isActive,
    };
  }
}

class BankAccountsResponse {
  final List<BankAccount> accounts;

  BankAccountsResponse({required this.accounts});

  factory BankAccountsResponse.fromJson(Map<String, dynamic> json) {
    return BankAccountsResponse(
      accounts: (json['accounts'] as List<dynamic>?)
              ?.map((e) => BankAccount.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AttachmentData {
  final String url;
  final String publicId;

  AttachmentData({
    required this.url,
    required this.publicId,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
    };
  }

  factory AttachmentData.fromJson(Map<String, dynamic> json) {
    return AttachmentData(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
    );
  }
}

class DepositRequest {
  final double amount;
  final String method; // 'bank_transfer'
  final String bankAccountId;
  final AttachmentData attachment;

  DepositRequest({
    required this.amount,
    required this.method,
    required this.bankAccountId,
    required this.attachment,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': method,
      'bankAccountId': bankAccountId,
      'attachment': attachment.toJson(),
    };
  }
}

class DepositResponse {
  final bool success;
  final String message;
  final WalletTransaction transaction;

  DepositResponse({
    required this.success,
    required this.message,
    required this.transaction,
  });

  factory DepositResponse.fromJson(Map<String, dynamic> json) {
    return DepositResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      transaction: WalletTransaction.fromJson(json['transaction'] ?? {}),
    );
  }
}

class WithdrawRequest {
  final double amount;
  final String method; // 'bank_transfer'
  final String details;

  WithdrawRequest({
    required this.amount,
    required this.method,
    required this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'method': method,
      'details': details,
    };
  }
}

class WithdrawResponse {
  final bool success;
  final String message;
  final WalletTransaction transaction;
  final double newBalance;

  WithdrawResponse({
    required this.success,
    required this.message,
    required this.transaction,
    required this.newBalance,
  });

  factory WithdrawResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      transaction: WalletTransaction.fromJson(json['transaction'] ?? {}),
      newBalance: (json['newBalance'] ?? 0).toDouble(),
    );
  }
}

