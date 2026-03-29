require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function checkCart() {
  const { data, error } = await supabase
    .from('cart_items')
    .select('*, products(name)');
  
  if (error) {
    console.error('Error:', error);
  } else {
    console.log('Cart Items:', JSON.stringify(data, null, 2));
  }
}

checkCart();
