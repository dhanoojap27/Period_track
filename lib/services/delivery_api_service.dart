// ============================================
// DELIVERY API SERVICE
// ============================================
// Complete API service for Period Tracker Delivery System
// Handles all HTTP requests to the backend
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DeliveryApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api'; // Chrome/Web
    } else {
      return 'http://10.0.2.2:3000/api'; // Android Emulator
    }
  }
  static const Duration timeout = Duration(seconds: 10);

  // Singleton instance
  static final DeliveryApiService _instance = DeliveryApiService._internal();
  factory DeliveryApiService() => _instance;
  DeliveryApiService._internal();

  /// Proxy helper for external images to bypass CORS
  String getProxyUrl(String url) {
    if (url.isEmpty) return url;
    
    // If it's a data URI (base64), return as is (CORS-safe)
    if (url.startsWith('data:')) return url;
    
    // Add protocol if missing (important for Google images)
    String finalUrl = url;
    if (!url.startsWith('http')) {
      finalUrl = 'https://$url';
    }
    
    // Don't proxy if it's already a local or data URL
    if (finalUrl.contains('localhost') || finalUrl.contains('127.0.0.1')) return finalUrl;
    
    return '$baseUrl/proxy?url=${Uri.encodeComponent(finalUrl)}';
  }

  String? _authToken;

  /// Set authentication token from Supabase
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Get headers with optional auth
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ============================================
  // PRODUCTS API
  // ============================================

  /// Get all products with optional filters
  Future<Map<String, dynamic>> getProducts({
    String? category,
    bool? featured,
    bool? emergency,
    double? minPrice,
    double? maxPrice,
    String? sort,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (category != null) queryParams['category'] = category;
      if (featured != null) queryParams['featured'] = featured.toString();
      if (emergency != null) queryParams['emergency'] = emergency.toString();
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (sort != null) queryParams['sort'] = sort;

      final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
      
      debugPrint('🛍️ Fetching products from: $uri');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      debugPrint('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load products: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error fetching products, falling back to mock data: $e');
      return _getMockProductsData(featured: featured);
    }
  }

  /// Get products by category ID
  Future<Map<String, dynamic>> getProductsByCategory(int categoryId) async {
    try {
      final uri = Uri.parse('$baseUrl/products/category/$categoryId');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load products: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error fetching products by category, falling back to mock data: $e');
      final allMocks = _getMockProductsData()['data'] as List<Map<String, dynamic>>;
      final categoryMocks = allMocks.where((p) => p['category_id'] == categoryId).toList();
      return {'success': true, 'data': categoryMocks};
    }
  }

  /// Get single product by ID
  Future<Map<String, dynamic>> getProduct(int productId) async {
    try {
      final uri = Uri.parse('$baseUrl/products/$productId');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load product: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error fetching product, falling back to mock data: $e');
      final allMocks = _getMockProductsData()['data'] as List<Map<String, dynamic>>;
      final product = allMocks.firstWhere((p) => p['id'] == productId, orElse: () => allMocks.first);
      return {'success': true, 'data': product};
    }
  }

  // ============================================
  // MOCK DATA FALLBACK
  // ============================================

  Map<String, dynamic> _getMockProductsData({bool? featured}) {
    List<Map<String, dynamic>> allProducts = [
      {
        'id': 1,
        'name': 'Whisper Ultra Soft Pads (XL)',
        'price': 12.50,
        'discount_price': 10.00,
        'description': 'Super soft and comfortable pads for heavy flow.',
        'image_urls': ['https://placehold.co/400x400/FFB6C1/FFFFFF/png?text=Pads'],
        'category_id': 1,
        'categories': {'name': 'Pads', 'icon': 'layers'},
        'stock_quantity': 50,
        'is_emergency_item': true,
        'is_featured': true,
        'rating': 4.8,
        'total_reviews': 324,
      },
      {
        'id': 2,
        'name': 'Tampax Pearl Tampons (Regular)',
        'price': 8.99,
        'description': 'Leak-free protection for up to 8 hours.',
        'image_urls': ['https://placehold.co/400x400/FFB6C1/FFFFFF/png?text=Tampons'],
        'category_id': 2,
        'categories': {'name': 'Tampons', 'icon': 'droplet'},
        'stock_quantity': 30,
        'is_emergency_item': false,
        'is_featured': false,
        'rating': 4.5,
        'total_reviews': 128,
      },
      {
        'id': 3,
        'name': 'Advil Pain Reliever (200mg)',
        'price': 15.00,
        'discount_price': 12.99,
        'description': 'Fast relief from menstrual cramps and backaches.',
        'image_urls': ['https://placehold.co/400x400/87CEFA/FFFFFF/png?text=Pain+Relief'],
        'category_id': 3,
        'categories': {'name': 'Pain Relief', 'icon': 'medication'},
        'stock_quantity': 100,
        'is_emergency_item': true,
        'is_featured': true,
        'rating': 4.9,
        'total_reviews': 540,
      },
      {
        'id': 4,
        'name': 'Dark Chocolate Box',
        'price': 20.00,
        'description': 'Craving satisfaction with rich dark chocolate.',
        'image_urls': ['https://placehold.co/400x400/8B4513/FFFFFF/png?text=Chocolate'],
        'category_id': 4,
        'categories': {'name': 'Cravings', 'icon': 'cookie'},
        'stock_quantity': 20,
        'is_emergency_item': false,
        'is_featured': true,
        'rating': 4.7,
        'total_reviews': 89,
      },
      {
        'id': 5,
        'name': 'Cozy Heating Pad',
        'price': 25.99,
        'discount_price': 19.99,
        'description': 'Warmth to soothe those difficult days.',
        'image_urls': ['https://placehold.co/400x400/FFA07A/FFFFFF/png?text=Heating+Pad'],
        'category_id': 5,
        'categories': {'name': 'Heating', 'icon': 'local_fire_department'},
        'stock_quantity': 15,
        'is_emergency_item': true,
        'is_featured': false,
        'rating': 4.6,
        'total_reviews': 210,
      }
    ];

    if (featured == true) {
      allProducts = allProducts.where((p) => p['is_featured'] == true).toList();
    }

    return {
      'success': true,
      'data': allProducts,
    };
  }

  // ============================================
  // CART API
  // ============================================
  static final Map<String, List<Map<String, dynamic>>> _mockCarts = {};

  /// Add product to cart
  Future<Map<String, dynamic>> addToCart({
    required String userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/cart/add');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
        }),
      ).timeout(timeout);

      debugPrint('Add to cart response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw ApiException(error['error'] ?? 'Failed to add to cart', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error adding to cart, falling back to mock: $e');
      final cart = _mockCarts[userId] ?? [];
      final existingIndex = cart.indexWhere((item) => item['product_id'] == productId);
      if (existingIndex >= 0) {
        cart[existingIndex]['quantity'] = (cart[existingIndex]['quantity'] as int) + quantity;
      } else {
        final allMocks = _getMockProductsData()['data'] as List<Map<String, dynamic>>;
        final product = allMocks.firstWhere((p) => p['id'] == productId, orElse: () => allMocks.first);
        cart.add({
          'id': DateTime.now().millisecondsSinceEpoch,
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'added_at': DateTime.now().toIso8601String(),
          'products': product,
        });
      }
      _mockCarts[userId] = cart;
      return {'success': true, 'message': 'Added to cart'};
    }
  }

  /// Get user's cart
  Future<Map<String, dynamic>> getCart(String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/cart/$userId');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load cart: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error fetching cart, falling back to mock: $e');
      return {'success': true, 'data': _mockCarts[userId] ?? []};
    }
  }

  /// Remove item from cart
  Future<Map<String, dynamic>> removeFromCart({
    required String userId,
    required int productId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/cart/$userId/$productId');
      
      final response = await http.delete(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to remove from cart', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error removing from cart, falling back to mock: $e');
      final cart = _mockCarts[userId] ?? [];
      cart.removeWhere((item) => item['product_id'] == productId);
      _mockCarts[userId] = cart;
      return {'success': true, 'message': 'Removed from cart'};
    }
  }

  /// Update cart item quantity
  Future<Map<String, dynamic>> updateCartItem({
    required String userId,
    required int productId,
    required int quantity,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/cart/update');
      
      final response = await http.put(
        uri,
        headers: _headers,
        body: json.encode({
          'userId': userId,
          'productId': productId,
          'quantity': quantity,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to update cart', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error updating cart, falling back to mock: $e');
      final cart = _mockCarts[userId] ?? [];
      final existingIndex = cart.indexWhere((item) => item['product_id'] == productId);
      if (existingIndex >= 0) {
        cart[existingIndex]['quantity'] = quantity;
        _mockCarts[userId] = cart;
      }
      return {'success': true, 'message': 'Updated cart'};
    }
  }

  // ============================================
  // ORDERS API
  // ============================================

  /// Create a new order
  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required Map<String, dynamic> deliveryAddress,
    Map<String, dynamic>? billingAddress,
    String paymentMethod = 'cod',
    String? notes,
    bool isEmergencyOrder = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/order/create');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
          'userId': userId,
          'deliveryAddress': deliveryAddress,
          'billingAddress': billingAddress ?? deliveryAddress,
          'paymentMethod': paymentMethod,
          'notes': notes,
          'isEmergencyOrder': isEmergencyOrder,
        }),
      ).timeout(timeout);

      debugPrint('Create order response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw ApiException(error['error'] ?? 'Failed to create order', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error creating order: $e');
      rethrow;
    }
  }

  /// Get user orders
  Future<Map<String, dynamic>> getUserOrders(String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/$userId');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load orders: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      rethrow;
    }
  }

  /// Get order details
  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/orders/details/$orderId');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load order details', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error fetching order details: $e');
      rethrow;
    }
  }

  // ============================================
  // DELIVERY API
  // ============================================

  /// Get delivery tracking for order
  Future<Map<String, dynamic>> getDeliveryTracking(int orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/delivery/tracking/$orderId');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load delivery tracking', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error fetching delivery tracking: $e');
      rethrow;
    }
  }

  /// Get emergency kits
  Future<Map<String, dynamic>> getEmergencyKits() async {
    try {
      final uri = Uri.parse('$baseUrl/delivery/emergency-kits');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load emergency kits', response.statusCode);
      }
    } catch (e) {
      debugPrint('❌ Error fetching emergency kits: $e');
      rethrow;
    }
  }
}

// ============================================
// EXCEPTION CLASS
// ============================================

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
