import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/store_models.dart';
import '../../services/store_service.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({Key? key}) : super(key: key);

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  bool _isLoading = true;
  List<StoreOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await StoreService.getOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConfigController.to.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textSecondary = isDark ? Colors.grey.shade400 : AppColors.textSecondary;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Responsive.isRTL ? IconlyLight.arrow_right : IconlyLight.arrow_left,
            color: textColor,
          ),
        ),
        title: Text(
          'order_history'.tr.isNotEmpty ? 'order_history'.tr : 'My Orders',
          style: AppFonts.AlmaraiBold18.copyWith(color: textColor),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.salesAccent))
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.folder, size: 54, color: textSecondary),
                      const SizedBox(height: 14),
                      Text(
                        'no_orders_found'.tr.isNotEmpty ? 'no_orders_found'.tr : 'No orders found',
                        style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: AppColors.salesAccent,
                  child: ListView.separated(
                    padding: Responsive.symmetric(horizontal: 24, vertical: 16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _orders.length,
                    separatorBuilder: (c, i) => SizedBox(height: Responsive.h(14)),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      
                      Color statusColor = AppColors.salesAccent;
                      if (order.status.toLowerCase().contains('pending')) {
                        statusColor = Colors.orange;
                      } else if (order.status.toLowerCase().contains('shipped') || order.status.toLowerCase().contains('deliver')) {
                        statusColor = Colors.green;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(Responsive.r(24)),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: Responsive.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${order.id}',
                                  style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                  ),
                                  child: Text(
                                    order.status.toUpperCase(),
                                    style: AppFonts.AlmaraiBold10.copyWith(color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'date'.tr.isNotEmpty ? 'date'.tr : 'Date',
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                                Text(
                                  order.createdAt.length >= 10 ? order.createdAt.substring(0, 10) : order.createdAt,
                                  style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'payment_method'.tr.isNotEmpty ? 'payment_method'.tr : 'Payment',
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                                Text(
                                  order.paymentMethod.toUpperCase(),
                                  style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'shipping_address'.tr.isNotEmpty ? 'shipping_address'.tr : 'Delivery Address',
                                  style: TextStyle(color: textSecondary, fontSize: 11),
                                ),
                                Text(
                                  order.shippingAddress.address,
                                  style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'total'.tr.isNotEmpty ? 'total'.tr : 'Total Amount',
                                  style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                                ),
                                Text(
                                  '${order.total.toInt()} EGP',
                                  style: AppFonts.AlmaraiBold16.copyWith(color: AppColors.salesAccent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
