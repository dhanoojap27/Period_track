const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');

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
 * @route   POST /api/cart/add
 * @desc    Add product to cart or update quantity
 * @access  Public (or Private with auth)
 */
router.post('/add', async (req, res) => {
  try {
    const { userId, productId, quantity = 1 } = req.body;

    if (!userId || !productId) {
      return res.status(400).json({
        success: false,
        error: 'User ID and Product ID are required'
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

      const { data, error } = await supabaseAdmin
        .from('cart_items')
        .update({ quantity: newQuantity })
        .eq('id', existingItem.id)
        .select()
        .single();
        
      if (error) throw error;
      result = data;
    } else {
      // Add new item
      const { data, error } = await supabaseAdmin
        .from('cart_items')
        .insert([{
          user_id: userId,
          product_id: productId,
          quantity: quantity
        }])
        .select()
        .single();
        
      if (error) throw error;
      result = data;
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
 * @route   GET /api/cart/:userId
 * @desc    Get cart items for a user
 * @access  Public (or Private with auth)
 */
router.get('/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;

    const { data, error } = await supabaseAdmin
      .from('cart_items')
      .select(`
        *,
        products (
          id,
          name,
          price,
          discount_price,
          description,
          image_urls,
          category_id,
          stock_quantity,
          is_emergency_item,
          is_featured,
          rating,
          total_reviews
        )
      `)
      .eq('user_id', userId)
      .order('added_at', { ascending: false });

    if (error) throw error;

    // Calculate total
    const total = data.reduce((sum, item) => {
      const price = item.products.discount_price || item.products.price;
      return sum + (price * item.quantity);
    }, 0);

    res.json({
      success: true,
      count: data.length,
      data,
      total: parseFloat(total.toFixed(2))
    });
  } catch (error) {
    console.error('Get cart error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   DELETE /api/cart/:userId/:productId
 * @desc    Remove item from cart
 * @access  Public (or Private with auth)
 */
router.delete('/:userId/:productId', async (req, res) => {
  try {
    const { userId, productId } = req.params;

    const { error } = await supabaseAdmin
      .from('cart_items')
      .delete()
      .eq('user_id', userId)
      .eq('product_id', productId);

    if (error) throw error;

    res.json({
      success: true,
      message: 'Item removed from cart'
    });
  } catch (error) {
    console.error('Remove from cart error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   PUT /api/cart/update
 * @desc    Update cart item quantity
 * @access  Public (or Private with auth)
 */
router.put('/update', async (req, res) => {
  try {
    const { userId, productId, quantity } = req.body;

    if (!userId || !productId || !quantity) {
      return res.status(400).json({
        success: false,
        error: 'User ID, Product ID, and Quantity are required'
      });
    }

    if (quantity <= 0) {
      // If quantity is 0 or negative, remove the item
      const { error } = await supabase
        .from('cart_items')
        .delete()
        .eq('user_id', userId)
        .eq('product_id', productId);

      if (error) throw error;

      return res.json({
        success: true,
        message: 'Item removed from cart'
      });
    }

    const { data, error } = await supabaseAdmin
      .from('cart_items')
      .update({ 
        quantity: quantity
      })
      .eq('user_id', userId)
      .eq('product_id', productId)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: 'Cart updated successfully',
      data
    });
  } catch (error) {
    console.error('Update cart error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;
