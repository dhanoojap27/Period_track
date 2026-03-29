-- ============================================
-- DELIVERY SYSTEM - SUPABASE DATABASE SCHEMA
-- ============================================
-- Complete schema for Period Tracker Delivery Feature
-- Includes: Users, Products, Cart, Orders, Delivery
-- ============================================

-- ============================================
-- DROP EXISTING TABLES (if they exist)
-- ============================================
-- This ensures a clean slate - WARNING: Deletes all data!
DROP TABLE IF EXISTS delivery_tracking CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS delivery_partners CASCADE;
DROP TABLE IF EXISTS emergency_kits CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Now create fresh tables

-- ============================================
-- 1. CATEGORIES TABLE
-- ============================================
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    image_url TEXT,
    icon VARCHAR(50),
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. PRODUCTS TABLE
-- ============================================
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    discount_price DECIMAL(10, 2) CHECK (discount_price >= 0 AND discount_price <= price),
    image_urls JSONB DEFAULT '[]'::jsonb,
    stock_quantity INTEGER DEFAULT 0 CHECK (stock_quantity >= 0),
    unit VARCHAR(50), -- e.g., "piece", "pack", "box"
    brand VARCHAR(100),
    is_emergency_item BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    rating DECIMAL(3, 2) DEFAULT 0.00 CHECK (rating >= 0.00 AND rating <= 5.00),
    total_reviews INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3. USERS TABLE (extends Supabase auth.users)
-- ============================================
CREATE TABLE users (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone VARCHAR(20),
    avatar_url TEXT,
    default_address JSONB,
    saved_addresses JSONB DEFAULT '[]'::jsonb,
    preferences JSONB DEFAULT '{}'::jsonb,
    loyalty_points INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. CART ITEMS TABLE
-- ============================================
CREATE TABLE cart_items (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- ============================================
-- 5. ORDERS TABLE
-- ============================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'confirmed', 'processing', 'out_for_delivery', 
        'delivered', 'cancelled', 'refunded'
    )),
    total_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0.00,
    delivery_fee DECIMAL(10, 2) DEFAULT 0.00,
    final_amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) DEFAULT 'cod' CHECK (payment_method IN ('cod', 'card', 'upi', 'wallet')),
    payment_status VARCHAR(50) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    delivery_address JSONB NOT NULL,
    billing_address JSONB,
    notes TEXT,
    is_emergency_order BOOLEAN DEFAULT false,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    actual_delivery_time TIMESTAMP WITH TIME ZONE,
    cancelled_by VARCHAR(20),
    cancellation_reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 6. ORDER ITEMS TABLE
-- ============================================
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    product_name VARCHAR(200) NOT NULL, -- Snapshot at time of order
    product_price DECIMAL(10, 2) NOT NULL, -- Price at time of order
    quantity INTEGER NOT NULL DEFAULT 1,
    subtotal DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 7. DELIVERY PARTNERS TABLE
-- ============================================
CREATE TABLE delivery_partners (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    vehicle_type VARCHAR(50), -- bike, scooter, car
    vehicle_number VARCHAR(20),
    license_number VARCHAR(50),
    current_location JSONB, -- {lat: number, lng: number}
    is_available BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    rating DECIMAL(3, 2) DEFAULT 0.00 CHECK (rating >= 0.00 AND rating <= 5.00),
    total_deliveries INTEGER DEFAULT 0,
    assigned_orders INTEGER[] DEFAULT '{}', -- Array of order IDs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 8. DELIVERY TRACKING TABLE
-- ============================================
CREATE TABLE delivery_tracking (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    partner_id INTEGER REFERENCES delivery_partners(id) ON DELETE SET NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'assigned' CHECK (status IN (
        'assigned', 'picked_up', 'in_transit', 'nearby', 'delivered', 'failed'
    )),
    location_history JSONB DEFAULT '[]'::jsonb, -- Array of {lat, lng, timestamp}
    current_location JSONB, -- {lat: number, lng: number}
    estimated_arrival TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    delivery_proof JSONB, -- {photo_url, signature, otp_verified}
    customer_feedback JSONB, -- {rating, comment}
    attempts INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 9. EMERGENCY KITS TABLE (Special Feature)
-- ============================================
CREATE TABLE emergency_kits (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    items JSONB NOT NULL, -- Array of {product_id, quantity}
    base_price DECIMAL(10, 2) NOT NULL,
    discount_percentage DECIMAL(5, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT true,
    priority_level VARCHAR(20) DEFAULT 'high' CHECK (priority_level IN ('normal', 'high', 'urgent')),
    average_delivery_time INTEGER DEFAULT 30, -- in minutes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- CREATE INDEXES FOR BETTER PERFORMANCE
-- ============================================
-- Categories
CREATE INDEX idx_categories_display_order ON categories(display_order);
CREATE INDEX idx_categories_is_active ON categories(is_active);

-- Products
CREATE INDEX idx_products_category_id ON products(category_id);
CREATE INDEX idx_products_is_emergency ON products(is_emergency_item);
CREATE INDEX idx_products_is_featured ON products(is_featured);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_products_stock ON products(stock_quantity);
CREATE INDEX idx_products_price ON products(price);

-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_is_active ON users(is_active);

-- Cart Items
CREATE INDEX idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX idx_cart_items_product_id ON cart_items(product_id);
CREATE INDEX idx_cart_items_user_product ON cart_items(user_id, product_id);

-- Orders
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_is_emergency ON orders(is_emergency_order);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);

-- Order Items
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Delivery Partners
CREATE INDEX idx_delivery_partners_available ON delivery_partners(is_available);
CREATE INDEX idx_delivery_partners_verified ON delivery_partners(is_verified);

-- Delivery Tracking
CREATE INDEX idx_delivery_tracking_order_id ON delivery_tracking(order_id);
CREATE INDEX idx_delivery_tracking_partner_id ON delivery_tracking(partner_id);
CREATE INDEX idx_delivery_tracking_status ON delivery_tracking(status);

-- Emergency Kits
CREATE INDEX idx_emergency_kits_active ON emergency_kits(is_active);
CREATE INDEX idx_emergency_kits_priority ON emergency_kits(priority_level);

-- ============================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE emergency_kits ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Categories: Public read, Admin write
CREATE POLICY "Anyone can view active categories" ON categories
    FOR SELECT USING (is_active = true);

-- Products: Public read, Admin write
CREATE POLICY "Anyone can view active products" ON products
    FOR SELECT USING (is_active = true AND stock_quantity > 0);

-- Users: Users can only view/update their own data
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = user_id);

-- Cart Items: Users can only manage their own cart
CREATE POLICY "Users can view own cart" ON cart_items
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can add to own cart" ON cart_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cart" ON cart_items
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete from own cart" ON cart_items
    FOR DELETE USING (auth.uid() = user_id);

-- Orders: Users can view their own orders
CREATE POLICY "Users can view own orders" ON orders
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders" ON orders
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Order Items: View through orders
CREATE POLICY "Users can view own order items" ON order_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = order_items.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Delivery Partners: Limited visibility
CREATE POLICY "Users can view available partners" ON delivery_partners
    FOR SELECT USING (is_available = true);

-- Delivery Tracking: Users can view tracking for their orders
CREATE POLICY "Users can view own delivery tracking" ON delivery_tracking
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM orders 
            WHERE orders.id = delivery_tracking.order_id 
            AND orders.user_id = auth.uid()
        )
    );

