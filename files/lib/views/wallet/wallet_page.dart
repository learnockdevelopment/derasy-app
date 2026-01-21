import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/utils/responsive_utils.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet_models.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  bool _isLoading = true;
  String? _error;
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await WalletService.getWallet();
      if (!mounted) return;
      setState(() {
        _wallet = response.wallet;
        _transactions = response.transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatNumber(String number) {
    if (Get.locale?.languageCode == 'ar') {
      return number.replaceAllMapped(
        RegExp(r'\d'),
        (match) {
          const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
          final group = match.group(0);
          if (group == null) return '';
          return arabicNumerals[int.parse(group)];
        },
      );
    }
    return number;
  }

  String _formatCurrency(double amount, String currency) {
    final formattedAmount = amount.toStringAsFixed(2);
    if (Get.locale?.languageCode == 'ar') {
      final arabicAmount = _formatNumber(formattedAmount);
      String translatedCurrency = currency;
      if (currency.toUpperCase() == 'USD') {
        translatedCurrency = 'دولار';
      } else if (currency.toUpperCase() == 'EGP') {
        translatedCurrency = 'جنيه';
      } else if (currency.toUpperCase() == 'SAR') {
        translatedCurrency = 'ريال';
      }
      return '$arabicAmount $translatedCurrency';
    }
    return '$formattedAmount $currency';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'wallet_title'.tr,
          style: AppFonts.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: Responsive.sp(18),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(IconlyLight.swap),
            onPressed: _loadWallet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: Responsive.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconlyBroken.danger,
              size: Responsive.sp(64),
              color: AppColors.error.withOpacity(0.5),
            ),
            SizedBox(height: Responsive.h(16)),
            Text(
              'error_loading_wallet'.tr,
              style: AppFonts.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: Responsive.h(24)),
            ElevatedButton(
              onPressed: _loadWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: Responsive.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(12))),
              ),
              child: Text('try_again'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadWallet,
      color: const Color(0xFF0F172A),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Responsive.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            SizedBox(height: Responsive.h(24)),
            _buildActionButtons(),
            SizedBox(height: Responsive.h(32)),
            Text(
              'recent_transactions'.tr,
              style: AppFonts.h3.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.sp(18),
              ),
            ),
            SizedBox(height: Responsive.h(16)),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    if (_wallet == null) return const SizedBox();
    return Container(
      width: double.infinity,
      padding: Responsive.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'current_balance'.tr,
                style: AppFonts.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: Responsive.sp(14),
                ),
              ),
              Icon(IconlyBroken.wallet, color: Colors.white.withOpacity(0.5), size: Responsive.sp(24)),
            ],
          ),
          SizedBox(height: Responsive.h(12)),
          Text(
            _formatCurrency(_wallet!.balance, _wallet!.currency),
            style: AppFonts.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.sp(32),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'deposit'.tr,
            icon: IconlyBroken.plus,
            color: const Color(0xFF0F172A),
            onTap: () async {
              final result = await Get.toNamed(AppRoutes.walletDeposit);
              if (result == true) {
                _loadWallet();
              }
            },
          ),
        ),
        SizedBox(width: Responsive.w(16)),
        Expanded(
          child: _buildActionButton(
            label: 'withdraw'.tr,
            icon: IconlyBroken.arrow_up_2,
            color: Colors.white,
            isOutlined: true,
            onTap: () async {
              final result = await Get.toNamed(AppRoutes.walletWithdraw);
              if (result == true) {
                _loadWallet();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isOutlined ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(Responsive.r(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        child: Container(
          padding: Responsive.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            border: isOutlined ? Border.all(color: const Color(0xFF0F172A), width: 1.5) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isOutlined ? const Color(0xFF0F172A) : Colors.white, size: Responsive.sp(20)),
              SizedBox(width: Responsive.w(8)),
              Text(
                label,
                style: AppFonts.bodyMedium.copyWith(
                  color: isOutlined ? const Color(0xFF0F172A) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Container(
        padding: Responsive.all(40),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(Responsive.r(24)),
        ),
        child: Column(
          children: [
            Icon(
              IconlyBroken.document,
              size: Responsive.sp(64),
              color: AppColors.grey300,
            ),
            SizedBox(height: Responsive.h(16)),
            Text(
              'no_transactions'.tr,
              style: AppFonts.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(WalletTransaction transaction) {
    final isDeposit = transaction.type == 'deposit';
    final isPending = transaction.status == 'pending';
    
    return Container(
      margin: Responsive.only(bottom: 12),
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Container(
            padding: Responsive.all(12),
            decoration: BoxDecoration(
              color: isDeposit 
                  ? AppColors.primaryGreen.withOpacity(0.1) 
                  : AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Responsive.r(14)),
            ),
            child: Icon(
              isDeposit ? IconlyBroken.arrow_down_2 : IconlyBroken.arrow_up_2,
              color: isDeposit ? AppColors.primaryGreen : AppColors.error,
              size: Responsive.sp(20),
            ),
          ),
          SizedBox(width: Responsive.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: AppFonts.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(14),
                  ),
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  _formatDate(transaction.date),
                  style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDeposit ? '+' : '-'}${_formatCurrency(transaction.amount, "")}',
                style: AppFonts.bodyMedium.copyWith(
                  color: isDeposit ? AppColors.primaryGreen : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(15),
                ),
              ),
              if (isPending)
                Container(
                  margin: Responsive.only(top: 4),
                  padding: Responsive.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Responsive.r(6)),
                  ),
                  child: Text(
                    'pending'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontSize: Responsive.sp(9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today'.tr;
    } else if (difference.inDays == 1) {
      return 'yesterday'.tr;
    } else if (difference.inDays < 7) {
      return '${_formatNumber(difference.inDays.toString())} ${'days_ago'.tr}';
    } else {
      return '${_formatNumber(date.day.toString())}/${_formatNumber(date.month.toString())}/${_formatNumber(date.year.toString())}';
    }
  }
}
