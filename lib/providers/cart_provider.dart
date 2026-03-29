// ============================================
// CART PROVIDER - STATE MANAGEMENT
// ============================================
// Manages shopping cart state using Riverpod
// ============================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/delivery_api_service.dart';

// Cart notifier for state management
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  CartState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;

  CartNotifier(this.ref) : super(CartState(items: [], isLoading: false));

  /// Load cart from backend
  Future<void> loadCart(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final api = ref.read(deliveryApiServiceProvider);
      final response = await api.getCart(userId);
      
      if (response['success'] == true) {
        final itemsData = response['data'] as List;
        final items = itemsData
            .map((item) => CartItem.fromJson(item))
            .toList();
        
        state = state.copyWith(items: items, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add product to cart
  Future<bool> addToCart({
    required String userId,
    required Product product,
    int quantity = 1,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final api = ref.read(deliveryApiServiceProvider);
      final response = await api.addToCart(
        userId: userId,
        productId: product.id,
        quantity: quantity,
      );

      if (response['success'] == true) {
        // Reload cart to get updated data
        await loadCart(userId);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Remove item from cart
  Future<bool> removeFromCart({
    required String userId,
    required int productId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final api = ref.read(deliveryApiServiceProvider);
      final response = await api.removeFromCart(
        userId: userId,
        productId: productId,
      );

      if (response['success'] == true) {
        // Remove from local state
        state = state.copyWith(
          items: state.items.where((item) => item.productId != productId).toList(),
          isLoading: false,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Update item quantity
  Future<bool> updateQuantity({
    required String userId,
    required int productId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        return await removeFromCart(userId: userId, productId: productId);
      }

      state = state.copyWith(isLoading: true, error: null);

      final api = ref.read(deliveryApiServiceProvider);
      final response = await api.updateCartItem(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );

      if (response['success'] == true) {
        // Update local state
        state = state.copyWith(
          items: state.items.map((item) {
            if (item.productId == productId) {
              return CartItem(
                id: item.id,
                userId: item.userId,
                productId: item.productId,
                quantity: quantity,
                addedAt: item.addedAt,
                product: item.product,
              );
            }
            return item;
          }).toList(),
          isLoading: false,
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear cart
  void clearCart() {
    state = state.copyWith(items: []);
  }

  /// Check if product is in cart
  bool isInCart(int productId) {
    return state.items.any((item) => item.productId == productId);
  }

  /// Get quantity of product in cart
  int getQuantity(int productId) {
    final item = state.items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        id: 0,
        userId: '',
        productId: productId,
        quantity: 0,
        addedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }
}

// API Service Provider
final deliveryApiServiceProvider = Provider<DeliveryApiService>((ref) {
  return DeliveryApiService();
});
