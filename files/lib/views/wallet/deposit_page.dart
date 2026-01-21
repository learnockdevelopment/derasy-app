import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/utils/responsive_utils.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet_models.dart';

class DepositPage extends StatefulWidget {
  const DepositPage({Key? key}) : super(key: key);

  @override
  _DepositPageState createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  bool _isLoadingBankAccounts = true;
  bool _isSubmitting = false;
  String? _error;
  List<BankAccount> _bankAccounts = [];
  BankAccount? _selectedBankAccount;
  File? _receiptImage;
  String? _uploadedImageUrl;
  String? _uploadedImagePublicId;

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBankAccounts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingBankAccounts = true;
      _error = null;
    });

    try {
      final response = await WalletService.getBankAccounts();
      if (!mounted) return;
      setState(() {
        _bankAccounts = response.accounts;
        if (_bankAccounts.isNotEmpty) {
          _selectedBankAccount = _bankAccounts.first;
        }
        _isLoadingBankAccounts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingBankAccounts = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
        _uploadedImageUrl = 'https://placeholder.com/receipt.jpg';
        _uploadedImagePublicId = 'receipt_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_image'.tr,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
    }
  }

  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBankAccount == null) {
      Get.snackbar(
        'error'.tr,
        'select_bank_account'.tr,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
      return;
    }

    if (_receiptImage == null || _uploadedImageUrl == null) {
      Get.snackbar(
        'error'.tr,
        'upload_receipt_required'.tr,
        backgroundColor: AppColors.error.withOpacity(0.1),
        colorText: AppColors.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final request = DepositRequest(
        amount: amount,
        method: 'bank_transfer',
        bankAccountId: _selectedBankAccount!.id,
        attachment: AttachmentData(
          url: _uploadedImageUrl!,
          publicId: _uploadedImagePublicId!,
        ),
      );

      final response = await WalletService.depositFunds(request);

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
          'deposit_funds'.tr,
          style: AppFonts.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
            fontSize: Responsive.sp(18),
          ),
        ),
      ),
      body: _isLoadingBankAccounts
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : _error != null
              ? _buildErrorState()
              : _buildForm(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: Responsive.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyBroken.danger, size: Responsive.sp(64), color: AppColors.error.withOpacity(0.5)),
            SizedBox(height: Responsive.h(16)),
            Text('error_loading_bank_accounts'.tr, style: AppFonts.h3.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: Responsive.h(8)),
            Text(_error ?? '', textAlign: TextAlign.center, style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary)),
            SizedBox(height: Responsive.h(24)),
            ElevatedButton(
              onPressed: _loadBankAccounts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(12))),
              ),
              child: Text('try_again'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
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
            _buildInfoCard(),
            SizedBox(height: Responsive.h(24)),
            _buildSectionTitle('select_bank_account'.tr),
            SizedBox(height: Responsive.h(12)),
            _buildBankAccountSelector(),
            if (_selectedBankAccount != null) ...[
              SizedBox(height: Responsive.h(24)),
              _buildBankDetails(),
            ],
            SizedBox(height: Responsive.h(24)),
            _buildSectionTitle('deposit_amount'.tr),
            SizedBox(height: Responsive.h(12)),
            _buildAmountField(),
            SizedBox(height: Responsive.h(24)),
            _buildSectionTitle('upload_receipt'.tr),
            SizedBox(height: Responsive.h(12)),
            _buildReceiptUpload(),
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

  Widget _buildInfoCard() {
    return Container(
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(IconlyBroken.info_square, color: AppColors.primaryBlue, size: Responsive.sp(22)),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Text(
              'deposit_info_message'.tr,
              style: AppFonts.bodySmall.copyWith(color: AppColors.primaryBlue, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
      ),
      child: DropdownButtonFormField<BankAccount>(
        value: _selectedBankAccount,
        icon: const Icon(IconlyLight.arrow_down_2),
        decoration: InputDecoration(
          prefixIcon: const Icon(IconlyLight.category),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            borderSide: BorderSide.none,
          ),
          contentPadding: Responsive.symmetric(horizontal: 16, vertical: 16),
        ),
        items: _bankAccounts.map((account) {
          return DropdownMenuItem(
            value: account,
            child: Text(account.bankName, style: AppFonts.bodyMedium),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedBankAccount = value),
        validator: (value) => value == null ? 'bank_account_required'.tr : null,
      ),
    );
  }

  Widget _buildBankDetails() {
    if (_selectedBankAccount == null) return const SizedBox();
    return Container(
      padding: Responsive.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('bank_name'.tr, _selectedBankAccount!.bankName),
          _buildDetailRow('account_holder'.tr, _selectedBankAccount!.accountHolder),
          _buildDetailRow('account_number'.tr, _selectedBankAccount!.accountNumber),
          _buildDetailRow('iban'.tr, _selectedBankAccount!.iban),
          _buildDetailRow('branch'.tr, _selectedBankAccount!.branch),
          if (_selectedBankAccount!.instructions.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              _selectedBankAccount!.instructions,
              style: AppFonts.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: Responsive.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
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
          return null;
        },
      ),
    );
  }

  Widget _buildReceiptUpload() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(Responsive.r(20)),
      child: Container(
        height: Responsive.h(180),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(Responsive.r(20)),
          border: Border.all(
            color: _receiptImage != null ? AppColors.primaryGreen : AppColors.grey200,
            width: 1.5,
            style: _receiptImage != null ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: _receiptImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(Responsive.r(18)),
                child: Image.file(_receiptImage!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyBroken.image, size: Responsive.sp(48), color: AppColors.grey400),
                  SizedBox(height: Responsive.h(12)),
                  Text('tap_to_upload_receipt'.tr, style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ),
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
        onPressed: _isSubmitting ? null : _submitDeposit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'submit_deposit_request'.tr,
                style: AppFonts.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
