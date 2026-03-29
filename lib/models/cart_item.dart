// ============================================
// CART ITEM MODEL
// ============================================

import 'product.dart';

class CartItem {
  final int id;
  final String userId;
  final int productId;
  final int quantity;
  final DateTime addedAt;
  final Product? product;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.addedAt,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      userId: json['user_id'],
      productId: json['product_id'],
      quantity: json['quantity'],
      addedAt: DateTime.parse(json['added_at']),
      product: (json['products'] != null) 
          ? Product.fromJson(json['products']) 
          : (json['product'] != null ? Product.fromJson(json['product']) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'added_at': addedAt.toIso8601String(),
    };
  }

  double get subtotal {
    if (product != null) {
      return product!.finalPrice * quantity;
    }
    return 0.0;
  }
}
