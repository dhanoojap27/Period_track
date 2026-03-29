import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/cart_provider.dart';
import '../../services/delivery_api_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final bool isEmergencyOrder;
  const CheckoutScreen({super.key, this.isEmergencyOrder = false});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeliveryApiService _apiService = DeliveryApiService();
  
  String paymentMethod = 'cod';
  bool isProcessing = false;
  bool isZipLoading = false;

  @override
  void initState() {
    super.initState();
    _zipController.addListener(_onZipChanged);
  }

  void _onZipChanged() {
    final zip = _zipController.text.trim();
    if (zip.length == 6) {
      _lookupZip(zip);
    }
  }

  Future<void> _lookupZip(String zip) async {
    setState(() => isZipLoading = true);
    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$zip'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
          setState(() {
            _cityController.text = postOffice['District'] ?? '';
            _stateController.text = postOffice['State'] ?? '';
          });
        }
      }
    } catch (e) {
      debugPrint('ZIP lookup failed: $e');
    } finally {
      if (mounted) setState(() => isZipLoading = false);
    }
  }

  // Address fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isProcessing = true);

    try {
      final userId = Supabase.instance.client.auth.currentSession?.user.id;
      if (userId == null) throw Exception('Please login to place order');

      final deliveryAddress = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipController.text,
      };

      final response = await _apiService.createOrder(
        userId: userId,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        isEmergencyOrder: widget.isEmergencyOrder,
      );

      if (response['success'] == true && mounted) {
        // Clear cart
        ref.read(cartProvider.notifier).clearCart();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentMethod == 'online' 
              ? 'Order placed! Payment awaiting verification.' 
              : 'Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Items (${cartState.itemCount})'),
                        Text('₹${cartState.total.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${cartState.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delivery Address
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      maxLength: 50,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixText: '+91 ',
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v?.length ?? 0) != 10 ? 'Enter valid 10-digit phone' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _zipController,
                      decoration: InputDecoration(
                        labelText: 'Pincode (ZIP)',
                        suffixIcon: isZipLoading ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ) : null,
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v?.length ?? 0) != 6 ? 'Enter valid 6-digit pincode' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Flat/House No., Building, Street'),
                      maxLines: 2,
                      maxLength: 150,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(labelText: 'State'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Payment Method
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      value: 'cod',
                      groupValue: paymentMethod,
                      onChanged: (v) => setState(() => paymentMethod = v!),
                      title: const Text('Cash on Delivery'),
                    ),
                    RadioListTile<String>(
                      value: 'online',
                      groupValue: paymentMethod,
                      onChanged: (v) => setState(() => paymentMethod = v!),
                      title: const Text('Online Payment (QR Code)'),
                    ),
                    if (paymentMethod == 'online')
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Scan to Pay',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.network(
                                  'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${Uri.encodeComponent('upi://pay?pa=periodtracker@upi&pn=Period%20Tracker&am=${cartState.total.toStringAsFixed(2)}&cu=INR')}',
                                  height: 180,
                                  width: 180,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 100),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Scan this QR with any payment app to pay ₹${cartState.total.toStringAsFixed(2)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Place Order Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isProcessing ? null : _placeOrder,
                    child: isProcessing
                        ? const CircularProgressIndicator()
                        : const Text('Place Order'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
