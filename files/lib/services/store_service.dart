import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/store_models.dart';
import 'user_storage_service.dart';

class StoreException implements Exception {
  final String message;

  StoreException(this.message);

  @override
  String toString() => 'StoreException: $message';
}

class StoreService {
  static const String _baseUrl = ApiConstants.baseUrl;

  // Products

  static Future<Map<String, dynamic>> getAllProducts({
    String? category,
    String? search,
    bool? featured,
    String? school,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🛒 [STORE SERVICE] ===========================================');
      print('🛒 [STORE SERVICE] getAllProducts called');
      print('🛒 [STORE SERVICE] Parameters:');
      print('🛒 [STORE SERVICE]   - category: $category');
      print('🛒 [STORE SERVICE]   - search: $search');
      print('🛒 [STORE SERVICE]   - featured: $featured');
      print('🛒 [STORE SERVICE]   - school: $school');
      print('🛒 [STORE SERVICE]   - page: $page');
      print('🛒 [STORE SERVICE]   - limit: $limit');
      
      final token = UserStorageService.getAuthToken();
      print('🛒 [STORE SERVICE] Token: ${token != null ? "EXISTS" : "NULL"}');
      
      final headers = token != null
          ? ApiConstants.getAuthHeaders(token)
          : {'Content-Type': 'application/json'};
      print('🛒 [STORE SERVICE] Headers: $headers');

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category != null) queryParams['category'] = category;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (featured != null) queryParams['featured'] = featured.toString();
      if (school != null) queryParams['school'] = school;

      final uri = Uri.parse('$_baseUrl/store/products').replace(queryParameters: queryParams);
      print('🛒 [STORE SERVICE] Base URL: $_baseUrl');
      print('🛒 [STORE SERVICE] Full URL: $uri');
      print('🛒 [STORE SERVICE] Query Params: $queryParams');
      print('🛒 [STORE SERVICE] Making GET request...');
      
      final response = await http.get(uri, headers: headers);
      
      print('🛒 [STORE SERVICE] Response received');
      print('🛒 [STORE SERVICE] Status Code: ${response.statusCode}');
      print('🛒 [STORE SERVICE] Response Headers: ${response.headers}');
      print('🛒 [STORE SERVICE] Content-Type: ${response.headers['content-type']}');
      print('🛒 [STORE SERVICE] Response Body Length: ${response.body.length}');
      
      // Check if response is HTML (error page)
      if (response.headers['content-type']?.contains('text/html') == true) {
        print('🛒 [STORE SERVICE] ❌ Response is HTML, not JSON!');
        print('🛒 [STORE SERVICE] This usually means the endpoint does not exist');
        print('🛒 [STORE SERVICE] Response Body (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        throw StoreException('API endpoint not found. The server returned an HTML page instead of JSON. Please check if the endpoint /store/products exists.');
      }
      
      print('🛒 [STORE SERVICE] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('🛒 [STORE SERVICE] ✅ Success (200)');
        try {
          final data = jsonDecode(response.body);
          print('🛒 [STORE SERVICE] Parsed JSON successfully');
          print('🛒 [STORE SERVICE] Data keys: ${data.keys.toList()}');
          print('🛒 [STORE SERVICE] Products Count: ${(data['data'] as List<dynamic>?)?.length ?? 0}');
          print('🛒 [STORE SERVICE] Pagination: ${data['pagination']}');
          
          final products = (data['data'] as List<dynamic>?)
              ?.map((e) {
                try {
                  return Product.fromJson(e);
                } catch (parseError) {
                  print('🛒 [STORE SERVICE] ❌ Error parsing product: $parseError');
                  print('🛒 [STORE SERVICE] Product data: $e');
                  return null;
                }
              })
              .where((p) => p != null)
              .cast<Product>()
              .toList() ?? [];
          
          print('🛒 [STORE SERVICE] Successfully parsed ${products.length} products');
          
          final result = {
            'success': true,
            'products': products,
            'pagination': data['pagination'] != null
                ? PaginationInfo.fromJson(data['pagination'])
                : null,
          };
          
          print('🛒 [STORE SERVICE] Returning result with ${products.length} products');
          print('🛒 [STORE SERVICE] ===========================================');
          return result;
        } catch (parseError) {
          print('🛒 [STORE SERVICE] ❌ JSON Parse Error: $parseError');
          print('🛒 [STORE SERVICE] Response body that failed to parse: ${response.body}');
          throw StoreException('Failed to parse response: $parseError');
        }
      } else if (response.statusCode == 403) {
        print('🛒 [STORE SERVICE] ❌ Forbidden (403)');
        try {
          final errorData = jsonDecode(response.body);
          print('🛒 [STORE SERVICE] Error message: ${errorData['message']}');
          throw StoreException(errorData['message'] ?? 'Store is currently disabled');
        } catch (e) {
          if (e is StoreException) rethrow;
          print('🛒 [STORE SERVICE] Error response body: ${response.body}');
          throw StoreException('Store is currently disabled');
        }
      } else {
        print('🛒 [STORE SERVICE] ❌ Error Status Code: ${response.statusCode}');
        print('🛒 [STORE SERVICE] Error Response Body: ${response.body}');
        throw StoreException('Failed to load products: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🛒 [STORE SERVICE] ===========================================');
      print('🛒 [STORE SERVICE] ❌ EXCEPTION CAUGHT');
      print('🛒 [STORE SERVICE] Error type: ${e.runtimeType}');
      print('🛒 [STORE SERVICE] Error message: $e');
      print('🛒 [STORE SERVICE] Stack trace: ${StackTrace.current}');
      print('🛒 [STORE SERVICE] ===========================================');
      if (e is StoreException) rethrow;
      throw StoreException('Failed to load products: $e');
    }
  }

  static Future<Product> getProduct(String id) async {
    try {
      final token = UserStorageService.getAuthToken();
      final headers = token != null
          ? ApiConstants.getAuthHeaders(token)
          : {'Content-Type': 'application/json'};

      final response = await http.get(
        Uri.parse('$_baseUrl/store/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw StoreException('Product not found');
      } else {
        throw StoreException('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to load product: $e');
    }
  }

  static Future<Product> createProduct(Map<String, dynamic> productData) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/store/products'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw StoreException(errorData['message'] ?? 'Invalid data');
      } else if (response.statusCode == 403) {
        throw StoreException('Not authorized');
      } else {
        throw StoreException('Failed to create product: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to create product: $e');
    }
  }

  static Future<Product> updateProduct(String id, Map<String, dynamic> productData) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/store/products/$id'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw StoreException('Product not found');
      } else if (response.statusCode == 403) {
        throw StoreException('Not authorized');
      } else {
        throw StoreException('Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to update product: $e');
    }
  }

  static Future<void> deleteProduct(String id) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/store/products/$id'),
        headers: ApiConstants.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw StoreException('Product not found');
      } else if (response.statusCode == 403) {
        throw StoreException('Not authorized');
      } else {
        throw StoreException('Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to delete product: $e');
    }
  }

  // Categories

  static Future<List<Category>> getAllCategories({
    String? parent,
    bool includeInactive = false,
  }) async {
    try {
      final token = UserStorageService.getAuthToken();
      final headers = token != null
          ? ApiConstants.getAuthHeaders(token)
          : {'Content-Type': 'application/json'};

      final queryParams = <String, String>{
        'includeInactive': includeInactive.toString(),
      };
      if (parent != null) queryParams['parent'] = parent;

      final uri = Uri.parse('$_baseUrl/store/categories').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
            ?.map((e) => Category.fromJson(e))
            .toList() ?? [];
      } else {
        throw StoreException('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to load categories: $e');
    }
  }

  static Future<Category> getCategory(String id) async {
    try {
      final token = UserStorageService.getAuthToken();
      final headers = token != null
          ? ApiConstants.getAuthHeaders(token)
          : {'Content-Type': 'application/json'};

      final response = await http.get(
        Uri.parse('$_baseUrl/store/categories/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw StoreException('Category not found');
      } else {
        throw StoreException('Failed to load category: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to load category: $e');
    }
  }

  static Future<Category> createCategory(Map<String, dynamic> categoryData) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/store/categories'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode(categoryData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data['data']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw StoreException(errorData['message'] ?? 'Invalid data');
      } else if (response.statusCode == 403) {
        throw StoreException('Not authorized');
      } else {
        throw StoreException('Failed to create category: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to create category: $e');
    }
  }

  static Future<Category> updateCategory(String id, Map<String, dynamic> categoryData) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/store/categories/$id'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode(categoryData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw StoreException('Category not found');
      } else if (response.statusCode == 403) {
        throw StoreException('Not authorized');
      } else {
        throw StoreException('Failed to update category: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to update category: $e');
    }
  }

  static Future<void> deleteCategory(String id) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/store/categories/$id'),
        headers: ApiConstants.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw StoreException(errorData['message'] ?? 'Cannot delete category');
      } else if (response.statusCode == 404) {
        throw StoreException('Category not found');
      } else if (response.statusCode == 403) {
        throw StoreException('Not authorized');
      } else {
        throw StoreException('Failed to delete category: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to delete category: $e');
    }
  }

  // Cart

  static Future<ShoppingCart> getCart() async {
    try {
      print('🛒 [STORE SERVICE] ===========================================');
      print('🛒 [STORE SERVICE] Getting cart...');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final url = '$_baseUrl/store/cart';
      final headers = ApiConstants.getAuthHeaders(token);

      print('🛒 [STORE SERVICE] URL: $url');
      print('🛒 [STORE SERVICE] Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('🛒 [STORE SERVICE] Response status: ${response.statusCode}');
      print('🛒 [STORE SERVICE] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🛒 [STORE SERVICE] ✅ Cart retrieved successfully');
        print('🛒 [STORE SERVICE] Cart data: ${data['data']}');
        
        final cart = ShoppingCart.fromJson(data['data']);
        print('🛒 [STORE SERVICE] Cart items count: ${cart.items.length}');
        print('🛒 [STORE SERVICE] Cart total: ${cart.total}');
        print('🛒 [STORE SERVICE] Cart subtotal: ${cart.subtotal}');
        print('🛒 [STORE SERVICE] ===========================================');
        
        return cart;
      } else if (response.statusCode == 401) {
        throw StoreException('Authentication required');
      } else {
        throw StoreException('Failed to load cart: ${response.statusCode}');
      }
    } catch (e) {
      print('🛒 [STORE SERVICE] ❌ Error loading cart: $e');
      print('🛒 [STORE SERVICE] ===========================================');
      if (e is StoreException) rethrow;
      throw StoreException('Failed to load cart: $e');
    }
  }

  static Future<ShoppingCart> addToCart({
    required String productId,
    required int quantity,
    List<CartSelection> selections = const [],
  }) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final requestBody = {
        'productId': productId,
        'quantity': quantity,
        'selections': selections.map((s) => s.toJson()).toList(),
      };

      print('🛒 [STORE SERVICE] Add to Cart Request:');
      print('🛒 [STORE SERVICE] URL: $_baseUrl/store/cart');
      print('🛒 [STORE SERVICE] Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/store/cart'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode(requestBody),
      );

      print('🛒 [STORE SERVICE] Add to Cart Response:');
      print('🛒 [STORE SERVICE] Status Code: ${response.statusCode}');
      print('🛒 [STORE SERVICE] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🛒 [STORE SERVICE] ✅ Item added to cart successfully');
        print('🛒 [STORE SERVICE] Cart Data: ${data['data']}');
        if (data['data'] != null) {
          final cart = ShoppingCart.fromJson(data['data']);
          print('🛒 [STORE SERVICE] Cart Items Count: ${cart.items.length}');
          print('🛒 [STORE SERVICE] Cart Total: ${cart.total}');
          print('🛒 [STORE SERVICE] Cart Subtotal: ${cart.subtotal}');
        }
        return ShoppingCart.fromJson(data['data']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw StoreException(errorData['message'] ?? 'Failed to add to cart');
      } else if (response.statusCode == 401) {
        throw StoreException('Authentication required');
      } else {
        throw StoreException('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to add to cart: $e');
    }
  }

  static Future<ShoppingCart> updateCartItem({
    required String productId,
    required int quantity,
    List<CartSelection> selections = const [],
  }) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/store/cart'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode({
          'productId': productId,
          'quantity': quantity,
          'selections': selections.map((s) => s.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ShoppingCart.fromJson(data['data']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw StoreException(errorData['message'] ?? 'Failed to update cart');
      } else if (response.statusCode == 404) {
        throw StoreException('Item not found in cart');
      } else if (response.statusCode == 401) {
        throw StoreException('Authentication required');
      } else {
        throw StoreException('Failed to update cart: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to update cart: $e');
    }
  }

  static Future<ShoppingCart> removeFromCart({
    required String productId,
    List<CartSelection> selections = const [],
  }) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final queryParams = <String, String>{
        'productId': productId,
      };
      if (selections.isNotEmpty) {
        queryParams['selections'] = jsonEncode(selections.map((s) => s.toJson()).toList());
      }

      final uri = Uri.parse('$_baseUrl/store/cart').replace(queryParameters: queryParams);
      final response = await http.delete(
        uri,
        headers: ApiConstants.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ShoppingCart.fromJson(data['data']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw StoreException(errorData['message'] ?? 'Failed to remove from cart');
      } else if (response.statusCode == 401) {
        throw StoreException('Authentication required');
      } else {
        throw StoreException('Failed to remove from cart: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to remove from cart: $e');
    }
  }

  // Orders

  static Future<Map<String, dynamic>> getAllOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$_baseUrl/store/orders').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: ApiConstants.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'orders': (data['data'] as List<dynamic>?)
              ?.map((e) => Order.fromJson(e))
              .toList() ?? [],
          'pagination': data['pagination'] != null
              ? PaginationInfo.fromJson(data['pagination'])
              : null,
        };
      } else if (response.statusCode == 401) {
        throw StoreException('Authentication required');
      } else {
        throw StoreException('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to load orders: $e');
    }
  }

  static Future<Order> getOrder(String id) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/store/orders/$id'),
        headers: ApiConstants.getAuthHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['data']);
      } else if (response.statusCode == 403) {
        throw StoreException('Access denied');
      } else if (response.statusCode == 404) {
        throw StoreException('Order not found');
      } else if (response.statusCode == 401) {
        throw StoreException('Authentication required');
      } else {
        throw StoreException('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to load order: $e');
    }
  }

  static Future<Order> createOrder({
    required List<Map<String, dynamic>> items,
    ShippingAddress? shippingAddress,
    required String deliveryMethod,
    double? deliveryFee,
    String? notes,
    String? schoolId,
  }) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final orderData = <String, dynamic>{
        'items': items,
        'deliveryMethod': deliveryMethod,
      };
      if (shippingAddress != null) orderData['shippingAddress'] = shippingAddress.toJson();
      if (deliveryFee != null) orderData['deliveryFee'] = deliveryFee;
      if (notes != null && notes.isNotEmpty) orderData['notes'] = notes;
      if (schoolId != null) orderData['school'] = schoolId;

      final response = await http.post(
        Uri.parse('$_baseUrl/store/orders'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['data']);
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw StoreException(errorData['message'] ?? 'Failed to create order');
      } else if (response.statusCode == 401) {
        throw StoreException('Authentication required');
      } else {
        throw StoreException('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to create order: $e');
    }
  }

  static Future<Order> updateOrderStatus({
    required String id,
    required String status,
    String? adminNotes,
    String? trackingNumber,
  }) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw StoreException('Authentication required');
      }

      final updateData = <String, dynamic>{
        'status': status,
      };
      if (adminNotes != null) updateData['adminNotes'] = adminNotes;
      if (trackingNumber != null) updateData['trackingNumber'] = trackingNumber;

      final response = await http.put(
        Uri.parse('$_baseUrl/store/orders/$id'),
        headers: ApiConstants.getAuthHeaders(token),
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw StoreException('Order not found');
      } else if (response.statusCode == 403) {
        throw StoreException('Not authorized');
      } else {
        throw StoreException('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreException) rethrow;
      throw StoreException('Failed to update order: $e');
    }
  }
}


