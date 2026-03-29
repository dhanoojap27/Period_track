// ============================================
// FLUTTER UI STRUCTURE - DELIVERY SYSTEM
// ============================================
// Complete screen implementations
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================
// 1. DELIVERY HOME SCREEN
// ============================================
class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  ConsumerState<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends ConsumerState<DeliveryHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Kit Banner
            _buildEmergencyKitBanner(),
            
            // Categories Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildCategoriesGrid(),
            
            // Featured Products
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Featured Products',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildFeaturedProducts(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyKitBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/emergency-kit'),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[400]!, Colors.orange[400]!],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚨 EMERGENCY KIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Need pads fast?\nGet instant relief delivered!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⚡ 30 min delivery',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.local_hospital,
              size: 80,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'Pads', 'icon': Icons.layers, 'color': Colors.pink},
      {'name': 'Tampons', 'icon': Icons.water_drop, 'color': Colors.blue},
      {'name': 'Medicine', 'icon': Icons.medication, 'color': Colors.red},
      {'name': 'Snacks', 'icon': Icons.cookie, 'color': Colors.orange},
      {'name': 'Heat Packs', 'icon': Icons.local_fire_department, 'color': Colors.deepOrange},
      {'name': 'Hygiene', 'icon': Icons.cleaning_services, 'color': Colors.teal},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(category: category);
      },
    );
  }

  Widget _buildFeaturedProducts() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return ProductCard(
            productId: index + 1,
            name: 'Premium Pads Pack',
            price: 199,
            image: 'assets/products/pads.png',
            isFeatured: true,
          );
        },
      ),
    );
  }
}

// ============================================
// 2. CATEGORY SCREEN
// ============================================
class CategoryScreen extends ConsumerWidget {
  final int categoryId;
  final String categoryName;

  const CategoryScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: FutureBuilder(
        future: ref.read(deliveryServiceProvider).getProductsByCategory(categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = (snapshot.data as Map)['data'] as List;
          
          if (products.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard.fromProductData(products[index]);
            },
          );
        },
      ),
    );
  }
}

// ============================================
// 3. PRODUCT LIST SCREEN
// ============================================
class ProductListScreen extends ConsumerWidget {
  final List<dynamic> products;

