// ============================================
// PRODUCT MODEL
// ============================================

class Product {
  final int id;
  final String name;
  final double price;
  final double? discountPrice;
  final String description;
  final List<String> imageUrls;
  final int categoryId;
  final String? categoryName;
  final String? categoryIcon;
  final int stockQuantity;
  final bool isEmergencyItem;
  final bool isFeatured;
  final double rating;
  final int totalReviews;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice,
    required this.description,
    required this.imageUrls,
    required this.categoryId,
    this.categoryName,
    this.categoryIcon,
    required this.stockQuantity,
    required this.isEmergencyItem,
    required this.isFeatured,
    required this.rating,
    required this.totalReviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      price: double.parse(json['price'].toString()),
      discountPrice: json['discount_price'] != null 
          ? double.parse(json['discount_price'].toString()) 
          : null,
      description: json['description'] ?? '',
      imageUrls: json['image_urls'] != null 
          ? List<String>.from(json['image_urls']) 
          : (json['image_url'] != null ? [json['image_url'].toString()] : []),
      categoryId: json['category_id'] ?? 0,
      categoryName: json['categories']?['name'],
      categoryIcon: json['categories']?['icon'],
      stockQuantity: json['stock_quantity'] ?? 0,
      isEmergencyItem: json['is_emergency_item'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      rating: double.parse(json['rating'].toString()) ?? 0.0,
      totalReviews: json['total_reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'discount_price': discountPrice,
      'description': description,
      'image_urls': imageUrls,
      'category_id': categoryId,
      'stock_quantity': stockQuantity,
      'is_emergency_item': isEmergencyItem,
      'is_featured': isFeatured,
      'rating': rating,
      'total_reviews': totalReviews,
    };
  }

  double get finalPrice => discountPrice ?? price;
  
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  
  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }
}
