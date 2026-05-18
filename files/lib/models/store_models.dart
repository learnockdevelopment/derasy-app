class StoreProduct {
  final String id;
  final String titleEn;
  final String titleAr;
  final double price;
  final List<String> images;
  final String description;
  final String category;
  final int stock;
  final bool featured;
  final String slug;
  final String itemType; // 'product' or 'package'
  final List<dynamic>? packageItems; // Nested items for package/bundle

  StoreProduct({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.price,
    required this.images,
    this.description = '',
    this.category = '',
    this.stock = 0,
    this.featured = false,
    this.slug = '',
    this.itemType = 'product',
    this.packageItems,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? json['title']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? json['title_en']?.toString() ?? json['title']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      images: (json['images'] as List?)?.map((img) => img.toString()).toList() ?? [],
      description: json['description']?.toString() ?? json['description_en']?.toString() ?? '',
      category: _parseCategory(json['category']),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      featured: json['featured'] as bool? ?? json['isFeatured'] as bool? ?? false,
      slug: json['slug']?.toString() ?? '',
      itemType: json['itemType']?.toString() ?? 'product',
      packageItems: json['packageItems'] ?? json['products'],
    );
  }

  static String _parseCategory(dynamic catJson) {
    if (catJson == null) return '';
    if (catJson is Map) {
      final name = catJson['name_en'] ?? catJson['name'] ?? catJson['title_en'] ?? catJson['title'] ?? catJson['_id'] ?? '';
      return name.toString();
    }
    return catJson.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title_en': titleEn,
      'title_ar': titleAr,
      'price': price,
      'images': images,
      'description': description,
      'category': category,
      'stock': stock,
      'featured': featured,
      'slug': slug,
      'itemType': itemType,
      if (packageItems != null) 'packageItems': packageItems,
    };
  }
}

class CartItemSelection {
  final String name;
  final String value;

  CartItemSelection({
    required this.name,
    required this.value,
  });

  factory CartItemSelection.fromJson(Map<String, dynamic> json) {
    return CartItemSelection(
      name: json['name']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

class StoreCartItem {
  final String id;
  final String productId;
  final String itemType; // 'product' or 'package'
  final StoreProduct? product;
  final int quantity;
  final List<CartItemSelection> selections;
  final double price;
  final double subtotal;

  StoreCartItem({
    required this.id,
    required this.productId,
    this.itemType = 'product',
    this.product,
    required this.quantity,
    required this.selections,
    required this.price,
    required this.subtotal,
  });

  factory StoreCartItem.fromJson(Map<String, dynamic> json) {
    return StoreCartItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? json['itemId']?.toString() ?? '',
      itemType: json['itemType']?.toString() ?? 'product',
      product: json['product'] != null ? StoreProduct.fromJson(json['product'] as Map<String, dynamic>) : null,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      selections: (json['selections'] as List?)?.map((s) => CartItemSelection.fromJson(s as Map<String, dynamic>)).toList() ?? [],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'itemType': itemType,
      'product': product?.toJson(),
      'quantity': quantity,
      'selections': selections.map((s) => s.toJson()).toList(),
      'price': price,
      'subtotal': subtotal,
    };
  }
}

class StoreCart {
  final List<StoreCartItem> items;
  final double subtotal;
  final double total;
  final int itemCount;

  StoreCart({
    required this.items,
    required this.subtotal,
    required this.total,
    required this.itemCount,
  });

  factory StoreCart.fromJson(Map<String, dynamic> json) {
    return StoreCart(
      items: (json['items'] as List?)?.map((item) => StoreCartItem.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'total': total,
      'itemCount': itemCount,
    };
  }
}

class StoreShippingAddress {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String governorate;
  final String postalCode;

  StoreShippingAddress({
    this.name = '',
    required this.phone,
    required this.address,
    required this.city,
    this.governorate = '',
    this.postalCode = '',
  });

  factory StoreShippingAddress.fromJson(Map<String, dynamic> json) {
    return StoreShippingAddress(
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      governorate: json['governorate']?.toString() ?? '',
      postalCode: json['postalCode']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'governorate': governorate,
      'postalCode': postalCode,
    };
  }
}

class StoreOrderItem {
  final String itemType; // 'product' or 'package'
  final String itemId;
  final StoreProduct? product;
  final int quantity;
  final double price;
  final List<CartItemSelection> selections;
  final double subtotal;

  StoreOrderItem({
    required this.itemType,
    required this.itemId,
    this.product,
    required this.quantity,
    required this.price,
    required this.selections,
    required this.subtotal,
  });

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    // Determine the product details from populated or nested object
    dynamic prodJson = json['product'] ?? json['itemId'];
    StoreProduct? product;
    if (prodJson != null && prodJson is Map) {
      // Check if itemType is package and format has schoolPackage coverImage/title etc.
      product = StoreProduct.fromJson({
        ...prodJson,
        // map package details to product fields for display uniformity
        if (prodJson['title'] != null) 'title_en': prodJson['title'],
        if (prodJson['packagePrice'] != null) 'price': prodJson['packagePrice'],
        if (prodJson['coverImage'] != null) 'images': [prodJson['coverImage']],
      });
    }
    return StoreOrderItem(
      itemType: json['itemType']?.toString() ?? 'product',
      itemId: json['itemId'] is Map ? (json['itemId']['_id']?.toString() ?? '') : (json['itemId']?.toString() ?? ''),
      product: product,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      selections: (json['selections'] as List?)?.map((s) => CartItemSelection.fromJson(s as Map<String, dynamic>)).toList() ?? [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StoreOrder {
  final String id;
  final String orderNumber;
  final String paymentMethod;
  final String deliveryMethod;
  final StoreShippingAddress shippingAddress;
  final String notes;
  final String? school;
  final String status;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String createdAt;
  final List<StoreOrderItem> items;

  StoreOrder({
    required this.id,
    required this.orderNumber,
    required this.paymentMethod,
    required this.deliveryMethod,
    required this.shippingAddress,
    required this.notes,
    this.school,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    return StoreOrder(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      deliveryMethod: json['deliveryMethod']?.toString() ?? '',
      shippingAddress: json['shippingAddress'] != null 
          ? StoreShippingAddress.fromJson(json['shippingAddress'] as Map<String, dynamic>)
          : StoreShippingAddress(address: '', city: '', phone: ''),
      notes: json['notes']?.toString() ?? '',
      school: json['school']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt']?.toString() ?? '',
      items: (json['items'] as List?)?.map((item) => StoreOrderItem.fromJson(item as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderNumber': orderNumber,
      'paymentMethod': paymentMethod,
      'deliveryMethod': deliveryMethod,
      'shippingAddress': shippingAddress.toJson(),
      'notes': notes,
      'school': school,
      'status': status,
      'subtotal': subtotal,
      'discount': discount,
      'deliveryFee': deliveryFee,
      'total': total,
      'createdAt': createdAt,
    };
  }
}
