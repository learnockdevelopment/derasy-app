class Product {
  final String id;
  final String titleEn;
  final String titleAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? shortDescriptionEn;
  final String? shortDescriptionAr;
  final String? specificationsEn;
  final String? specificationsAr;
  final List<String> images;
  final List<String> tags;
  final Category? category;
  final List<SchoolInfo> schools;
  final double price;
  final Discount? discount;
  final List<ProductSelection> selections;
  final int stock;
  final String? sku;
  final bool isFeatured;
  final bool isActive;
  final int views;
  final int sales;
  final double rating;
  final int ratingCount;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    this.descriptionEn,
    this.descriptionAr,
    this.shortDescriptionEn,
    this.shortDescriptionAr,
    this.specificationsEn,
    this.specificationsAr,
    this.images = const [],
    this.tags = const [],
    this.category,
    this.schools = const [],
    required this.price,
    this.discount,
    this.selections = const [],
    required this.stock,
    this.sku,
    this.isFeatured = false,
    this.isActive = true,
    this.views = 0,
    this.sales = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'] ?? '',
      titleEn: json['title_en'] ?? '',
      titleAr: json['title_ar'] ?? '',
      descriptionEn: json['description_en'],
      descriptionAr: json['description_ar'],
      shortDescriptionEn: json['shortDescription_en'],
      shortDescriptionAr: json['shortDescription_ar'],
      specificationsEn: json['specifications_en'],
      specificationsAr: json['specifications_ar'],
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      schools: (json['schools'] as List<dynamic>?)?.map((e) => SchoolInfo.fromJson(e)).toList() ?? [],
      price: (json['price'] ?? 0).toDouble(),
      discount: json['discount'] != null ? Discount.fromJson(json['discount']) : null,
      selections: (json['selections'] as List<dynamic>?)?.map((e) => ProductSelection.fromJson(e)).toList() ?? [],
      stock: json['stock'] ?? 0,
      sku: json['sku'],
      isFeatured: json['isFeatured'] ?? false,
      isActive: json['isActive'] ?? true,
      views: json['views'] ?? 0,
      sales: json['sales'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title_en': titleEn,
      'title_ar': titleAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (shortDescriptionEn != null) 'shortDescription_en': shortDescriptionEn,
      if (shortDescriptionAr != null) 'shortDescription_ar': shortDescriptionAr,
      if (specificationsEn != null) 'specifications_en': specificationsEn,
      if (specificationsAr != null) 'specifications_ar': specificationsAr,
      'images': images,
      'tags': tags,
      if (category != null) 'category': category!.id,
      'schools': schools.map((s) => s.id).toList(),
      'price': price,
      if (discount != null) 'discount': discount!.toJson(),
      'selections': selections.map((s) => s.toJson()).toList(),
      'stock': stock,
      if (sku != null) 'sku': sku,
      'isFeatured': isFeatured,
    };
  }

  double getFinalPrice(String? schoolId) {
    double finalPrice = price;
    
    if (discount != null) {
      if (discount!.global != null && discount!.global! > 0) {
        finalPrice = price * (1 - discount!.global! / 100);
      }
      
      if (schoolId != null && discount!.schoolSpecific != null) {
        final schoolDiscount = discount!.schoolSpecific!.firstWhere(
          (d) => d.school == schoolId,
          orElse: () => SchoolDiscount(school: '', discount: 0),
        );
        if (schoolDiscount.discount > 0) {
          finalPrice = price * (1 - schoolDiscount.discount / 100);
        }
      }
    }
    
    return finalPrice;
  }
}

