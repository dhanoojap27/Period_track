const express = require('express');
const router = express.Router();
const { createClient } = require('@supabase/supabase-js');
const authMiddleware = require('../middleware/authMiddleware');

const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY
);

/**
 * @route   GET /api/notifications/admin
 * @desc    Get latest notifications for admin
 * @access  Private (Admin)
 */
router.get('/admin', authMiddleware, async (req, res) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('notifications')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(10);

    if (error) throw error;

    res.json({
      success: true,
      data
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * @route   PATCH /api/notifications/read/:id
 * @desc    Mark notification as read
 * @access  Private (Admin)
 */
router.patch('/read/:id', authMiddleware, async (req, res) => {
  try {
    const { error } = await supabaseAdmin
      .from('notifications')
      .update({ is_read: true })
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({ success: true, message: 'Notification marked as read' });
  } catch (error) {
    console.error('Mark read error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

/**
 * @route   DELETE /api/notifications/clear-all
 * @desc    Clear all notifications for admin
 * @access  Private (Admin)
 */
router.delete('/clear-all', authMiddleware, async (req, res) => {
  try {
    const { error } = await supabaseAdmin
      .from('notifications')
      .delete()
      .not('id', 'is', null); // Delete all

    if (error) throw error;

    res.json({ success: true, message: 'All notifications cleared' });
  } catch (error) {
    console.error('Clear notifications error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
