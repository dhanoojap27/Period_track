const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function migrate() {
  console.log('🚀 Starting migration for delivery_partners...');
  
  try {
    // Check if columns already exist (optional, but safer)
    const { error: alterError } = await supabase.rpc('execute_sql', {
      sql_query: `
        ALTER TABLE delivery_partners ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;
        ALTER TABLE delivery_partners ADD COLUMN IF NOT EXISTS password TEXT;
        
        -- Update demo driver if exists
        UPDATE delivery_partners 
         SET email = 'driver1@example.com', password = 'password123' 
         WHERE name = 'Demo Driver 1' AND email IS NULL;
      `
    });

    if (alterError) {
      // If RPC is not available, we can't run raw SQL directly through the client easily without a custom function.
      // Let's try a different approach: fetch, check, and update if possible, 
      // but for ALTER TABLE, the user might need to do it in the dashboard.
      console.log('Attempting alternative update (this requires columns to exist)...');
      
      const { data: updateData, error: updateError } = await supabase
        .from('delivery_partners')
        .update({ email: 'driver1@example.com', password: 'password123' })
        .eq('name', 'Demo Driver 1');
        
      if (updateError) throw updateError;
      console.log('✅ Demo driver credentials updated (assuming columns exist).');
    } else {
      console.log('✅ Migration successful via RPC.');
    }
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    console.log('\nIMPORTANT: Please run the following SQL in your Supabase SQL Editor:');
    console.log(`
      ALTER TABLE delivery_partners ADD COLUMN IF NOT EXISTS email TEXT UNIQUE;
      ALTER TABLE delivery_partners ADD COLUMN IF NOT EXISTS password TEXT;
      UPDATE delivery_partners SET email = 'driver1@example.com', password = 'password123' WHERE name = 'Demo Driver 1';
    `);
  }
}

migrate();
