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
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      titleEn: json['title_en']?.toString() ?? json['title']?.toString() ?? '',
      titleAr: json['title_ar']?.toString() ?? json['title_en']?.toString() ?? json['title']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      images: (json['images'] as List?)?.map((img) => img.toString()).toList() ?? [],
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      featured: json['featured'] as bool? ?? false,
    );
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
  final StoreProduct? product;
  final int quantity;
  final List<CartItemSelection> selections;
  final double price;
  final double subtotal;

  StoreCartItem({
    required this.id,
    required this.productId,
    this.product,
    required this.quantity,
    required this.selections,
    required this.price,
    required this.subtotal,
  });

  factory StoreCartItem.fromJson(Map<String, dynamic> json) {
    return StoreCartItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
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
  final String address;
  final String city;
  final String phone;

  StoreShippingAddress({
    required this.address,
    required this.city,
    required this.phone,
  });

  factory StoreShippingAddress.fromJson(Map<String, dynamic> json) {
    return StoreShippingAddress(
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'phone': phone,
    };
  }
}

class StoreOrder {
  final String id;
  final String paymentMethod;
  final String deliveryMethod;
  final StoreShippingAddress shippingAddress;
  final String notes;
  final String? school;
  final String status;
  final double total;
  final String createdAt;

  StoreOrder({
    required this.id,
    required this.paymentMethod,
    required this.deliveryMethod,
    required this.shippingAddress,
    required this.notes,
    this.school,
    required this.status,
    required this.total,
    required this.createdAt,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    return StoreOrder(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      deliveryMethod: json['deliveryMethod']?.toString() ?? '',
      shippingAddress: json['shippingAddress'] != null 
          ? StoreShippingAddress.fromJson(json['shippingAddress'] as Map<String, dynamic>)
          : StoreShippingAddress(address: '', city: '', phone: ''),
      notes: json['notes']?.toString() ?? '',
      school: json['school']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'paymentMethod': paymentMethod,
      'deliveryMethod': deliveryMethod,
      'shippingAddress': shippingAddress.toJson(),
      'notes': notes,
      'school': school,
      'status': status,
      'total': total,
      'createdAt': createdAt,
    };
  }
}
