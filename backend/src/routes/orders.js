const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const authMiddleware = require('../middleware/authMiddleware');

// Public client for reads
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Admin client bypasses RLS for writes
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY
);

// Helper function to generate order number
const generateOrderNumber = () => {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `ORD-${date}-${random}`;
};

/**
 * @route   POST /api/order/create
 * @desc    Create a new order from cart items
 * @access  Public (or Private with auth)
 */
router.post('/create', async (req, res) => {
  try {
    const { 
      userId,
      deliveryAddress, 
      billingAddress, 
      paymentMethod = 'cod',
      notes,
      isEmergencyOrder = false 
    } = req.body;

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'User ID is required'
      });
    }

    if (!deliveryAddress) {
      return res.status(400).json({
        success: false,
        error: 'Delivery address is required'
      });
    }

    // Get cart items
    const { data: cartItems, error: cartError } = await supabaseAdmin
      .from('cart_items')
      .select(`
        product_id,
        quantity,
        products (
          id,
          name,
          price,
          discount_price,
          stock_quantity
        )
      `)
      .eq('user_id', userId);

    if (cartError || cartItems.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Cart is empty'
      });
    }

    // Calculate totals
    const subtotal = cartItems.reduce((total, item) => {
      const price = item.products.discount_price || item.products.price;
      return total + (price * item.quantity);
    }, 0);

    const deliveryFee = isEmergencyOrder ? 50 : 30;
    const discount = isEmergencyOrder ? (subtotal * 0.15) : 0; // 15% off on emergency orders
    const finalAmount = subtotal + deliveryFee - discount;

    // Generate order number
    const orderNumber = generateOrderNumber();

    // Create order
    const { data: order, error: orderError } = await supabaseAdmin
      .from('orders')
      .insert([{
        user_id: userId,
        order_number: orderNumber,
        status: 'pending',
        total_amount: subtotal,
        discount_amount: discount,
        delivery_fee: deliveryFee,
        final_amount: finalAmount,
        payment_method: paymentMethod,
        payment_status: paymentMethod === 'cod' ? 'pending' : 'awaiting_verification',
        delivery_address: typeof deliveryAddress === 'string' ? deliveryAddress : (deliveryAddress.address || ''),
        customer_name: typeof deliveryAddress === 'object' ? deliveryAddress.name : null,
        customer_phone: typeof deliveryAddress === 'object' ? deliveryAddress.phone : null,
        billing_address: billingAddress || (typeof deliveryAddress === 'string' ? deliveryAddress : (deliveryAddress.address || '')),
        notes: notes,
        is_emergency_order: isEmergencyOrder,
        estimated_delivery_time: new Date(Date.now() + (isEmergencyOrder ? 30 : 60) * 60000).toISOString()
      }])
      .select()
      .single();

    if (orderError) throw orderError;

    // Create order items
    const orderItems = cartItems.map(item => ({
      order_id: order.id,
      product_id: item.product_id,
      product_name: item.products.name,
      product_price: item.products.discount_price || item.products.price,
      quantity: item.quantity,
      subtotal: (item.products.discount_price || item.products.price) * item.quantity
    }));

    const { error: itemsError } = await supabaseAdmin
      .from('order_items')
      .insert(orderItems);

    if (itemsError) throw itemsError;

    // Clear cart
    const { error: clearError } = await supabaseAdmin
      .from('cart_items')
      .delete()
      .eq('user_id', userId);

    if (clearError) throw clearError;

    res.json({
      success: true,
      message: isEmergencyOrder ? '🚨 Emergency order placed successfully!' : 'Order placed successfully',
      data: {
        order,
        orderItems,
        estimatedDelivery: order.estimated_delivery_time
      }
    });
  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   GET /api/orders/all
 * @desc    Get all orders for admin
 * @access  Private (Admin)
 */
router.get('/all', authMiddleware, async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('orders')
      .select(`
        *,
        order_items (
          product_name,
          quantity,
          product_price,
          subtotal
        ),
        delivery_tracking (
          status,
          partner_id,
          delivery_partners (
            name,
            phone
          )
        )
      `)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      count: data.length,
      data
    });
  } catch (error) {
    console.error('Get all orders error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   GET /api/orders/:userId
 * @desc    Get all orders for a user
 * @access  Public (or Private with auth)
 */
router.get('/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;

    const { data, error } = await supabaseAdmin
      .from('orders')
      .select(`
        *,
        order_items (
          product_name,
          quantity,
          product_price,
          subtotal
        )
      `)
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      count: data.length,
      data
    });
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   GET /api/orders/details/:orderId
 * @desc    Get single order details
 * @access  Public (or Private with auth)
 */
router.get('/details/:orderId', async (req, res) => {
  try {
    const orderId = parseInt(req.params.orderId);

    if (isNaN(orderId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid order ID'
      });
    }

    const { data, error } = await supabaseAdmin
      .from('orders')
      .select(`
        *,
        order_items (
          product_name,
          quantity,
          product_price,
          subtotal
        )
      `)
      .eq('id', orderId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          success: false,
          error: 'Order not found'
        });
      }
      throw error;
    }

    res.json({
      success: true,
      data
    });
  } catch (error) {
    console.error('Get order details error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   PATCH /api/order/status/:orderId
 * @desc    Update order status (Admin/Delivery Partner only)
 * @access  Private (Admin/Delivery Partner)
 */
router.patch('/status/:orderId', authMiddleware, async (req, res) => {
  try {
    const orderId = parseInt(req.params.orderId);
    const { status, notes } = req.body;

    if (!status) {
      return res.status(400).json({
        success: false,
        error: 'Status is required'
      });
    }

    const validStatuses = [
      'pending', 'confirmed', 'processing', 
      'out_for_delivery', 'delivered', 'cancelled', 'refunded'
    ];

    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid status value'
      });
    }

    // Update order
    const updateData = {
      status,
      notes: notes || undefined,
      updated_at: new Date().toISOString()
    };

    // If delivered, set actual delivery time
    if (status === 'delivered') {
      updateData.actual_delivery_time = new Date().toISOString();
    }

    const { data, error } = await supabaseAdmin
      .from('orders')
      .update(updateData)
      .eq('id', orderId)
      .select()
      .single();

    if (error) throw error;

    // SYNC WITH DELIVERY TRACKING
    // If Admin updates status, ensure delivery_tracking is also updated
    const trackingStatusMap = {
      'processing': 'assigned',
      'out_for_delivery': 'in_transit',
      'delivered': 'delivered'
    };

    if (trackingStatusMap[status]) {
      const trackingUpdate = { 
        status: trackingStatusMap[status],
        updated_at: new Date().toISOString()
      };
      if (status === 'delivered') trackingUpdate.delivered_at = new Date().toISOString();

      await supabaseAdmin
        .from('delivery_tracking')
        .update(trackingUpdate)
        .eq('order_id', orderId);
    }

    res.json({
      success: true,
      message: 'Order status updated successfully',
      data
    });
  } catch (error) {
    console.error('Update order status error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