class Category {
  final String id;
  final String titleEn;
  final String titleAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? shortDescriptionEn;
  final String? shortDescriptionAr;
  final List<String> images;
  final String? parentId;
  final bool isActive;
  final String? slug;
  final int? order;
  final int? productCount;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    this.descriptionEn,
    this.descriptionAr,
    this.shortDescriptionEn,
    this.shortDescriptionAr,
    this.images = const [],
    this.parentId,
    this.isActive = true,
    this.slug,
    this.order,
    this.productCount,
    this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'] ?? '',
      titleEn: json['title_en'] ?? '',
      titleAr: json['title_ar'] ?? '',
      descriptionEn: json['description_en'],
      descriptionAr: json['description_ar'],
      shortDescriptionEn: json['shortDescription_en'],
      shortDescriptionAr: json['shortDescription_ar'],
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      parentId: json['parent']?.toString(),
      isActive: json['isActive'] ?? true,
      slug: json['slug'],
      order: json['order'],
      productCount: json['productCount'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title_en': titleEn,
      'title_ar': titleAr,
      if (descriptionEn != null) 'description_en': descriptionEn,
      if (descriptionAr != null) 'description_ar': descriptionAr,
      if (shortDescriptionEn != null) 'shortDescription_en': shortDescriptionEn,
      if (shortDescriptionAr != null) 'shortDescription_ar': shortDescriptionAr,
      'images': images,
      if (parentId != null) 'parent': parentId,
      'order': order,
    };
  }
}

class SchoolInfo {
  final String id;
  final String name;
  final String? slug;

  SchoolInfo({
    required this.id,
    required this.name,
    this.slug,
  });

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'],
    );
  }
}

class Discount {
  final double? global;
  final List<SchoolDiscount>? schoolSpecific;

  Discount({
    this.global,
    this.schoolSpecific,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      global: json['global']?.toDouble(),
      schoolSpecific: (json['schoolSpecific'] as List<dynamic>?)
          ?.map((e) => SchoolDiscount.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (global != null) 'global': global,
      if (schoolSpecific != null)
        'schoolSpecific': schoolSpecific!.map((s) => s.toJson()).toList(),
    };
  }
}

class SchoolDiscount {
  final String school;
  final double discount;

  SchoolDiscount({
    required this.school,
    required this.discount,
  });

