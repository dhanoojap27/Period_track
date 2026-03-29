const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const authMiddleware = require('../middleware/authMiddleware');

// Public client (anon key) for read operations
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Admin client (service role key) for write operations - bypasses RLS
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY
);

/**
 * @route   GET /api/products
 * @desc    Get all active products with optional filtering
 * @access  Public
 */
router.get('/', async (req, res) => {
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
router.get('/category/:id', async (req, res) => {
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
 * @route   GET /api/products/:id
 * @desc    Get single product by ID
 * @access  Public
 */
router.get('/:id', async (req, res) => {
  try {
    const productId = parseInt(req.params.id);

    if (isNaN(productId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid product ID'
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
      .eq('id', productId)
      .single();

    if (error) {
      if (error.code === 'PGRST116') {
        return res.status(404).json({
          success: false,
          error: 'Product not found'
        });
      }
      throw error;
    }

    res.json({
      success: true,
      data
    });
  } catch (error) {
    console.error('Get product error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * @route   POST /api/products
 * @desc    Create a new product (Admin)
 * @access  Private (Admin)
 */
router.post('/', authMiddleware, async (req, res) => {
  try {
    const newProduct = req.body;
    const { data, error } = await supabaseAdmin
      .from('products')
      .insert([newProduct])
      .select()
      .single();

    if (error) throw error;
    res.status(201).json({ success: true, data });
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * @route   PUT /api/products/:id
 * @desc    Update a product (Admin)
 * @access  Private (Admin)
 */
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const productId = parseInt(req.params.id);
    const updates = req.body;
    
    if (isNaN(productId)) {
      return res.status(400).json({ success: false, error: 'Invalid product ID' });
    }

    const { data, error } = await supabaseAdmin
      .from('products')
      .update(updates)
      .eq('id', productId)
      .select()
      .single();

    if (error) throw error;
    res.json({ success: true, data });
  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * @route   DELETE /api/products/:id
 * @desc    Delete a product (Admin - soft delete)
 * @access  Private (Admin)
 */
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const productId = parseInt(req.params.id);
    if (isNaN(productId)) {
      return res.status(400).json({ success: false, error: 'Invalid product ID' });
    }

    // Soft delete by setting is_active to false
    const { data, error } = await supabaseAdmin
      .from('products')
      .update({ is_active: false })
      .eq('id', productId)
      .select()
      .single();

    if (error) throw error;
    res.json({ success: true, message: 'Product disabled / deleted', data });
  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
