import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/store_models.dart';
import '../../../services/store_service.dart';
import '../../../widgets/shimmer_loading.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = false;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool resetPage = false}) async {
    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await StoreService.getAllOrders(
        page: _currentPage,
        limit: 20,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _orders = result['orders'] as List<Order>;
          final pagination = result['pagination'] as PaginationInfo?;
          _totalPages = pagination?.pages ?? 1;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        elevation: 0,
        title: Text(
          'orders'.tr,
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
      body: Column(
        children: [
          // Status Filter
          Container(
            color: Colors.white,
            padding: Responsive.symmetric(vertical: 12, horizontal: 16),
            child: SizedBox(
              height: Responsive.h(40),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (_, __) => SizedBox(width: Responsive.w(8)),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildStatusChip(null, 'all'.tr);
                  }
                  final statuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
                  final status = statuses[index - 1];
                  return _buildStatusChip(status, _getStatusText(status));
                },
              ),
            ),
          ),
          // Orders List
          Expanded(
            child: _isLoading && _orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadOrders(resetPage: true),
                        child: ListView.builder(
                          padding: Responsive.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_orders[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status, String label) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? status : null;
        });
        _loadOrders(resetPage: true);
      },
      selectedColor: AppColors.blue1,
      labelStyle: AppFonts.bodyMedium.copyWith(
        color: isSelected ? Colors.white : const Color(0xFF1F2937),
        fontSize: AppFonts.size12,
      ),
      padding: Responsive.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: Responsive.only(bottom: 12),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        onTap: () {
          Get.toNamed(AppRoutes.storeOrderDetails, arguments: {'orderId': order.id});
        },
        child: Padding(
          padding: Responsive.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.id.substring(0, 8)}',
                    style: AppFonts.bodyMedium.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: AppFonts.size12,
                    ),
                  ),
                  Container(
                    padding: Responsive.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Responsive.r(8)),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: AppFonts.bodySmall.copyWith(
                        color: _getStatusColor(order.status),
                        fontSize: AppFonts.size10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(12)),
              Text(
                '${order.items.length} ${'items'.tr}',
                style: AppFonts.bodyMedium.copyWith(
                  color: const Color(0xFF1F2937),
                  fontSize: AppFonts.size14,
                ),
              ),
              SizedBox(height: Responsive.h(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'total'.tr,
                    style: AppFonts.bodyMedium.copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: AppFonts.size14,
                    ),
                  ),
                  Text(
                    '${order.total.toStringAsFixed(0)} ${'egp'.tr}',
                    style: AppFonts.bodyLarge.copyWith(
                      color: AppColors.blue1,
                      fontWeight: FontWeight.bold,
                      fontSize: AppFonts.size16,
                    ),
                  ),
                ],
              ),
              if (order.createdAt != null) ...[
                SizedBox(height: Responsive.h(8)),
                Text(
                  _formatDate(order.createdAt!),
                  style: AppFonts.bodySmall.copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontSize: AppFonts.size12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: Responsive.sp(80), color: const Color(0xFF9CA3AF)),
          SizedBox(height: Responsive.h(16)),
          Text(
            'no_orders'.tr,
            style: AppFonts.bodyLarge.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: AppFonts.size16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


