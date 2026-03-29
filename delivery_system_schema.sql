-- ============================================
-- PERIOD TRACKER - DELIVERY SYSTEM SCHEMA
-- ============================================
-- Copy and paste this script into your Supabase SQL Editor to create 
-- all tables required by the new Delivery and Admin features.
-- ============================================

-- Drop existing tables to avoid conflicts
DROP TABLE IF EXISTS delivery_tracking CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS delivery_partners CASCADE;
DROP TABLE IF EXISTS emergency_kits CASCADE;


-- ============================================
-- 1. CATEGORIES TABLE
-- ============================================
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    icon TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Internal inserts for UI filtering (matching Flutter app)
INSERT INTO categories (name, icon) VALUES 
('Sanitary Pads', 'pad_icon'), 
('Tampons', 'tampon_icon'), 
('Pain Relief', 'pill_icon'),
('Comfort Foods', 'chocolate_icon');


-- ============================================
-- 2. PRODUCTS TABLE
-- ============================================
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    description TEXT,
    price NUMERIC NOT NULL,
    discount_price NUMERIC,
    stock_quantity INTEGER DEFAULT 0,
    image_urls TEXT[] DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    is_emergency_item BOOLEAN DEFAULT false,
    rating NUMERIC DEFAULT 0.0,
    total_reviews INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sample products (matching the 4 categories above)
INSERT INTO products (
    name, category_id, description, price, discount_price,
    stock_quantity, image_urls, is_active, is_featured, is_emergency_item,
    rating, total_reviews
) VALUES
(
    'Whisper Ultra Soft Pads (XL)', 1,
    'Super soft and comfortable pads for heavy flow. Leak-free protection all day.',
    12.50, 10.00, 50,
    ARRAY['https://placehold.co/400x400/FFB6C1/FFFFFF/png?text=Pads'],
    true, true, true, 4.8, 324
),
(
    'Stayfree Secure Pads (Regular)', 1,
    'Excellent absorption with soft cottony cover for regular flow days.',
    9.99, NULL, 80,
    ARRAY['https://placehold.co/400x400/FFB6C1/FFFFFF/png?text=Pads'],
    true, false, false, 4.5, 210
),
(
    'Tampax Pearl Tampons (Regular)', 2,
    'Leak-free protection for up to 8 hours. Easy to insert and remove.',
    8.99, NULL, 30,
    ARRAY['https://placehold.co/400x400/DDA0DD/FFFFFF/png?text=Tampons'],
    true, true, false, 4.5, 128
),
(
    'Advil Pain Reliever (200mg x20)', 3,
    'Fast relief from menstrual cramps, backaches and headaches.',
    15.00, 12.99, 100,
    ARRAY['https://placehold.co/400x400/87CEFA/FFFFFF/png?text=Pain+Relief'],
    true, true, true, 4.9, 540
),
(
    'Cadbury Dark Chocolate Box', 4,
    'Rich premium dark chocolate to satisfy those cravings during your period.',
    20.00, NULL, 20,
    ARRAY['https://placehold.co/400x400/8B4513/FFFFFF/png?text=Chocolate'],
    true, true, false, 4.7, 89
);


-- ============================================
-- 3. CART ITEMS TABLE
-- ============================================
CREATE TABLE cart_items (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ============================================
-- 4. ORDERS TABLE
-- ============================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    order_number TEXT UNIQUE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    total_amount NUMERIC NOT NULL,
    discount_amount NUMERIC DEFAULT 0,
    delivery_fee NUMERIC DEFAULT 0,
    final_amount NUMERIC NOT NULL,
    payment_method TEXT DEFAULT 'cod',
    payment_status TEXT DEFAULT 'pending',
    delivery_address TEXT NOT NULL,
    customer_name TEXT,
    customer_phone TEXT,
    billing_address TEXT,
    notes TEXT,
    is_emergency_order BOOLEAN DEFAULT false,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    actual_delivery_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ============================================
-- 5. ORDER ITEMS TABLE
-- ============================================
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    product_price NUMERIC NOT NULL,
    quantity INTEGER NOT NULL,
    subtotal NUMERIC NOT NULL
);


-- ============================================
-- 6. DELIVERY PARTNERS TABLE
-- ============================================
CREATE TABLE delivery_partners (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    password TEXT,
    phone TEXT NOT NULL,
    vehicle_number TEXT,
    rating NUMERIC DEFAULT 5.0,
    is_available BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT true,
    assigned_orders INTEGER[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert a default demo driver
INSERT INTO delivery_partners (name, email, password, phone, vehicle_number)
VALUES ('Demo Driver 1', 'driver1@example.com', 'password123', '+1234567890', 'XYZ-1234');


-- ============================================
-- 7. DELIVERY TRACKING TABLE
-- ============================================
CREATE TABLE delivery_tracking (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    partner_id INTEGER REFERENCES delivery_partners(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'assigned',
    current_location TEXT,
    notes TEXT,
    delivered_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ============================================
-- 8. EMERGENCY KITS TABLE
-- ============================================
CREATE TABLE emergency_kits (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL,
    is_active BOOLEAN DEFAULT true,
    priority_level INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ============================================
-- 9. NOTIFICATIONS TABLE (Admin Alerts)
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    message TEXT NOT NULL,
    type TEXT NOT NULL,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    partner_id INTEGER REFERENCES delivery_partners(id) ON DELETE SET NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


-- ============================================
-- INDEXES & PERFORMANCE
-- ============================================
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_cart_user ON cart_items(user_id);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_tracking_order ON delivery_tracking(order_id);


-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================
-- Keep these enabled to let your API and App read data correctly.

-- 1. Products and Categories (Publicly Readable)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Products are publicly readable" ON products FOR SELECT USING (true);

ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories are publicly readable" ON categories FOR SELECT USING (true);

-- 2. Cart Items (User Specific)
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can see their own cart items" ON cart_items FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can insert their own cart items" ON cart_items FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update their own cart items" ON cart_items FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete their own cart items" ON cart_items FOR DELETE USING (auth.uid()::text = user_id);

-- 3. Orders (User Specific)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can see their own orders" ON orders FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can create their own orders" ON orders FOR INSERT WITH CHECK (auth.uid()::text = user_id);

-- 4. Order Items (User Specific - via Order)
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can see their own order items" ON order_items FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM orders 
        WHERE orders.id = order_items.order_id 
        AND orders.user_id = auth.uid()::text
    )
);

-- 5. Delivery Tracking (User Specific - via Order)
ALTER TABLE delivery_tracking ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can see tracking for their own orders" ON delivery_tracking FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM orders 
        WHERE orders.id = delivery_tracking.order_id 
        AND orders.user_id = auth.uid()::text
    )
);
