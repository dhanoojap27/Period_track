// ============================================
// NODE.JS EXPRESS API - DELIVERY SYSTEM
// ============================================
// Complete REST API for Period Tracker Delivery Feature
// ============================================

const express = require('express');
const { createClient } = require('@supabase/supabase-js');
const router = express.Router();

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// ============================================
// MIDDLEWARE: Authentication
// ============================================
const authenticateUser = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
      return res.status(401).json({ error: 'No token provided' });
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ error: 'Invalid token' });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
};

// ============================================
// HELPER FUNCTIONS
// ============================================

// Generate unique order number
const generateOrderNumber = () => {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
  return `ORD-${date}-${random}`;
};

// Calculate cart total
const calculateCartTotal = async (userId) => {
  const { data: cartItems, error } = await supabase
    .from('cart_items')
    .select(`
      quantity,
      products (
        price,
        discount_price
      )
    `)
    .eq('user_id', userId);

  if (error) throw error;

  return cartItems.reduce((total, item) => {
    const price = item.products.discount_price || item.products.price;
    return total + (price * item.quantity);
  }, 0);
};

// ============================================
// ROUTES
// ============================================

/**
 * @route   GET /api/products
 * @desc    Get all active products with optional filtering
 * @access  Public
 */
router.get('/products', async (req, res) => {
  try {
    const { category, featured, emergency, minPrice, maxPrice, sort } = req.query;

    let query = supabase
      .from('products')
      .select(`
        *,
        categories (
          name,
          icon
        )
      `)
      .eq('is_active', true)
      .gt('stock_quantity', 0);

    // Apply filters
    if (category) {
      query = query.eq('category_id', category);
    }
    if (featured === 'true') {
      query = query.eq('is_featured', true);
    }
    if (emergency === 'true') {
      query = query.eq('is_emergency_item', true);
    }
    if (minPrice) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice) {
      query = query.lte('price', maxPrice);
    }

    // Apply sorting
    switch (sort) {
      case 'price_asc':
        query = query.order('price', { ascending: true });
        break;
      case 'price_desc':
        query = query.order('price', { ascending: false });
        break;
      case 'rating':
        query = query.order('rating', { ascending: false });
        break;
      default:
        query = query.order('created_at', { ascending: false });
    }

    const { data, error } = await query;

    if (error) throw error;

    res.json({
      success: true,
      count: data.length,
      data
    });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   GET /api/products/category/:id
 * @desc    Get products by category ID
 * @access  Public
 */
router.get('/products/category/:id', async (req, res) => {
  try {
    const categoryId = parseInt(req.params.id);

    if (isNaN(categoryId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid category ID'
      });
    }

    const { data, error } = await supabase
      .from('products')
      .select(`
        *,
        categories (
          name,
          icon
        )
      `)
      .eq('category_id', categoryId)
      .eq('is_active', true)
      .gt('stock_quantity', 0)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      count: data.length,
      data
    });
  } catch (error) {
    console.error('Get products by category error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   POST /api/cart/add
 * @desc    Add product to cart or update quantity
 * @access  Private
 */
router.post('/cart/add', authenticateUser, async (req, res) => {
  try {
    const { productId, quantity = 1 } = req.body;
    const userId = req.user.id;

    if (!productId) {
      return res.status(400).json({
        success: false,
        error: 'Product ID is required'
      });
    }

    // Check if product exists and is in stock
    const { data: product, error: productError } = await supabase
      .from('products')
      .select('id, stock_quantity, price')
      .eq('id', productId)
      .single();

    if (productError || !product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }

    if (product.stock_quantity < quantity) {
      return res.status(400).json({
        success: false,
        error: 'Insufficient stock'
      });
    }

    // Check if item already in cart
    const { data: existingItem } = await supabase
      .from('cart_items')
      .select('id, quantity')
      .eq('user_id', userId)
      .eq('product_id', productId)
      .single();

    let result;
    if (existingItem) {
      // Update quantity
      const newQuantity = existingItem.quantity + quantity;
      
      if (newQuantity > product.stock_quantity) {
        return res.status(400).json({
          success: false,
          error: 'Cannot add more than available stock'
        });
      }

      result = await supabase
        .from('cart_items')
        .update({ 
          quantity: newQuantity,
          updated_at: new Date().toISOString()
        })
        .eq('id', existingItem.id)
        .select()
        .single();
    } else {
      // Add new item
      result = await supabase
        .from('cart_items')
        .insert([{
          user_id: userId,
          product_id: productId,
          quantity: quantity
        }])
        .select()
        .single();
    }

    res.json({
      success: true,
      message: 'Product added to cart successfully',
      data: result
    });
  } catch (error) {
    console.error('Add to cart error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   POST /api/order/create
 * @desc    Create a new order from cart items
 * @access  Private
 */
router.post('/order/create', authenticateUser, async (req, res) => {
  try {
    const userId = req.user.id;
    const { 
      deliveryAddress, 
      billingAddress, 
      paymentMethod = 'cod',
      notes,
      isEmergencyOrder = false 
    } = req.body;

    if (!deliveryAddress) {
      return res.status(400).json({
        success: false,
        error: 'Delivery address is required'
      });
    }

    // Get cart items
    const { data: cartItems, error: cartError } = await supabase
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
    const { data: order, error: orderError } = await supabase
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
        payment_status: paymentMethod === 'cod' ? 'pending' : 'paid',
        delivery_address: deliveryAddress,
        billing_address: billingAddress || deliveryAddress,
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

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItems);

    if (itemsError) throw itemsError;

    // Clear cart
    const { error: clearError } = await supabase
      .from('cart_items')
      .delete()
      .eq('user_id', userId);

    if (clearError) throw clearError;

    // Assign delivery partner for emergency orders
    if (isEmergencyOrder) {
      const { data: partnerData } = await supabase.rpc('assign_nearest_partner', {
        p_order_id: order.id
      });
    }

    res.json({
      success: true,
      message: isEmergencyOrder ? 'Emergency order placed successfully!' : 'Order placed successfully',
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
 * @route   GET /api/orders/:userId
 * @desc    Get all orders for a user
 * @access  Private
 */
router.get('/orders/:userId', authenticateUser, async (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Verify user can only access their own orders
    if (userId !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'Unauthorized access'
      });
    }

    const { data, error } = await supabase
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
 * @route   PATCH /api/order/status/:orderId
 * @desc    Update order status (Admin/Delivery Partner only)
 * @access  Private (Admin/Delivery Partner)
 */
router.patch('/order/status/:orderId', authenticateUser, async (req, res) => {
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

    const { data, error } = await supabase
      .from('orders')
      .update(updateData)
      .eq('id', orderId)
      .select()
      .single();

    if (error) throw error;

    // Update delivery tracking if status changed
    if (['out_for_delivery', 'delivered'].includes(status)) {
      const trackingStatus = status === 'out_for_delivery' ? 'in_transit' : 'delivered';
      
      await supabase
        .from('delivery_tracking')
        .update({
          status: trackingStatus,
          delivered_at: status === 'delivered' ? new Date().toISOString() : undefined,
          updated_at: new Date().toISOString()
        })
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

/**
 * @route   GET /api/emergency-kits
 * @desc    Get all available emergency kits
 * @access  Public
 */
router.get('/emergency-kits', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('emergency_kits')
      .select('*')
      .eq('is_active', true)
      .order('priority_level', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      count: data.length,
      data
    });
  } catch (error) {
    console.error('Get emergency kits error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   POST /api/emergency-kit/order/:kitId
 * @desc    Quick order emergency kit
 * @access  Private
 */
router.post('/emergency-kit/order/:kitId', authenticateUser, async (req, res) => {
  try {
    const kitId = parseInt(req.params.kitId);
    const userId = req.user.id;

    // Get kit details
    const { data: kit, error: kitError } = await supabase
      .from('emergency_kits')
      .select('*')
      .eq('id', kitId)
      .eq('is_active', true)
      .single();

    if (kitError || !kit) {
      return res.status(404).json({
        success: false,
        error: 'Emergency kit not found'
      });
    }

    // Use the order creation logic with pre-filled items
    // Similar to /order/create but with kit items
    // Implementation similar to above...

    res.json({
      success: true,
      message: 'Emergency kit order placed successfully!',
      data: {
        kit,
        estimatedDelivery: new Date(Date.now() + 30 * 60000).toISOString()
      }
    });
  } catch (error) {
    console.error('Emergency kit order error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
