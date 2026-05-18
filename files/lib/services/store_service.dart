import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/store_models.dart';
import 'user_storage_service.dart';

class StoreService {
  static const String baseStoreUrl = '${ApiConstants.parentBaseUrl}/store';

  // Local Product Cache for Client-Side Cart Lookup
  static final Map<String, StoreProduct> _cachedProducts = {};

  // Local Cart State
  static final List<StoreCartItem> _localCartItems = [];

  // Dynamic categories discovered from the backend
  static List<Map<String, String>> discoveredCategories = [
    {'id': 'all', 'name': 'All Items', 'name_ar': 'الكل'}
  ];

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

  // --- 1. Products APIs (Listed in Specs) ---

  // Get list of products
  static Future<List<StoreProduct>> getProducts({
    String? category,
    String? search,
    bool? featured,
  }) async {
    // Hits GET /store exactly without query parameters or filters as specified in Store Discovery
    final urlStr = baseStoreUrl;
    print('🛒 [STORE_SERVICE] GET Store Discovery: $urlStr');
    final response = await http.get(Uri.parse(urlStr), headers: _getHeaders());
    print('🛒 [STORE_SERVICE] GET Store Discovery status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'GET Store Discovery');
      
      // Parse dynamic categories
      if (data['categories'] != null && data['categories'] is List) {
        final catList = data['categories'] as List;
        discoveredCategories = [
          {'id': 'all', 'name': 'All Items', 'name_ar': 'الكل'}
        ];
        for (final cat in catList) {
          if (cat is Map<String, dynamic>) {
            final id = cat['_id']?.toString() ?? cat['slug']?.toString() ?? '';
            final name = cat['title_en']?.toString() ?? cat['name_en']?.toString() ?? cat['name']?.toString() ?? cat['title']?.toString() ?? id;
            final nameAr = cat['title_ar']?.toString() ?? cat['name_ar']?.toString() ?? cat['name']?.toString() ?? name;
            
            discoveredCategories.add({
              'id': name,
              'name': name,
              'name_ar': nameAr,
            });
          }
        }
      }

      final list = (data['products'] ?? data['data'] ?? data) as List;
      final products = list.map((item) => StoreProduct.fromJson(item as Map<String, dynamic>)).toList();
      
      // Parse school packages/bundles dynamically from discovery response
      final pkgList = (data['packages'] ?? []) as List;
      final packages = pkgList.map((item) {
        final map = item as Map<String, dynamic>;
        return StoreProduct(
          id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
          titleEn: map['title']?.toString() ?? '',
          titleAr: map['title']?.toString() ?? '',
          price: (map['packagePrice'] as num?)?.toDouble() ?? 0.0,
          images: map['coverImage'] != null ? [map['coverImage'].toString()] : [],
          description: map['description']?.toString() ?? '',
          category: map['category']?.toString() ?? 'Uniform & Books',
          stock: 99,
          featured: map['isFeatured'] as bool? ?? false,
          slug: map['slug']?.toString() ?? '',
          itemType: 'package',
          packageItems: map['products'],
        );
      }).toList();

      final allItems = [...products, ...packages];

      // Cache all items for cart lookup
      for (final p in allItems) {
        _cachedProducts[p.id] = p;
      }
      
      return allItems;
    } else {
      throw Exception('Failed to load products: ${response.statusCode} - ${response.body}');
    }
  }

  // Get product details by slug
  static Future<StoreProduct> getProductDetails(String slug) async {
    final url = '$baseStoreUrl/products/$slug';
    print('🛒 [STORE_SERVICE] GET Product Details: $url');
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    print('🛒 [STORE_SERVICE] GET Product Details response: ${response.body}');

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'GET Product Details');
      final product = StoreProduct.fromJson((data['product'] ?? data['data'] ?? data) as Map<String, dynamic>);
      
      // Cache product details for cart lookup
      _cachedProducts[product.id] = product;
      
