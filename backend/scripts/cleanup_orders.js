const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY
);

async function cleanup() {
  console.log('🧹 Starting cleanup of ghost active orders...');

  // 1. Get all orders marked as delivered in the main orders table
  const { data: deliveredOrders, error: orderErr } = await supabase
    .from('orders')
    .select('id, order_number')
    .eq('status', 'delivered');

  if (orderErr) {
    console.error('❌ Failed to fetch delivered orders:', orderErr);
    return;
  }

  console.log(`🔍 Found ${deliveredOrders.length} delivered orders in total.`);

  const deliveredIds = deliveredOrders.map(o => o.id);
  if (deliveredIds.length === 0) {
    console.log('✅ No delivered orders to sync.');
    return;
  }

  // 2. Find tracking entries for these orders that are NOT yet marked as delivered
  const { data: staleTracking, error: trackErr } = await supabase
    .from('delivery_tracking')
    .select('id, order_id, status')
    .in('order_id', deliveredIds)
    .neq('status', 'delivered');

  if (trackErr) {
    console.error('❌ Failed to fetch stale tracking records:', trackErr);
    return;
  }

  console.log(`⚠️ Found ${staleTracking.length} tracking records that need synchronization.`);

  if (staleTracking.length === 0) {
    console.log('✅ All tracking records are already synchronized.');
    return;
  }

  // 3. Update them to delivered
  const now = new Date().toISOString();
  const { error: updateErr } = await supabase
    .from('delivery_tracking')
    .update({ 
      status: 'delivered', 
      delivered_at: now,
      updated_at: now,
      notes: 'Auto-synchronized by cleanup script'
    })
    .in('id', staleTracking.map(t => t.id));

  if (updateErr) {
    console.error('❌ Failed to update tracking records:', updateErr);
  } else {
    console.log(`✅ Successfully synchronized ${staleTracking.length} orders. Delivery Partners should now see the correct history.`);
  }
}

cleanup().catch(console.error);
