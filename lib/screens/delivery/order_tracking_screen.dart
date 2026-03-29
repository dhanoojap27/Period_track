// ============================================
// ORDER TRACKING SCREEN
// ============================================

import 'package:flutter/material.dart';
import '../../services/delivery_api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final DeliveryApiService _apiService = DeliveryApiService();
  Map<String, dynamic>? _trackingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    try {
      final response = await _apiService.getDeliveryTracking(widget.orderId);
      if (response['success'] == true) {
        setState(() {
          _trackingData = response['data'];
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      // If tracking record not found (404), maybe we just show order status
      try {
        final orderResponse = await _apiService.getOrderDetails(widget.orderId);
        if (orderResponse['success'] == true) {
          setState(() {
            _trackingData = {
              'status': orderResponse['data']['status'],
              'order_number': orderResponse['data']['order_number'],
            };
            _isLoading = false;
            _isBasicInfo = true;
          });
          return;
        }
      } catch (innerE) {
        debugPrint('Failed to load even basic order info: $innerE');
      }
      setState(() => _isLoading = false);
    }
  }

  bool _isBasicInfo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadTracking();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trackingData == null
              ? const Center(child: Text('No tracking data'))
              : _buildTrackingView(),
    );
  }

  Widget _buildTrackingView() {
    final status = _trackingData?['status'] ?? 'pending';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Status Card
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatStatus(status),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text('Estimated delivery: ${_getEstimatedDelivery()}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Timeline
          _buildTimeline(),

          const SizedBox(height: 24),

          // Delivery Partner Info
          if (_trackingData?['delivery_partner'] != null || _trackingData?['delivery_partners'] != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Partner',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildPartnerInfo(_trackingData?['delivery_partner'] ?? _trackingData?['delivery_partners']),
                  ],
                ),
              ),
            ),
          ] else if (_isBasicInfo) 
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'We are currently looking for a delivery partner to pick up your order.',
                        style: TextStyle(color: Colors.blue[900]),
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

  Widget _buildTimeline() {
    final steps = [
      {'status': 'confirmed', 'label': 'Order Confirmed'},
      {'status': 'processing', 'label': 'Processing'},
      {'status': 'shipped', 'label': 'Shipped'},
      {'status': 'out_for_delivery', 'label': 'Out for Delivery'},
      {'status': 'delivered', 'label': 'Delivered'},
    ];

    final currentStepIndex = steps.indexWhere((s) => s['status'] == _trackingData?['status']);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= currentStepIndex;
        final isCurrent = index == currentStepIndex;

        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.grey[300],
                    shape: BoxShape.circle,
                    border: isCurrent ? Border.all(color: Colors.green, width: 3) : null,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.close,
                    color: isCompleted ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isCompleted ? Colors.green : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step['label']!,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPartnerInfo(Map<String, dynamic>? partner) {
    if (partner == null) return const SizedBox.shrink();
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.person),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partner['name'] ?? 'Driver',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(partner['phone'] ?? '+1 234 567 890'),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: () {}, // Implement call logic if needed
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {

    switch (status) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.hourglass_empty;
      case 'shipped':
        return Icons.local_shipping;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.pending;
    }
  }

  String _formatStatus(String status) {
    return status.split('_').map((word) => 
      word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}'
    ).join(' ');
  }

  String _getEstimatedDelivery() {
    // Mock implementation - should come from backend
    return DateTime.now().add(const Duration(hours: 1)).toString();
  }
}
