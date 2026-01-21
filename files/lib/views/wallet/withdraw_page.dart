import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/utils/responsive_utils.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet_models.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({Key? key}) : super(key: key);

  @override
  _WithdrawPageState createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _ibanController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isLoadingWallet = true;
  Wallet? _wallet;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountNameController.dispose();
    _ibanController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    if (!mounted) return;
    setState(() {
      _isLoadingWallet = true;
    });

    try {
      final response = await WalletService.getWallet();
      if (!mounted) return;
      setState(() {
        _wallet = response.wallet;
        _isLoadingWallet = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWallet = false;
      });
      Get.snackbar(
        'error'.tr,
        'failed_to_load_wallet'.tr,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
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

  Future<void> _submitWithdraw() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text);
    
    if (_wallet != null && amount > _wallet!.balance) {
      Get.snackbar(
        'error'.tr,
        'insufficient_balance'.tr,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final details = '''${'account_holder_name'.tr}: ${_accountNameController.text}
${'iban'.tr}: ${_ibanController.text}
${'account_number'.tr}: ${_accountNumberController.text}
${'bank_name'.tr}: ${_bankNameController.text}''';

      final request = WithdrawRequest(
        amount: amount,
        method: 'bank_transfer',
        details: details,
      );

      final response = await WalletService.withdrawFunds(request);

      Get.snackbar(
        'success'.tr,
        response.message,
        backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
        colorText: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
      );

      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          'withdraw_funds'.tr,
          style: AppFonts.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: Responsive.sp(18),
          ),
        ),
      ),
      body: _isLoadingWallet
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: Responsive.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBalanceCard(),
            SizedBox(height: Responsive.h(24)),
            _buildInfoCard(),
            SizedBox(height: Responsive.h(32)),
            _buildSectionTitle('withdrawal_amount'.tr),
            SizedBox(height: Responsive.h(12)),
            _buildAmountField(),
            SizedBox(height: Responsive.h(32)),
            _buildSectionTitle('bank_account_details'.tr),
            SizedBox(height: Responsive.h(4)),
            Text(
              'enter_bank_details_for_withdrawal'.tr,
              style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: Responsive.h(16)),
            _buildBankDetailsFields(),
            SizedBox(height: Responsive.h(40)),
            _buildSubmitButton(),
            SizedBox(height: Responsive.h(20)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppFonts.bodyMedium.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF0F172A),
        fontSize: Responsive.sp(15),
      ),
    );
  }

  Widget _buildBalanceCard() {
    if (_wallet == null) return const SizedBox();
    return Container(
      padding: Responsive.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
          Text(
            'available_balance'.tr,
            style: AppFonts.bodySmall.copyWith(color: Colors.white.withOpacity(0.7)),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            _formatCurrency(_wallet!.balance, _wallet!.currency),
            style: AppFonts.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.sp(28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        border: Border.all(color: AppColors.warning.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(IconlyBroken.info_square, color: AppColors.warning, size: Responsive.sp(22)),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Text(
              'withdraw_info_message'.tr,
              style: AppFonts.bodySmall.copyWith(color: AppColors.warning, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
      ),
      child: TextFormField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: AppFonts.h3.copyWith(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: const Icon(IconlyLight.send),
          hintText: 'enter_amount'.tr,
          hintStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textHint),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(16)), borderSide: BorderSide.none),
          contentPadding: Responsive.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'amount_required'.tr;
          final amount = double.tryParse(value);
          if (amount == null || amount <= 0) return 'invalid_amount'.tr;
          if (_wallet != null && amount > _wallet!.balance) return 'amount_exceeds_balance'.tr;
          return null;
        },
      ),
    );
  }

  Widget _buildBankDetailsFields() {
    return Column(
      children: [
        _buildTextField(_accountNameController, 'account_holder_name'.tr, IconlyLight.profile),
        SizedBox(height: Responsive.h(16)),
        _buildTextField(_bankNameController, 'bank_name'.tr, IconlyLight.category),
        SizedBox(height: Responsive.h(16)),
        _buildTextField(_ibanController, 'iban'.tr, IconlyLight.wallet),
        SizedBox(height: Responsive.h(16)),
        _buildTextField(_accountNumberController, 'account_number'.tr, IconlyLight.ticket, isNumeric: true),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: AppFonts.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(Responsive.r(16)), borderSide: BorderSide.none),
          contentPadding: Responsive.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) => value == null || value.isEmpty ? '$label ${'is_required'.tr}' : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: Responsive.h(56),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitWithdraw,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'submit_withdrawal_request'.tr,
                style: AppFonts.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
