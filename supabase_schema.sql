-- ============================================
-- PERIOD TRACKER - COMPLETE SUPABASE SCHEMA
-- ============================================
-- This schema includes all tables needed for:
-- - User authentication (via Supabase Auth)
-- - User profiles and settings
-- - Cycle tracking
-- - Predictions
-- - AI chat messages
-- - Notifications
-- ============================================

-- Drop existing tables if they exist (be careful if you have data!)
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS predictions CASCADE;
DROP TABLE IF EXISTS cycles CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;

-- ============================================
-- 1. USER PROFILES TABLE
-- ============================================
-- Stores detailed user information from questionnaire
CREATE TABLE user_profiles (
    user_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER NOT NULL,
    weight DOUBLE PRECISION NOT NULL,
    height DOUBLE PRECISION NOT NULL,
    cycle_length INTEGER NOT NULL DEFAULT 28,
    period_length INTEGER NOT NULL DEFAULT 5,
    last_period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    health_conditions JSONB DEFAULT '[]'::jsonb,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. USER SETTINGS TABLE
-- ============================================
-- Stores quick reference settings (denormalized for performance)
CREATE TABLE user_settings (
    user_id TEXT PRIMARY KEY,
    "cycleLength" INTEGER NOT NULL DEFAULT 28,
    "periodLength" INTEGER NOT NULL DEFAULT 5,
    "lastPeriodStart" TEXT NOT NULL,
    "age" INTEGER NOT NULL,
    "height" DOUBLE PRECISION NOT NULL,
    "weight" DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3. CYCLES TABLE
-- ============================================
-- Stores individual cycle/period entries with symptoms, mood, flow
CREATE TABLE cycles (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    "startDate" TEXT NOT NULL,
    "endDate" TEXT,
    symptoms JSONB DEFAULT '[]'::jsonb,
    mood JSONB DEFAULT '[]'::jsonb,
    "flowLevel" TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, "startDate")
);

-- ============================================
-- 4. PREDICTIONS TABLE
-- ============================================
-- Stores ML-based predictions for next period, ovulation, fertile window
CREATE TABLE predictions (
    user_id TEXT PRIMARY KEY,
    "nextPeriod" TEXT NOT NULL,
    "ovulationDay" TEXT NOT NULL,
    "fertileStart" TEXT NOT NULL,
    "fertileEnd" TEXT NOT NULL,
    "confidenceDays" INTEGER DEFAULT 2,
    "predictedCycleLength" DOUBLE PRECISION DEFAULT 28.0,
    trend TEXT DEFAULT 'stable',
    ml_model_version TEXT DEFAULT '1.0',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 5. CHAT MESSAGES TABLE
-- ============================================
-- Stores AI chat conversation history (both assistant and doctor modes)
CREATE TABLE chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    content TEXT NOT NULL,
    is_user BOOLEAN NOT NULL,
    chat_mode TEXT NOT NULL CHECK (chat_mode IN ('assistant', 'doctor')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    parent_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 6. NOTIFICATIONS TABLE (Optional)
-- ============================================
-- Stores notification preferences and history
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('period_reminder', 'ovulation_reminder', 'custom')),
    scheduled_time TIMESTAMP WITH TIME ZONE,
    is_sent BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- CREATE INDEXES FOR BETTER PERFORMANCE
-- ============================================
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

CREATE INDEX idx_cycles_user_id ON cycles(user_id);
CREATE INDEX idx_cycles_start_date ON cycles("startDate");
CREATE INDEX idx_cycles_user_start_date ON cycles(user_id, "startDate");

CREATE INDEX idx_predictions_user_id ON predictions(user_id);

CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_timestamp ON chat_messages(timestamp DESC);
CREATE INDEX idx_chat_messages_mode ON chat_messages(chat_mode);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_scheduled_time ON notifications(scheduled_time) WHERE is_sent = false;
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read) WHERE is_read = false;

-- ============================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES FOR USER_PROFILES
-- ============================================
CREATE POLICY "Users can view own profile"
    ON user_profiles FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own profile"
    ON user_profiles FOR DELETE
    USING (auth.uid()::text = user_id);

-- ============================================
-- RLS POLICIES FOR USER_SETTINGS
-- ============================================
CREATE POLICY "Users can view own settings"
    ON user_settings FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own settings"
    ON user_settings FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own settings"
    ON user_settings FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own settings"
    ON user_settings FOR DELETE
    USING (auth.uid()::text = user_id);

-- ============================================
-- RLS POLICIES FOR CYCLES
-- ============================================
CREATE POLICY "Users can view own cycles"
    ON cycles FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own cycles"
    ON cycles FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own cycles"
    ON cycles FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own cycles"
    ON cycles FOR DELETE
    USING (auth.uid()::text = user_id);

-- ============================================
-- RLS POLICIES FOR PREDICTIONS
-- ============================================
CREATE POLICY "Users can view own predictions"
    ON predictions FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own predictions"
    ON predictions FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own predictions"
    ON predictions FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own predictions"
    ON predictions FOR DELETE
    USING (auth.uid()::text = user_id);

-- ============================================
-- RLS POLICIES FOR CHAT_MESSAGES
-- ============================================
CREATE POLICY "Users can view own chat messages"
    ON chat_messages FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own chat messages"
    ON chat_messages FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own chat messages"
    ON chat_messages FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own chat messages"
    ON chat_messages FOR DELETE
    USING (auth.uid()::text = user_id);

-- ============================================
-- RLS POLICIES FOR NOTIFICATIONS
-- ============================================
CREATE POLICY "Users can view own notifications"
    ON notifications FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own notifications"
    ON notifications FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own notifications"
    ON notifications FOR UPDATE
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own notifications"
    ON notifications FOR DELETE
    USING (auth.uid()::text = user_id);

-- ============================================
-- TRIGGERS FOR UPDATED_AT TIMESTAMPS
-- ============================================
-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to user_profiles
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to user_settings
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to cycles
CREATE TRIGGER update_cycles_updated_at
    BEFORE UPDATE ON cycles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to predictions
CREATE TRIGGER update_predictions_updated_at
    BEFORE UPDATE ON predictions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================
COMMENT ON TABLE user_profiles IS 'Stores detailed user information including health data and preferences';
COMMENT ON TABLE user_settings IS 'Quick reference settings for user cycle tracking';
COMMENT ON TABLE cycles IS 'Individual menstrual cycle entries with symptoms, mood, and flow data';
COMMENT ON TABLE predictions IS 'ML-based predictions for period, ovulation, and fertile windows';
COMMENT ON TABLE chat_messages IS 'AI chat conversation history for both assistant and doctor modes';
COMMENT ON TABLE notifications IS 'Notification scheduling and history for period/ovulation reminders';

-- ============================================
-- SAMPLE DATA (OPTIONAL - REMOVE IN PRODUCTION)
-- ============================================
-- Uncomment below if you want to insert test data
-- You'll need to replace 'test-user-id' with an actual auth.uid()

-- INSERT INTO user_profiles (user_id, name, age, weight, height, cycle_length, period_length, last_period_start, health_conditions, is_completed)
-- VALUES ('test-user-id', 'Test User', 25, 65.0, 165.0, 28, 5, NOW() - INTERVAL '30 days', '[]', true);

-- INSERT INTO user_settings (user_id, "cycleLength", "periodLength", "lastPeriodStart", "age", "height", "weight")
-- VALUES ('test-user-id', 28, 5, (NOW() - INTERVAL '30 days')::text, 25, 165.0, 65.0);
