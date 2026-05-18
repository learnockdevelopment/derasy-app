import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/store_models.dart';
import 'user_storage_service.dart';

class StoreService {
  static const String baseStoreUrl = '${ApiConstants.parentBaseUrl}/store';

  // Helper to construct headers with auth token
  static Map<String, String> _getHeaders() {
    final token = UserStorageService.getAuthToken() ?? '';
    return ApiConstants.getHeaders(token: token);
  }

  // Safe JSON Decoder to capture HTML errors from backend and log them clearly
  static dynamic _safeJsonDecode(String body, String endpointInfo) {
    try {
      return jsonDecode(body);
    } on FormatException catch (e) {
      print('❌ [STORE_SERVICE] JSON FormatException for $endpointInfo: $e');
      print('❌ [STORE_SERVICE] Response body was: ${body.length > 500 ? body.substring(0, 500) + '...' : body}');
      throw FormatException('Server returned HTML or invalid format instead of JSON for $endpointInfo. Please check if the endpoint is deployed correctly.');
    }
  }

  // --- 1. Products APIs ---

  // Get list of products
  static Future<List<StoreProduct>> getProducts({
    String? category,
    String? search,
    bool? featured,
  }) async {
    var urlStr = '$baseStoreUrl/products';
    if (category != null) urlStr += 'category=$category&';
    if (search != null) urlStr += 'search=${Uri.encodeComponent(search)}&';
    if (featured != null) urlStr += 'featured=$featured&';

    print('🛒 [STORE_SERVICE] GET Products: $urlStr');
    final response = await http.get(Uri.parse(urlStr), headers: _getHeaders());
    print('🛒 [STORE_SERVICE] GET Products status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'GET Products');
      final list = (data['data'] ?? data['products'] ?? data) as List;
      return list.map((item) => StoreProduct.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode} - ${response.body}');
    }
  }

  // Get product details
  static Future<StoreProduct> getProductDetails(String productId) async {
    final url = '$baseStoreUrl/products/$productId';
    print('🛒 [STORE_SERVICE] GET Product Details: $url');
    final response = await http.get(Uri.parse(url), headers: _getHeaders());

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'GET Product Details');
      return StoreProduct.fromJson((data['data'] ?? data['product'] ?? data) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load product details: ${response.statusCode} - ${response.body}');
    }
  }

  // --- 2. Cart Management APIs (DB-Synced) ---

  // Get the database-synced cart
  static Future<StoreCart> getCart() async {
    final url = '$baseStoreUrl/cart';
    print('🛒 [STORE_SERVICE] GET Cart: $url');
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    print('🛒 [STORE_SERVICE] GET Cart status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'GET Cart');
      return StoreCart.fromJson((data['data'] ?? data['cart'] ?? data) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load cart: ${response.statusCode} - ${response.body}');
    }
  }

  // Add/Update item in cart
  static Future<StoreCart> addToCart(String productId, int quantity, List<CartItemSelection> selections) async {
    final url = '$baseStoreUrl/cart';
    print('🛒 [STORE_SERVICE] POST Add to Cart: $url');
    
    final body = {
      'productId': productId,
      'quantity': quantity,
      'selections': selections.map((s) => s.toJson()).toList(),
    };

    final response = await http.post(
      Uri.parse(url),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _safeJsonDecode(response.body, 'POST Add to Cart');
      return StoreCart.fromJson((data['data'] ?? data['cart'] ?? data) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to add to cart: ${response.statusCode} - ${response.body}');
    }
  }

  // Update item quantity
  static Future<StoreCart> updateCartItemQuantity(String cartItemId, int quantity) async {
    final url = '$baseStoreUrl/cart';
    print('🛒 [STORE_SERVICE] PUT Update Cart Item: $url');

    final body = {
      'cartItemId': cartItemId,
      'quantity': quantity,
    };

    final response = await http.put(
      Uri.parse(url),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'PUT Update Cart Item');
      return StoreCart.fromJson((data['data'] ?? data['cart'] ?? data) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update cart: ${response.statusCode} - ${response.body}');
    }
  }

  // Remove single item or clear entire cart
  static Future<StoreCart> removeCartItem({String? cartItemId, bool clearAll = false}) async {
    var urlStr = '$baseStoreUrl/cart?';
    if (cartItemId != null) urlStr += 'cartItemId=$cartItemId&';
    if (clearAll) urlStr += 'clear=true&';

    print('🛒 [STORE_SERVICE] DELETE Cart Item: $urlStr');
    final response = await http.delete(Uri.parse(urlStr), headers: _getHeaders());

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'DELETE Cart Item');
      return StoreCart.fromJson((data['data'] ?? data['cart'] ?? data) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to delete cart item: ${response.statusCode} - ${response.body}');
    }
  }

  // --- 3. Orders & Checkout APIs ---

  // Create an order (checkout)
  static Future<StoreOrder?> createOrder({
    required String paymentMethod,
    required String deliveryMethod,
    required StoreShippingAddress shippingAddress,
    String notes = '',
    String? school,
  }) async {
    final url = '$baseStoreUrl/orders';
    print('🛒 [STORE_SERVICE] POST Create Order: $url');

    final body = {
      'paymentMethod': paymentMethod,
      'deliveryMethod': deliveryMethod,
      'shippingAddress': shippingAddress.toJson(),
      'notes': notes,
      if (school != null) 'school': school,
    };

    final response = await http.post(
      Uri.parse(url),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _safeJsonDecode(response.body, 'POST Create Order');
      return StoreOrder.fromJson((data['data'] ?? data['order'] ?? data) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to create order: ${response.statusCode} - ${response.body}');
    }
  }

  // Get order history
  static Future<List<StoreOrder>> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    var urlStr = '$baseStoreUrl/orders?page=$page&limit=$limit';
    if (status != null) urlStr += '&status=$status';

    print('🛒 [STORE_SERVICE] GET Orders: $urlStr');
    final response = await http.get(Uri.parse(urlStr), headers: _getHeaders());

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'GET Orders');
      final list = (data['data'] ?? data['orders'] ?? data) as List;
      return list.map((item) => StoreOrder.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch orders: ${response.statusCode} - ${response.body}');
    }
  }
}
