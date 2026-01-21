import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/wallet_models.dart';
import 'user_storage_service.dart';
import 'auth_error_handler.dart';

class WalletException implements Exception {
  final String message;

  WalletException(this.message);

  @override
  String toString() => 'WalletException: $message';
}

class WalletService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get user wallet information
  static Future<WalletResponse> getWallet() async {
    try {
      print('💰 [WALLET] Getting wallet information...');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw WalletException('Authentication required');
      }

      final url = '$_baseUrl/me/wallet';
      final headers = ApiConstants.getAuthHeaders(token);

      print('💰 [WALLET] URL: $url');
      print('💰 [WALLET] Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('💰 [WALLET] Response status: ${response.statusCode}');
      print('💰 [WALLET] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('💰 [WALLET] ✅ Wallet retrieved successfully');
        return WalletResponse.fromJson(data);
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        // Handle unauthorized - logout and navigate to login
        await AuthErrorHandler.handleIfUnauthorized(response.statusCode);
        throw WalletException('Unauthorized access');
      } else if (response.statusCode == 404) {
        throw WalletException('User not found');
      } else {
        final errorData = jsonDecode(response.body);
        throw WalletException(errorData['message'] ?? 'Failed to get wallet');
      }
    } catch (e) {
      print('💰 [WALLET] ❌ Error: $e');
      if (e is WalletException) rethrow;
      throw WalletException('Failed to get wallet: $e');
    }
  }

  /// Charge wallet
  static Future<ChargeWalletResponse> chargeWallet(ChargeWalletRequest request) async {
    try {
      print('💰 [WALLET] Charging wallet...');
      print('💰 [WALLET] Amount: ${request.amount}');
      print('💰 [WALLET] Payment Method: ${request.paymentMethod}');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw WalletException('Authentication required');
      }

      final url = '$_baseUrl/me/wallet/charge';
      final headers = ApiConstants.getAuthHeaders(token);

      print('💰 [WALLET] URL: $url');
      print('💰 [WALLET] Request body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('💰 [WALLET] Response status: ${response.statusCode}');
      print('💰 [WALLET] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('💰 [WALLET] ✅ Wallet charged successfully');
        print('💰 [WALLET] New Balance: ${data['newBalance']}');
        return ChargeWalletResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw WalletException(errorData['message'] ?? 'Invalid amount');
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        // Handle unauthorized - logout and navigate to login
        await AuthErrorHandler.handleIfUnauthorized(response.statusCode);
        throw WalletException('Unauthorized access');
      } else {
        final errorData = jsonDecode(response.body);
        throw WalletException(errorData['message'] ?? 'Failed to charge wallet');
      }
    } catch (e) {
      print('💰 [WALLET] ❌ Error: $e');
      if (e is WalletException) rethrow;
      throw WalletException('Failed to charge wallet: $e');
    }
  }

  /// Get active bank accounts
  static Future<BankAccountsResponse> getBankAccounts() async {
    try {
      print('💰 [WALLET] Getting bank accounts...');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw WalletException('Authentication required');
      }

      final url = '$_baseUrl/bank-accounts';
      final headers = ApiConstants.getAuthHeaders(token);

      print('💰 [WALLET] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('💰 [WALLET] Response status: ${response.statusCode}');
      print('💰 [WALLET] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('💰 [WALLET] ✅ Bank accounts retrieved successfully');
        return BankAccountsResponse.fromJson(data);
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        await AuthErrorHandler.handleIfUnauthorized(response.statusCode);
        throw WalletException('Unauthorized access');
      } else {
        final errorData = jsonDecode(response.body);
        throw WalletException(errorData['message'] ?? 'Failed to get bank accounts');
      }
    } catch (e) {
      print('💰 [WALLET] ❌ Error: $e');
      if (e is WalletException) rethrow;
      throw WalletException('Failed to get bank accounts: $e');
    }
  }

  /// Deposit funds via bank transfer
  static Future<DepositResponse> depositFunds(DepositRequest request) async {
    try {
      print('💰 [WALLET] Depositing funds...');
      print('💰 [WALLET] Amount: ${request.amount}');
      print('💰 [WALLET] Method: ${request.method}');
      print('💰 [WALLET] Bank Account ID: ${request.bankAccountId}');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw WalletException('Authentication required');
      }

      final url = '$_baseUrl/me/wallet/deposit';
      final headers = ApiConstants.getAuthHeaders(token);

      print('💰 [WALLET] URL: $url');
      print('💰 [WALLET] Request body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('💰 [WALLET] Response status: ${response.statusCode}');
      print('💰 [WALLET] Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('💰 [WALLET] ✅ Deposit request submitted successfully');
        return DepositResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw WalletException(errorData['message'] ?? 'Invalid deposit request');
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        await AuthErrorHandler.handleIfUnauthorized(response.statusCode);
        throw WalletException('Unauthorized access');
      } else {
        final errorData = jsonDecode(response.body);
        throw WalletException(errorData['message'] ?? 'Failed to deposit funds');
      }
    } catch (e) {
      print('💰 [WALLET] ❌ Error: $e');
      if (e is WalletException) rethrow;
      throw WalletException('Failed to deposit funds: $e');
    }
  }

  /// Withdraw funds
  static Future<WithdrawResponse> withdrawFunds(WithdrawRequest request) async {
    try {
      print('💰 [WALLET] Withdrawing funds...');
      print('💰 [WALLET] Amount: ${request.amount}');
      print('💰 [WALLET] Method: ${request.method}');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw WalletException('Authentication required');
      }

      final url = '$_baseUrl/me/wallet/withdraw';
      final headers = ApiConstants.getAuthHeaders(token);

      print('💰 [WALLET] URL: $url');
      print('💰 [WALLET] Request body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('💰 [WALLET] Response status: ${response.statusCode}');
      print('💰 [WALLET] Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('💰 [WALLET] ✅ Withdrawal request submitted successfully');
        print('💰 [WALLET] New Balance: ${data['newBalance']}');
        return WithdrawResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw WalletException(errorData['message'] ?? 'Invalid withdrawal request');
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        await AuthErrorHandler.handleIfUnauthorized(response.statusCode);
        throw WalletException('Unauthorized access');
      } else {
        final errorData = jsonDecode(response.body);
        throw WalletException(errorData['message'] ?? 'Failed to withdraw funds');
      }
    } catch (e) {
      print('💰 [WALLET] ❌ Error: $e');
      if (e is WalletException) rethrow;
      throw WalletException('Failed to withdraw funds: $e');
    }
  }
}