  factory SchoolDiscount.fromJson(Map<String, dynamic> json) {
    return SchoolDiscount(
      school: json['school'] ?? '',
      discount: (json['discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'school': school,
      'discount': discount,
    };
  }
}

class ProductSelection {
  final String name;
  final String nameEn;
  final String nameAr;
  final List<SelectionOption> options;
  final bool required;

  ProductSelection({
    required this.name,
    required this.nameEn,
    required this.nameAr,
    required this.options,
    this.required = false,
  });

  factory ProductSelection.fromJson(Map<String, dynamic> json) {
    return ProductSelection(
      name: json['name'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => SelectionOption.fromJson(e))
          .toList() ?? [],
      required: json['required'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_en': nameEn,
      'name_ar': nameAr,
      'options': options.map((o) => o.toJson()).toList(),
      'required': required,
    };
  }
}

class SelectionOption {
  final String value;
  final String valueEn;
  final String valueAr;
  final double priceModifier;
  final String? image;

  SelectionOption({
    required this.value,
    required this.valueEn,
    required this.valueAr,
    this.priceModifier = 0.0,
    this.image,
  });

  factory SelectionOption.fromJson(Map<String, dynamic> json) {
    return SelectionOption(
      value: json['value'] ?? '',
      valueEn: json['value_en'] ?? '',
      valueAr: json['value_ar'] ?? '',
      priceModifier: (json['priceModifier'] ?? 0).toDouble(),
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'value_en': valueEn,
      'value_ar': valueAr,
      'priceModifier': priceModifier,
      if (image != null) 'image': image,
    };
  }
}

class CartItem {
  final String productId;
  final Product? product;
  final int quantity;
  final List<CartSelection> selections;
  final double price;
  final double subtotal;

  CartItem({
    required this.productId,
    this.product,
    required this.quantity,
    this.selections = const [],
    required this.price,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    print('🛒 [CART ITEM MODEL] Parsing cart item from JSON:');
    print('🛒 [CART ITEM MODEL] JSON keys: ${json.keys.toList()}');
    print('🛒 [CART ITEM MODEL] productId: ${json['productId']}');
    print('🛒 [CART ITEM MODEL] product: ${json['product']}');
    print('🛒 [CART ITEM MODEL] product type: ${json['product'].runtimeType}');
    print('🛒 [CART ITEM MODEL] quantity: ${json['quantity']}');
    print('🛒 [CART ITEM MODEL] price: ${json['price']}');
    print('🛒 [CART ITEM MODEL] subtotal: ${json['subtotal']}');
    
    // Handle product field - it can be either a Map (full product object) or a String (product ID)
    Product? product;
    if (json['product'] != null) {
      if (json['product'] is Map<String, dynamic>) {
        product = Product.fromJson(json['product']);
        print('🛒 [CART ITEM MODEL] Product parsed from object: ${product.titleAr}');
      } else if (json['product'] is String) {
        print('🛒 [CART ITEM MODEL] Product is a string ID: ${json['product']}');
        // Product is just an ID, will be null
        product = null;
      } else {
        print('🛒 [CART ITEM MODEL] Product has unexpected type: ${json['product'].runtimeType}');
        product = null;
      }
    } else {
      print('🛒 [CART ITEM MODEL] Product is null');
    }
    
    return CartItem(
      productId: json['productId'] ?? '',
      product: product,
      quantity: json['quantity'] ?? 1,
      selections: (json['selections'] as List<dynamic>?)
          ?.map((e) => CartSelection.fromJson(e))
          .toList() ?? [],
      price: (json['price'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'selections': selections.map((s) => s.toJson()).toList(),
    };
  }
}

class CartSelection {
  final String name;
  final String value;

  CartSelection({
    required this.name,
    required this.value,
  });

  factory CartSelection.fromJson(Map<String, dynamic> json) {
    return CartSelection(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}

class ShoppingCart {
  final List<CartItem> items;
  final double subtotal;
  final double total;
  final int itemCount;

  ShoppingCart({
    required this.items,
    required this.subtotal,
    required this.total,
    required this.itemCount,
  });

  factory ShoppingCart.fromJson(Map<String, dynamic> json) {
    print('🛒 [SHOPPING CART MODEL] Parsing cart from JSON:');
    print('🛒 [SHOPPING CART MODEL] JSON keys: ${json.keys.toList()}');
    print('🛒 [SHOPPING CART MODEL] items: ${json['items']}');
    print('🛒 [SHOPPING CART MODEL] subtotal: ${json['subtotal']}');
    print('🛒 [SHOPPING CART MODEL] total: ${json['total']}');
    print('🛒 [SHOPPING CART MODEL] itemCount: ${json['itemCount']}');
    
    final items = (json['items'] as List<dynamic>?)
        ?.map((e) {
          print('🛒 [SHOPPING CART MODEL] Parsing item: $e');
          return CartItem.fromJson(e);
        })
        .toList() ?? [];
    
    print('🛒 [SHOPPING CART MODEL] Parsed ${items.length} items');
    
    return ShoppingCart(
      items: items,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      itemCount: json['itemCount'] ?? 0,
    );
  }
}

class OrderItem {
  final String productId;
  final Product? product;
  final int quantity;
  final double price;
  final List<CartSelection> selections;
  final double subtotal;

  OrderItem({
    required this.productId,
    this.product,
    required this.quantity,
    required this.price,
    this.selections = const [],
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      selections: (json['selections'] as List<dynamic>?)
          ?.map((e) => CartSelection.fromJson(e))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }
}

class ShippingAddress {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String governorate;
  final String? postalCode;

  ShippingAddress({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.governorate,
    this.postalCode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      governorate: json['governorate'] ?? '',
      postalCode: json['postalCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'governorate': governorate,
      if (postalCode != null) 'postalCode': postalCode,
    };
  }
}

class Order {
  final String id;
  final UserInfo? user;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final ShippingAddress? shippingAddress;
  final String deliveryMethod;
  final String? notes;
  final String? adminNotes;
  final String? trackingNumber;
  final String? transactionId;
  final String? schoolId;
  final DateTime? createdAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    this.user,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.deliveryFee = 0.0,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    this.shippingAddress,
    required this.deliveryMethod,
    this.notes,
    this.adminNotes,
    this.trackingNumber,
    this.transactionId,
    this.schoolId,
    this.createdAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'wallet',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      shippingAddress: json['shippingAddress'] != null
          ? ShippingAddress.fromJson(json['shippingAddress'])
          : null,
      deliveryMethod: json['deliveryMethod'] ?? 'pickup',
      notes: json['notes'],
      adminNotes: json['adminNotes'],
      trackingNumber: json['trackingNumber'],
      transactionId: json['transactionId'],
      schoolId: json['school']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt']) : null,
      shippedAt: json['shippedAt'] != null ? DateTime.parse(json['shippedAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
    );
  }
}

class UserInfo {
  final String id;
  final String name;
  final String email;

  UserInfo({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }
}


