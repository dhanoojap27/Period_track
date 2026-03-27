-- Drop existing tables if they exist (be careful if you have data!)
DROP TABLE IF EXISTS predictions CASCADE;
DROP TABLE IF EXISTS cycles CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;

-- Create user_settings table (matches UserSettings model)
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

-- Create cycles table (matches CycleEntry model)
CREATE TABLE cycles (
    id SERIAL PRIMARY KEY,
    user_id TEXT NOT NULL,
    "startDate" TEXT NOT NULL,
    "endDate" TEXT,
    symptoms JSONB DEFAULT '[]'::jsonb,
    mood JSONB DEFAULT '[]'::jsonb,
    "flowLevel" TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, "startDate")
);

-- Create predictions table (matches Predictions model)
CREATE TABLE predictions (
    user_id TEXT PRIMARY KEY,
    "nextPeriod" TEXT NOT NULL,
    "ovulationDay" TEXT NOT NULL,
    "fertileStart" TEXT NOT NULL,
    "fertileEnd" TEXT NOT NULL,
    "confidenceDays" INTEGER DEFAULT 2,
    "predictedCycleLength" DOUBLE PRECISION DEFAULT 28.0,
    trend TEXT DEFAULT 'stable',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_cycles_user_id ON cycles(user_id);
CREATE INDEX idx_cycles_start_date ON cycles(start_date);

-- Enable Row Level Security (RLS)
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user_settings
CREATE POLICY "Users can view own settings" ON user_settings
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own settings" ON user_settings
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own settings" ON user_settings
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own settings" ON user_settings
    FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS policies for cycles
CREATE POLICY "Users can view own cycles" ON cycles
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own cycles" ON cycles
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own cycles" ON cycles
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own cycles" ON cycles
    FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS policies for predictions
CREATE POLICY "Users can view own predictions" ON predictions
    FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own predictions" ON predictions
    FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own predictions" ON predictions
    FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own predictions" ON predictions
    FOR DELETE USING (auth.uid()::text = user_id);
