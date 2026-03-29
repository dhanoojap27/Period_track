// ============================================
// FLUTTER API SERVICE - DELIVERY SYSTEM
// ============================================
// API calls using http package
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class DeliveryApiService {
  static const String baseUrl = 'http://your-api-url.com/api'; // Replace with your actual API URL
  static const Duration timeout = Duration(seconds: 30);

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

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
      
      debugPrint('Fetching products from: $uri');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load products: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      rethrow;
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
      debugPrint('Error fetching products by category: $e');
      rethrow;
    }
  }

  // ============================================
  // CART API
  // ============================================

  /// Add product to cart
  Future<Map<String, dynamic>> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/cart/add');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
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
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  // ============================================
  // ORDERS API
  // ============================================

  /// Create a new order
  Future<Map<String, dynamic>> createOrder({
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
      debugPrint('Error creating order: $e');
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
      debugPrint('Error fetching orders: $e');
      rethrow;
    }
  }

  /// Update order status (Admin/Delivery Partner only)
  Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
    String? notes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/order/status/$orderId');
      
      final response = await http.patch(
        uri,
        headers: _headers,
        body: json.encode({
          'status': status,
          'notes': notes,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw ApiException(error['error'] ?? 'Failed to update order status', response.statusCode);
      }
    } catch (e) {
      debugPrint('Error updating order status: $e');
      rethrow;
    }
  }

  // ============================================
  // EMERGENCY KITS API
  // ============================================

  /// Get all emergency kits
  Future<Map<String, dynamic>> getEmergencyKits() async {
    try {
      final uri = Uri.parse('$baseUrl/emergency-kits');
      
      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to load emergency kits: ${response.statusCode}', response.statusCode);
      }
    } catch (e) {
      debugPrint('Error fetching emergency kits: $e');
      rethrow;
    }
  }

  /// Order emergency kit
  Future<Map<String, dynamic>> orderEmergencyKit({
    required int kitId,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/emergency-kit/order/$kitId');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode({
          'deliveryAddress': deliveryAddress,
        }),
      ).timeout(timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw ApiException(error['error'] ?? 'Failed to order emergency kit', response.statusCode);
      }
    } catch (e) {
      debugPrint('Error ordering emergency kit: $e');
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
