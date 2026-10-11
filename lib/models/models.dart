class Product {
  final String id;
  final String name;
  final String sku;
  final double price;
  final int stockCount;
  final String manufacturerId;
  final List<String> categoryIds;
  final List<String> supplierIds;
  final DateTime? deletedAt;

  const Product({
    required this.id, required this.name, required this.sku, required this.price,
    required this.stockCount, required this.manufacturerId,
    required this.categoryIds, required this.supplierIds, this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    String? id, String? name, String? sku, double? price, int? stockCount, String? manufacturerId,
    List<String>? categoryIds, List<String>? supplierIds, DateTime? deletedAt, bool clearDeletedAt = false,
  }) {
    return Product(
      id: id ?? this.id, name: name ?? this.name, sku: sku ?? this.sku, price: price ?? this.price,
      stockCount: stockCount ?? this.stockCount, manufacturerId: manufacturerId ?? this.manufacturerId,
      categoryIds: categoryIds ?? this.categoryIds, supplierIds: supplierIds ?? this.supplierIds,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'sku': sku, 'price': price, 'stockCount': stockCount,
    'manufacturerId': manufacturerId, 'categoryIds': categoryIds, 'supplierIds': supplierIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? '',
    sku: json['sku'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    stockCount: int.tryParse(json['stockCount'].toString()) ?? 0,
    manufacturerId: json['manufacturerId']?.toString() ?? '',
    categoryIds: (json['categoryIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    supplierIds: (json['supplierIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    deletedAt: json['deletedAt'] == null || json['deletedAt'] == '' ? null : DateTime.tryParse(json['deletedAt'] as String),
  );
}

class Manufacturer {
  final String id;
  final String name;
  final int foundedYear;
  final String country;
  final DateTime? deletedAt;

  const Manufacturer({required this.id, required this.name, required this.foundedYear, required this.country, this.deletedAt});
  bool get isDeleted => deletedAt != null;

  Manufacturer copyWith({String? id, String? name, int? foundedYear, String? country, DateTime? deletedAt, bool clearDeletedAt = false}) => Manufacturer(
    id: id ?? this.id, name: name ?? this.name, foundedYear: foundedYear ?? this.foundedYear, country: country ?? this.country, deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt)
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'foundedYear': foundedYear, 'country': country, 'deletedAt': deletedAt?.toIso8601String()};
  
  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
    id: json['id']?.toString() ?? '', 
    name: json['name'] as String? ?? '', 
    foundedYear: int.tryParse(json['foundedYear'].toString()) ?? 0, 
    country: json['country'] as String? ?? '', 
    deletedAt: json['deletedAt'] == null || json['deletedAt'] == '' ? null : DateTime.tryParse(json['deletedAt'] as String)
  );
}

class Category {
  final String id; 
  final String name; 
  final DateTime? deletedAt;
  
  const Category({required this.id, required this.name, this.deletedAt});
  
  bool get isDeleted => deletedAt != null;

  Category copyWith({String? id, String? name, DateTime? deletedAt, bool clearDeletedAt = false}) => Category(
    id: id ?? this.id, name: name ?? this.name, deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt)
  );
  
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'deletedAt': deletedAt?.toIso8601String()};
  
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id']?.toString() ?? '', 
    name: json['name'] as String? ?? '', 
    deletedAt: json['deletedAt'] == null || json['deletedAt'] == '' ? null : DateTime.tryParse(json['deletedAt'] as String)
  );
}

class Supplier {
  final String id; 
  final String name; 
  final String contactEmail; 
  final DateTime? deletedAt;
  
  const Supplier({required this.id, required this.name, required this.contactEmail, this.deletedAt});
  
  bool get isDeleted => deletedAt != null;

  Supplier copyWith({String? id, String? name, String? contactEmail, DateTime? deletedAt, bool clearDeletedAt = false}) => Supplier(
    id: id ?? this.id, name: name ?? this.name, contactEmail: contactEmail ?? this.contactEmail, deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt)
  );
  
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'contactEmail': contactEmail, 'deletedAt': deletedAt?.toIso8601String()};
  
  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id']?.toString() ?? '', 
    name: json['name'] as String? ?? '', 
    contactEmail: json['contactEmail'] as String? ?? '', 
    deletedAt: json['deletedAt'] == null || json['deletedAt'] == '' ? null : DateTime.tryParse(json['deletedAt'] as String)
  );
}

class DiscountCard {
  final String number; 
  final String issuedAt;
  
  const DiscountCard({required this.number, required this.issuedAt});
  
  Map<String, dynamic> toJson() => {'number': number, 'issuedAt': issuedAt};
  
  factory DiscountCard.fromJson(Map<String, dynamic> json) => DiscountCard(
    number: json['number'] as String? ?? '', 
    issuedAt: json['issuedAt'] as String? ?? ''
  );
}

class Customer {
  final String id; 
  final String fullName; 
  final String email; 
  final DiscountCard card; 
  final DateTime? deletedAt;
  
  const Customer({required this.id, required this.fullName, required this.email, required this.card, this.deletedAt});
  
  bool get isDeleted => deletedAt != null;

  Customer copyWith({String? id, String? fullName, String? email, DiscountCard? card, DateTime? deletedAt, bool clearDeletedAt = false}) => Customer(
    id: id ?? this.id, fullName: fullName ?? this.fullName, email: email ?? this.email, card: card ?? this.card, deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt)
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'fullName': fullName, 'email': email, 'card': card.toJson(), 'deletedAt': deletedAt?.toIso8601String()
  };
  
  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id']?.toString() ?? '', 
    fullName: json['fullName'] as String? ?? '', 
    email: json['email'] as String? ?? '',
    card: DiscountCard.fromJson(json['card'] as Map<String, dynamic>? ?? {}),
    deletedAt: json['deletedAt'] == null || json['deletedAt'] == '' ? null : DateTime.tryParse(json['deletedAt'] as String)
  );
}

class Order {
  final String id;
  final String customerId;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime? deletedAt;

  const Order({required this.id, required this.customerId, required this.totalAmount, required this.status, required this.createdAt, this.deletedAt});
  
  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toJson() => {
    'id': id, 'customerId': customerId, 'totalAmount': totalAmount, 'status': status, 'createdAt': createdAt.toIso8601String(), 'deletedAt': deletedAt?.toIso8601String()
  };
  
  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id']?.toString() ?? '', 
    customerId: json['customerId']?.toString() ?? '',
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0, 
    status: json['status'] as String? ?? 'new',
    createdAt: json['createdAt'] != null && json['createdAt'] != '' ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
    deletedAt: json['deletedAt'] == null || json['deletedAt'] == '' ? null : DateTime.tryParse(json['deletedAt'] as String)
  );
}

class OrderItem {
  final String id; 
  final String orderId; 
  final String productId; 
  final int quantity; 
  final double price;
  
  const OrderItem({required this.id, required this.orderId, required this.productId, required this.quantity, required this.price});
  
  Map<String, dynamic> toJson() => {
    'id': id, 'orderId': orderId, 'productId': productId, 'quantity': quantity, 'price': price
  };
  
  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id']?.toString() ?? '', 
    orderId: json['orderId']?.toString() ?? '',
    productId: json['productId']?.toString() ?? '', 
    quantity: int.tryParse(json['quantity'].toString()) ?? 0,
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
  );
}