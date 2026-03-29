import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/delivery_api_service.dart';
import 'checkout_screen.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyKitScreen extends ConsumerStatefulWidget {
  const EmergencyKitScreen({super.key});

  @override
  ConsumerState<EmergencyKitScreen> createState() => _EmergencyKitScreenState();
}

class _EmergencyKitScreenState extends ConsumerState<EmergencyKitScreen> {
  final DeliveryApiService _apiService = DeliveryApiService();
  List<Map<String, dynamic>> _kits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKits();
  }

  Future<void> _loadKits() async {
    try {
      final response = await _apiService.getEmergencyKits();
      if (response['success'] == true) {
        setState(() {
          _kits = (response['data'] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Kits'),
        backgroundColor: Colors.red[400],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _kits.isEmpty
              ? const Center(child: Text('No emergency kits available'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _kits.length,
                  itemBuilder: (context, index) {
                    return _buildKitCard(_kits[index]);
                  },
                ),
    );
  }

  Widget _buildKitCard(Map<String, dynamic> kit) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_hospital, color: Colors.red[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kit['name'] ?? 'Emergency Kit',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${kit['items_count'] ?? 0} items',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              kit['description'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${kit['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '⚡ ${kit['delivery_time'] ?? '30 min'} delivery',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _orderKit(kit),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Order Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _orderKit(Map<String, dynamic> kit) async {
    try {
      final userId = Supabase.instance.client.auth.currentSession?.user.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to order')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Emergency Order'),
          content: Text('Proceed with high-speed delivery for ${kit['name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  
                  // Clear existing cart for emergency priority
                  ref.read(cartProvider.notifier).clearCart();
                  
                  // Create a kit product
                  final kitProduct = Product(
                    id: kit['id'] as int, 
                    name: kit['name'],
                    price: (kit['price'] as num).toDouble(),
                    description: kit['description'],
                    imageUrls: [],
                    categoryId: 6,
                    stockQuantity: 100,
                    isEmergencyItem: true,
                    isFeatured: true,
                    rating: 5.0,
                    totalReviews: 0,
                  );

                  // Add to cart
                  final success = await ref.read(cartProvider.notifier).addToCart(
                    userId: userId,
                    product: kitProduct,
                    quantity: 1,
                  );

                  if (success && mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CheckoutScreen(isEmergencyOrder: true),
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not add kit to cart. Please try again.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order failed: ${e.toString()}')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              child: const Text('Order Now'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