  const ProductListScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard.fromProductData(products[index]);
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter & Sort'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Price: Low to High'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Price: High to Low'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Top Rated'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 4. PRODUCT DETAILS SCREEN
// ============================================
class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name']),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Image.network(
              widget.product['image_urls'][0],
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${widget.product['price']}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (widget.product['discount_price'] != null)
                            Text(
                              '\$${widget.product['discount_price']}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('${widget.product['rating']} (${widget.product['total_reviews']} reviews)'),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product['description'],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quantity Selector
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) setState(() => quantity--);
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$quantity',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () {
                          if (quantity < widget.product['stock_quantity']) {
                            setState(() => quantity++);
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () async {
              await ref.read(deliveryServiceProvider).addToCart(
                productId: widget.product['id'],
                quantity: quantity,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart')),
                );
              }
            },
            icon: const Icon(Icons.shopping_cart),
            label: Text('Add to Cart - \$${widget.product['price'] * quantity}'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// 5. CART SCREEN
// ============================================
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Replace with actual cart items
              itemBuilder: (context, index) {
                return CartItemTile(index: index);
              },
            ),
          ),
          
          // Checkout Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 18)),
                      Text(
                        '\$999',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/checkout'),
                      child: const Text('Proceed to Checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// 6. CHECKOUT SCREEN
// ============================================
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String paymentMethod = 'cod';
  bool isEmergencyOrder = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Address
            _buildSectionTitle('Delivery Address'),
            _buildAddressCard(),
            
            // Order Summary
            _buildSectionTitle('Order Summary'),
            _buildOrderSummary(),
            
            // Payment Method
            _buildSectionTitle('Payment Method'),
            _buildPaymentOptions(),
            
            // Emergency Order Toggle
            SwitchListTile(
              title: const Text('🚨 Emergency Delivery'),
              subtitle: const Text('Get it in 30 minutes (+\$20)'),
              value: isEmergencyOrder,
              onChanged: (value) => setState(() => isEmergencyOrder = value),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => _placeOrder(),
            child: Text(isEmergencyOrder ? 'Place Emergency Order' : 'Place Order'),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('123 Main Street, Apt 4B\nNew York, NY 10001'),
            const SizedBox(height: 8),
            const Text('John Doe • +1 234 567 8900'),
            TextButton(
              onPressed: () {},
              child: const Text('Change Address'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRow('Subtotal', '\$999'),
            _buildRow('Delivery Fee', '\$30'),
            const Divider(),
            _buildRow('Total', '\$1029', isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        RadioListTile(
          title: const Text('Cash on Delivery'),
          value: 'cod',
          groupValue: paymentMethod,
          onChanged: (value) => setState(() => paymentMethod = value!),
        ),
        RadioListTile(
          title: const Text('Credit/Debit Card'),
          value: 'card',
          groupValue: paymentMethod,
          onChanged: (value) => setState(() => paymentMethod = value!),
        ),
        RadioListTile(
          title: const Text('UPI'),
          value: 'upi',
          groupValue: paymentMethod,
          onChanged: (value) => setState(() => paymentMethod = value!),
        ),
      ],
    );
  }

  void _placeOrder() async {
    try {
      final orderData = {
        'deliveryAddress': {'address': '123 Main St'},
        'paymentMethod': paymentMethod,
        'isEmergencyOrder': isEmergencyOrder,
      };

      final result = await ref.read(deliveryServiceProvider).createOrder(
        deliveryAddress: orderData['deliveryAddress'],
        paymentMethod: paymentMethod,
        isEmergencyOrder: isEmergencyOrder,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/order-tracking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// ============================================
// 7. ORDER TRACKING SCREEN
// ============================================
class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
      ),
      body: Column(
        children: [
          // Order Status Timeline
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusStep(
                  'Order Placed',
                  'Your order has been placed',
                  Icons.check_circle,
                  Colors.green,
                  completed: true,
                ),
                _buildStatusStep(
                  'Confirmed',
                  'Seller has confirmed your order',
                  Icons.check_circle,
                  Colors.green,
                  completed: true,
                ),
                _buildStatusStep(
                  'Out for Delivery',
                  'Your order is on the way',
                  Icons.local_shipping,
                  Colors.blue,
                  completed: false,
                  current: true,
                ),
                _buildStatusStep(
                  'Delivered',
                  'Order will be delivered soon',
                  Icons.home,
                  Colors.grey,
                  completed: false,
                ),
              ],
            ),
          ),

          // Delivery Partner Info
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage('https://example.com/driver.jpg'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mike Johnson', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Delivery Partner'),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                Text(' 4.8 (234 deliveries)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ETA
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Estimated Time'),
                    Text(
                      '25-30 minutes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStep(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    required bool completed,
    bool current = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: completed || current ? color : Colors.grey,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: completed || current ? color : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: completed || current ? null : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================
// WIDGET COMPONENTS
// ============================================

class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/category',
        arguments: {'id': 1, 'name': category['name']},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: (category['color'] as Color).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: category['color'] as Color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'] as IconData,
              size: 40,
              color: category['color'] as Color,
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final int? productId;
  final String? name;
  final double? price;
  final String? image;
  final bool? isFeatured;
  final Map<String, dynamic>? productData;

  const ProductCard({
    super.key,
    this.productId,
    this.name,
    this.price,
    this.image,
    this.isFeatured,
  }) : productData = null;

  const ProductCard.fromProductData(this.productData, {super.key})
      : productId = null,
        name = null,
        price = null,
        image = null,
        isFeatured = null;

  @override
  Widget build(BuildContext context) {
    final data = productData ?? {
      'id': productId,
      'name': name,
      'price': price,
      'image_urls': [image],
      'is_featured': isFeatured,
    };

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/product-details',
        arguments: data,
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  data['image_urls'][0],
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${data['price']}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final int index;

  const CartItemTile({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            child: Image.network('https://example.com/product.jpg', width: 100, height: 100, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('\$199', style: TextStyle(color: Colors.green)),
                  Row(
                    children: [
                      IconButton(onPressed: () {}, icon: const Icon(Icons.remove)),
                      const Text('2'),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