      return product;
    } else {
      throw Exception('Failed to load product details: ${response.statusCode} - ${response.body}');
    }
  }

  // Get package details by slug
  static Future<StoreProduct> getPackageDetails(String slug) async {
    final url = '$baseStoreUrl/packages/$slug';
    print('🛒 [STORE_SERVICE] GET Package Details: $url');
    final response = await http.get(Uri.parse(url), headers: _getHeaders());
    print('🛒 [STORE_SERVICE] GET Package Details response: ${response.body}');

    if (response.statusCode == 200) {
      final data = _safeJsonDecode(response.body, 'GET Package Details');
      final map = (data['schoolPackage'] ?? data['package'] ?? data['data'] ?? data) as Map<String, dynamic>;
      
      final product = StoreProduct(
        id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
        titleEn: map['title_en']?.toString() ?? map['title']?.toString() ?? '',
        titleAr: map['title_ar']?.toString() ?? map['title']?.toString() ?? '',
        price: (map['price'] as num?)?.toDouble() ?? (map['packagePrice'] as num?)?.toDouble() ?? 0.0,
        images: map['images'] != null 
            ? List<String>.from((map['images'] as List).map((e) => e.toString()))
            : (map['coverImage'] != null ? [map['coverImage'].toString()] : []),
        description: map['description']?.toString() ?? '',
        category: map['category']?.toString() ?? 'Uniform & Books',
        stock: 99,
        featured: map['isFeatured'] as bool? ?? false,
        slug: map['slug']?.toString() ?? '',
        itemType: 'package',
        packageItems: map['products'],
      );

      // Cache product details for cart lookup
      _cachedProducts[product.id] = product;
      
      return product;
    } else {
      throw Exception('Failed to load package details: ${response.statusCode} - ${response.body}');
    }
  }

  // --- 2. Local Cart Management (Simulated Client-Side to Avoid Non-Existent Endpoints) ---

  // Helper to build a StoreCart object from local items
  static StoreCart _buildLocalCart() {
    double subtotal = 0;
    int count = 0;
    for (final item in _localCartItems) {
      subtotal += item.subtotal;
      count += item.quantity;
    }
    return StoreCart(
      items: List.from(_localCartItems),
      subtotal: subtotal,
      total: subtotal,
      itemCount: count,
    );
  }

  // Get the locally managed cart
  static Future<StoreCart> getCart() async {
    print('🛒 [STORE_SERVICE] GET Local Cart (Active Items: ${_localCartItems.length})');
    return _buildLocalCart();
  }

  // Add item to local cart
  static Future<StoreCart> addToCart(String productId, int quantity, List<CartItemSelection> selections) async {
    print('🛒 [STORE_SERVICE] Local Add to Cart - Product: $productId, Qty: $quantity');

    // Find if the item already exists with matching selections
    int index = -1;
    for (int i = 0; i < _localCartItems.length; i++) {
      if (_localCartItems[i].productId == productId) {
        bool match = true;
        if (_localCartItems[i].selections.length == selections.length) {
          for (int j = 0; j < selections.length; j++) {
            if (_localCartItems[i].selections[j].name != selections[j].name ||
                _localCartItems[i].selections[j].value != selections[j].value) {
              match = false;
              break;
            }
          }
        } else {
          match = false;
        }
        if (match) {
          index = i;
          break;
        }
      }
    }

    final product = _cachedProducts[productId];
    final price = product?.price ?? 150.0; // fallback if not cached yet

    if (index != -1) {
      final existing = _localCartItems[index];
      final newQty = existing.quantity + quantity;
      _localCartItems[index] = StoreCartItem(
        id: existing.id,
        productId: productId,
        itemType: existing.itemType,
        product: existing.product,
        quantity: newQty,
        selections: existing.selections,
        price: price,
        subtotal: price * newQty,
      );
    } else {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      _localCartItems.add(StoreCartItem(
        id: id,
        productId: productId,
        itemType: 'product',
        product: product,
        quantity: quantity,
        selections: selections,
        price: price,
        subtotal: price * quantity,
      ));
    }

    return _buildLocalCart();
  }

  // Update item quantity locally
  static Future<StoreCart> updateCartItemQuantity(String cartItemId, int quantity) async {
    print('🛒 [STORE_SERVICE] Local Update Qty - Item: $cartItemId, Qty: $quantity');
    
    int index = _localCartItems.indexWhere((item) => item.id == cartItemId);
    if (index != -1) {
      final existing = _localCartItems[index];
      _localCartItems[index] = StoreCartItem(
        id: existing.id,
        productId: existing.productId,
        itemType: existing.itemType,
        product: existing.product,
        quantity: quantity,
        selections: existing.selections,
        price: existing.price,
        subtotal: existing.price * quantity,
      );
    }

    return _buildLocalCart();
  }

  // Remove local item or clear cart
  static Future<StoreCart> removeCartItem({String? cartItemId, bool clearAll = false}) async {
    print('🛒 [STORE_SERVICE] Local Remove - Item: $cartItemId, ClearAll: $clearAll');
    
    if (clearAll) {
      _localCartItems.clear();
    } else if (cartItemId != null) {
      _localCartItems.removeWhere((item) => item.id == cartItemId);
    }

    return _buildLocalCart();
  }

  // --- 3. Orders & Checkout APIs (Listed in Specs) ---

  // Create an order (checkout)
  static Future<String?> createOrder({
    required String deliveryMethod,
    required StoreShippingAddress shippingAddress,
    required List<StoreCartItem> items,
    String notes = '',
  }) async {
    final url = '$baseStoreUrl/checkout';
    print('🛒 [STORE_SERVICE] POST Create Order: $url');

    final body = {
      'deliveryMethod': deliveryMethod,
      'shippingAddress': shippingAddress.toJson(),
      'notes': notes,
      'items': items.map((item) => {
        'itemId': item.productId,
        'itemType': item.itemType,
        'quantity': item.quantity,
        'selections': item.selections.map((s) => s.toJson()).toList(),
      }).toList(),
    };

    final response = await http.post(
      Uri.parse(url),
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = _safeJsonDecode(response.body, 'POST Create Order');
      
      // Clear local cart on successful checkout
      _localCartItems.clear();
      
      return data['orderId']?.toString();
    } else {
      dynamic errorData;
      try {
        errorData = jsonDecode(response.body);
      } catch (_) {}
      final message = errorData != null ? (errorData['message'] ?? errorData['error']) : null;
      throw Exception(message ?? 'Failed to create order: ${response.statusCode}');
    }
  }

  // Get order history
  static Future<List<StoreOrder>> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    // Hits GET /store/orders exactly without query parameters or filters as specified in specs
    final urlStr = '$baseStoreUrl/orders';
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
