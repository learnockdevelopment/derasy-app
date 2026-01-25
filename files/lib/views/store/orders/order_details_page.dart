import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/store_models.dart';
import '../../../services/store_service.dart';
import '../../../services/user_storage_service.dart';
import '../../../widgets/safe_network_image.dart';
import '../../../widgets/shimmer_loading.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({Key? key}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Order? _order;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    final orderId = args?['orderId'] as String?;
    if (orderId != null) {
      _loadOrder(orderId);
    }
  }

  Future<void> _loadOrder(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final order = await StoreService.getOrder(id);
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Get.snackbar(
          'error'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
        );
        Get.back();
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'confirmed':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'pending'.tr;
      case 'confirmed':
        return 'confirmed'.tr;
      case 'shipped':
        return 'shipped'.tr;
      case 'delivered':
        return 'delivered'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.blue1,
          title: Text('order_details'.tr),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.blue1,
          title: Text('order_details'.tr),
        ),
        body: Center(
          child: Text('order_not_found'.tr),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        elevation: 0,
        title: Text(
          'order_details'.tr,
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            Container(
              margin: Responsive.all(16),
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.r(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
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
                        'order_status'.tr,
                        style: AppFonts.h3.copyWith(
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.bold,
                          fontSize: AppFonts.size18,
                        ),
                      ),
                      Container(
                        padding: Responsive.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_order!.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Responsive.r(8)),
                        ),
                        child: Text(
                          _getStatusText(_order!.status),
                          style: AppFonts.bodySmall.copyWith(
                            color: _getStatusColor(_order!.status),
                            fontSize: AppFonts.size12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'payment_status'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                          fontSize: AppFonts.size14,
                        ),
                      ),
                      Text(
                        _order!.paymentStatus == 'paid' ? 'paid'.tr : 'unpaid'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: _order!.paymentStatus == 'paid' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: AppFonts.size14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_order!.createdAt != null) ...[
                    SizedBox(height: Responsive.h(8)),
                    Text(
                      '${'order_date'.tr}: ${_formatDate(_order!.createdAt!)}',
                      style: AppFonts.bodySmall.copyWith(
                        color: const Color(0xFF9CA3AF),
                        fontSize: AppFonts.size12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Order Items
            Container(
              margin: Responsive.symmetric(horizontal: 16),
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.r(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'order_items'.tr,
                    style: AppFonts.h3.copyWith(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: AppFonts.size18,
                    ),
                  ),
                  SizedBox(height: Responsive.h(16)),
                  ..._order!.items.map((item) {
                    return _buildOrderItem(item);
                  }),
                ],
              ),
            ),

            // Order Summary
            Container(
              margin: Responsive.all(16),
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.r(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'order_summary'.tr,
                    style: AppFonts.h3.copyWith(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.bold,
                      fontSize: AppFonts.size18,
                    ),
                  ),
                  SizedBox(height: Responsive.h(16)),
                  _buildSummaryRow('subtotal'.tr, '${_order!.subtotal.toStringAsFixed(0)} ${'egp'.tr}'),
                  if (_order!.discount > 0)
                    _buildSummaryRow('discount'.tr, '-${_order!.discount.toStringAsFixed(0)} ${'egp'.tr}'),
                  if (_order!.deliveryFee > 0)
                    _buildSummaryRow('delivery_fee'.tr, '${_order!.deliveryFee.toStringAsFixed(0)} ${'egp'.tr}'),
                  Divider(height: Responsive.h(24)),
                  _buildSummaryRow('total'.tr, '${_order!.total.toStringAsFixed(0)} ${'egp'.tr}',
                      isTotal: true),
                ],
              ),
            ),

            // Shipping Address
            if (_order!.shippingAddress != null) ...[
              Container(
                margin: Responsive.symmetric(horizontal: 16),
                padding: Responsive.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'shipping_address'.tr,
                      style: AppFonts.h3.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: AppFonts.size18,
                      ),
                    ),
                    SizedBox(height: Responsive.h(12)),
                    Text(
                      '${_order!.shippingAddress!.name}\n${_order!.shippingAddress!.phone}\n${_order!.shippingAddress!.address}\n${_order!.shippingAddress!.city}, ${_order!.shippingAddress!.governorate}',
                      style: AppFonts.bodyMedium.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: AppFonts.size14,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: Responsive.h(20)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Container(
      margin: Responsive.only(bottom: 12),
      child: Row(
        children: [
          SafeNetworkImage(
            imageUrl: item.product?.images.isNotEmpty == true ? item.product!.images.first : '',
            width: Responsive.w(60),
            height: Responsive.h(60),
            fit: BoxFit.cover,
            errorWidget: Container(
              width: Responsive.w(60),
              height: Responsive.h(60),
              color: const Color(0xFFF3F4F6),
              child: Icon(Icons.image_rounded, size: Responsive.sp(24), color: const Color(0xFF9CA3AF)),
            ),
          ),
          SizedBox(width: Responsive.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product?.titleAr ?? 'product'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.bold,
                    fontSize: AppFonts.size14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  '${'quantity'.tr}: ${item.quantity} x ${item.price.toStringAsFixed(0)} ${'egp'.tr}',
                  style: AppFonts.bodySmall.copyWith(
                    color: const Color(0xFF6B7280),
                    fontSize: AppFonts.size12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.subtotal.toStringAsFixed(0)} ${'egp'.tr}',
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.blue1,
              fontWeight: FontWeight.bold,
              fontSize: AppFonts.size14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: Responsive.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppFonts.bodyMedium.copyWith(
              color: isTotal ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
              fontSize: isTotal ? AppFonts.size16 : AppFonts.size14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppFonts.bodyMedium.copyWith(
              color: isTotal ? AppColors.blue1 : const Color(0xFF1F2937),
              fontSize: isTotal ? AppFonts.size18 : AppFonts.size14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}