-- Emergency Kits: Public read
CREATE POLICY "Anyone can view active emergency kits" ON emergency_kits
    FOR SELECT USING (is_active = true);

-- ============================================
-- TRIGGERS FOR AUTO-UPDATES
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables with updated_at
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cart_items_updated_at BEFORE UPDATE ON cart_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_delivery_partners_updated_at BEFORE UPDATE ON delivery_partners
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_delivery_tracking_updated_at BEFORE UPDATE ON delivery_tracking
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emergency_kits_updated_at BEFORE UPDATE ON emergency_kits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCTIONS & PROCEDURES
-- ============================================

-- Function to generate unique order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
DECLARE
    new_order_number TEXT;
BEGIN
    SELECT 'ORD-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0')
    INTO new_order_number;
    RETURN new_order_number;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate cart total
CREATE OR REPLACE FUNCTION calculate_cart_total(p_user_id TEXT)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    total DECIMAL(10, 2);
BEGIN
    SELECT COALESCE(SUM(p.price * ci.quantity), 0)
    INTO total
    FROM cart_items ci
    JOIN products p ON ci.product_id = p.id
    WHERE ci.user_id = p_user_id;
    
    RETURN total;
END;
$$ LANGUAGE plpgsql;

-- Function to assign nearest delivery partner
CREATE OR REPLACE FUNCTION assign_nearest_partner(p_order_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    v_partner_id INTEGER;
BEGIN
    SELECT id INTO v_partner_id
    FROM delivery_partners
    WHERE is_available = true AND is_verified = true
    ORDER BY RANDOM() -- Replace with actual distance calculation
    LIMIT 1;
    
    IF v_partner_id IS NOT NULL THEN
        UPDATE delivery_partners
        SET assigned_orders = array_append(assigned_orders, p_order_id)
        WHERE id = v_partner_id;
        
        INSERT INTO delivery_tracking (order_id, partner_id, status)
        VALUES (p_order_id, v_partner_id, 'assigned');
    END IF;
    
    RETURN v_partner_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SEED DATA
-- ============================================

-- Insert sample categories
INSERT INTO categories (name, description, icon, display_order) VALUES
('Sanitary Pads', 'Disposable and reusable pads for period protection', 'layers', 1),
('Tampons', 'Compact and convenient tampons', 'droplet', 2),
('Menstrual Cups', 'Eco-friendly reusable cups', 'circle', 3),
('Pain Relief', 'Medicines for cramp relief', 'medication', 4),
('Comfort Foods', 'Snacks and drinks for comfort', 'fastfood', 5),
('Heat Therapy', 'Hot water bottles and heat patches', 'local_fire_department', 6),
('Hygiene Products', 'Wipes, sprays, and cleaning products', 'cleaning_services', 7),
('Wellness', 'Vitamins and supplements', 'self_improvement', 8);

-- Insert sample emergency kit
INSERT INTO emergency_kits (name, description, items, base_price, discount_percentage, priority_level, average_delivery_time) VALUES
('Emergency Period Care Kit', 'Essential items for immediate relief during periods', 
 '[{"product_id": 1, "quantity": 1, "name": "Sanitary Pads Pack"}, {"product_id": 10, "quantity": 1, "name": "Pain Relief Tablet"}, {"product_id": 20, "quantity": 1, "name": "Chocolate Bar"}]', 
 299.00, 15.00, 'urgent', 30);

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================
COMMENT ON TABLE categories IS 'Product categories for delivery system';
COMMENT ON TABLE products IS 'Available products for purchase';
COMMENT ON TABLE users IS 'User profiles with addresses and preferences';
COMMENT ON TABLE cart_items IS 'Shopping cart items for users';
COMMENT ON TABLE orders IS 'Order history and current orders';
COMMENT ON TABLE order_items IS 'Individual items in each order';
COMMENT ON TABLE delivery_partners IS 'Delivery personnel information';
COMMENT ON TABLE delivery_tracking IS 'Real-time order tracking';
COMMENT ON TABLE emergency_kits IS 'Pre-configured emergency period care kits';
