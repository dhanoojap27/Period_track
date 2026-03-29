const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const authMiddleware = require('../middleware/authMiddleware');
const deliveryAuthMiddleware = require('../middleware/deliveryAuthMiddleware');
const jwt = require('jsonwebtoken');

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

/**
 * @route   POST /api/delivery/login
 * @desc    Login for delivery partners
 * @access  Public
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'Email and password are required' });
    }

    // Direct check (for demo simplicity, normally we'd bcrypt compare)
    const { data: partner, error } = await supabaseAdmin
      .from('delivery_partners')
      .select('*')
      .eq('email', email)
      .eq('password', password)
      .single();

    if (error || !partner) {
      return res.status(401).json({ success: false, error: 'Invalid email or password' });
    }

    // Generate JWT
    const token = jwt.sign(
      { id: partner.id, email: partner.email, name: partner.name, role: 'partner' },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      partner: {
        id: partner.id,
        name: partner.name,
        phone: partner.phone,
        vehicle: partner.vehicle_number
      }
    });
  } catch (error) {
    console.error('Partner login error:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

/**
 * @route   GET /api/delivery/my-orders
 * @desc    Get assigned orders for the logged-in partner
 * @access  Private (Partner)
 */
router.get('/my-orders', deliveryAuthMiddleware, async (req, res) => {
  try {
    const partnerId = req.partner.id;

    const { data, error } = await supabaseAdmin
      .from('delivery_tracking')
      .select(`
        id,
        status,
        current_location,
        notes,
        updated_at,
        orders!inner (
          id,
          order_number,
          customer_name,
          customer_phone,
          delivery_address,
          total_amount,
          status,
          is_emergency_order,
          created_at,
          order_items (
            product_name,
            quantity
          )
        )
      `)
      .eq('partner_id', partnerId)
      .not('status', 'eq', 'delivered')
      .order('updated_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, count: data.length, data });
  } catch (error) {
    console.error('Get my active orders error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * @route   GET /api/delivery/my-history
 * @desc    Get completed orders for the partner
 * @access  Private (Partner)
 */
router.get('/my-history', deliveryAuthMiddleware, async (req, res) => {
  try {
    const partnerId = req.partner.id;

    const { data, error } = await supabaseAdmin
      .from('delivery_tracking')
      .select(`
        id,
        status,
        delivered_at,
        orders!inner (
          order_number,
          customer_name,
          delivery_address,
          total_amount
        )
      `)
      .eq('partner_id', partnerId)
      .eq('status', 'delivered')
      .order('delivered_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, count: data.length, data });
  } catch (error) {
    console.error('Get order history error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * @route   GET /api/delivery/partners
 * @desc    Get available delivery partners
 * @access  Private (Admin only)
 */
router.get('/partners', authMiddleware, async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('delivery_partners')
      .select('*')
      .eq('is_available', true)
      .eq('is_verified', true);

    if (error) throw error;

    res.json({
      success: true,
      count: data.length,
      data
    });
  } catch (error) {
    console.error('Get delivery partners error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   GET /api/delivery/tracking/:orderId
 * @desc    Get delivery tracking for an order
 * @access  Public (or Private with auth)
 */
router.get('/tracking/:orderId', async (req, res) => {
  try {
    const orderId = parseInt(req.params.orderId);

    if (isNaN(orderId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid order ID'
      });
    }

    const { data, error } = await supabaseAdmin
      .from('delivery_tracking')
      .select(`
        *,
        delivery_partners (
          name,
          phone,
          vehicle_number,
          rating
        )
      `)
      .eq('order_id', orderId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          success: false,
          error: 'Tracking information not found'
        });
      }
      throw error;
    }

    res.json({
      success: true,
      data: {
        ...data,
        delivery_partner: data.delivery_partners // Map plural key to singular for Flutter compatibility
      }
    });
  } catch (error) {
    console.error('Get delivery tracking error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   POST /api/delivery/assign
 * @desc    Assign delivery partner to order
 * @access  Private (Admin only)
 */
router.post('/assign', authMiddleware, async (req, res) => {
  try {
    const { orderId, partnerId } = req.body;

    if (!orderId || !partnerId) {
      return res.status(400).json({
        success: false,
        error: 'Order ID and Partner ID are required'
      });
    }

    // Remove any existing tracking records for this order to prevent duplicates
    await supabaseAdmin
      .from('delivery_tracking')
      .delete()
      .eq('order_id', orderId);

    // Create delivery tracking record
    const { data: assignmentData, error: assignmentError } = await supabaseAdmin
      .from('delivery_tracking')
      .insert([{
        order_id: orderId,
        partner_id: partnerId,
        status: 'assigned'
      }])
      .select()
      .single();

    if (assignmentError) throw assignmentError;

    // Persist partner_id in the main orders table for dashboard visibility
    await supabaseAdmin
      .from('orders')
      .update({ partner_id: partnerId })
      .eq('id', orderId);

    // Create notification for admin
    const { data: orderData } = await supabaseAdmin
      .from('orders')
      .select('order_number')
      .eq('id', orderId)
      .single();

    const { data: partnerData } = await supabaseAdmin
      .from('delivery_partners')
      .select('name')
      .eq('id', partnerId)
      .single();

    await supabaseAdmin
      .from('notifications')
      .insert([{
        message: `🚚 Order #${orderData.order_number} has been assigned to ${partnerData.name}.`,
        type: 'delivery_update',
        order_id: orderId,
        partner_id: partnerId
      }]);

    res.json({
      success: true,
      message: 'Delivery partner assigned successfully',
      data: assignmentData
    });

    // We successfully created the tracking record. 
    // We don't strictly need to update the redundant assigned_orders array on the partner table for now.
    // This ensures the operation is atomic and reliable.

    res.json({
      success: true,
      message: 'Delivery partner assigned successfully',
      data
    });
  } catch (error) {
    console.error('Assign delivery partner error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   PATCH /api/delivery/status-update/:trackingId
 * @desc    Update delivery status by partner
 * @access  Private (Partner)
 */
router.patch('/status-update/:trackingId', deliveryAuthMiddleware, async (req, res) => {
  try {
    const trackingId = parseInt(req.params.trackingId);
    const { status, currentLocation, notes } = req.body;
    const partnerId = req.partner.id;

    if (!status) {
      return res.status(400).json({ success: false, error: 'Status is required' });
    }

    // Verify ownership
    const { data: tracking, error: fetchErr } = await supabaseAdmin
      .from('delivery_tracking')
      .select('partner_id, order_id')
      .eq('id', trackingId)
      .single();

    if (fetchErr || !tracking || tracking.partner_id !== partnerId) {
      return res.status(403).json({ success: false, error: 'Forbidden: You do not have permission for this order' });
    }

    const validStatuses = ['assigned', 'picked_up', 'in_transit', 'delivered'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, error: 'Invalid status' });
    }

    const updateData = {
      status,
      current_location: currentLocation || undefined,
      notes: notes || undefined,
      updated_at: new Date().toISOString()
    };

    if (status === 'delivered') {
      updateData.delivered_at = new Date().toISOString();
    }

    const { data, error } = await supabaseAdmin
      .from('delivery_tracking')
      .update(updateData)
      .eq('id', trackingId)
      .select()
      .single();

    if (error) throw error;

    // Define mapping to update core Order status
    const orderStatusMap = {
      'assigned': 'processing',
      'picked_up': 'processing',
      'in_transit': 'out_for_delivery',
      'delivered': 'delivered'
    };

    await supabaseAdmin
      .from('orders')
      .update({ status: orderStatusMap[status] })
      .eq('id', tracking.order_id);

    // Create notification for admin
    const { data: orderInfo } = await supabaseAdmin
      .from('orders')
      .select('order_number')
      .eq('id', tracking.order_id)
      .single();

    const statusLabels = {
      'picked_up': 'picked up',
      'in_transit': 'out for delivery',
      'delivered': 'delivered'
    };

    if (status !== 'assigned') {
      await supabaseAdmin
        .from('notifications')
        .insert([{
          message: `📦 Order #${orderInfo.order_number} is now ${statusLabels[status] || status.replace('_', ' ')}.`,
          type: 'delivery_update',
          order_id: tracking.order_id,
          partner_id: partnerId
        }]);
    }

    res.json({
      success: true,
      message: `Delivery updated to ${status}`,
      data
    });
  } catch (error) {
    console.error('Partner status update error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * @route   GET /api/delivery/emergency-kits
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

module.exports = router;
