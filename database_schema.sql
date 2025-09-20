-- SurakshaPay Database Schema
-- This file contains all the PostgreSQL queries needed to set up the database

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    pin_hash VARCHAR(255) NOT NULL,
    duress_pin_hash VARCHAR(255) NOT NULL,
    trusted_contact VARCHAR(15) NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00,
    upi_id VARCHAR(100) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Contacts table
CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) NOT NULL,
    upi_id VARCHAR(100),
    is_frequent BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, phone)
);

-- Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(15,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('sent', 'received', 'qr_payment')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    reference_id VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fraud logs table
CREATE TABLE IF NOT EXISTS fraud_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    fraud_type VARCHAR(50) NOT NULL CHECK (fraud_type IN ('duress_pin', 'gambling_detected', 'suspicious_transaction', 'voice_fraud')),
    description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    is_resolved BOOLEAN DEFAULT false,
    alert_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Voice commands log
CREATE TABLE IF NOT EXISTS voice_commands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    command_text TEXT NOT NULL,
    processed_text TEXT,
    action_taken VARCHAR(100),
    confidence_score DECIMAL(3,2),
    language VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- App settings
CREATE TABLE IF NOT EXISTS app_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    voice_enabled BOOLEAN DEFAULT true,
    preferred_language VARCHAR(10) DEFAULT 'hi-IN',
    tts_enabled BOOLEAN DEFAULT true,
    fraud_alerts_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_upi_id ON users(upi_id);
CREATE INDEX IF NOT EXISTS idx_contacts_user_id ON contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_sender_id ON transactions(sender_id);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver_id ON transactions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_fraud_logs_user_id ON fraud_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_logs_created_at ON fraud_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_voice_commands_user_id ON voice_commands(user_id);

-- Create functions for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_settings_updated_at BEFORE UPDATE ON app_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data for testing
INSERT INTO users (phone, name, pin_hash, duress_pin_hash, trusted_contact, balance, upi_id) VALUES
('9876543210', 'Priya Sharma', '$2a$10$example_hash_1', '$2a$10$example_hash_2', '9876543211', 12500.00, '9876543210@surakshapay'),
('8765432109', 'Ramesh Kumar', '$2a$10$example_hash_3', '$2a$10$example_hash_4', '8765432110', 8500.00, '8765432109@surakshapay'),
('7654321098', 'Sunita Devi', '$2a$10$example_hash_5', '$2a$10$example_hash_6', '7654321099', 15000.00, '7654321098@surakshapay')
ON CONFLICT (phone) DO NOTHING;

-- Insert sample contacts
INSERT INTO contacts (user_id, name, phone, upi_id, is_frequent) 
SELECT u.id, 'Ramesh Kumar', '8765432109', '8765432109@surakshapay', true
FROM users u WHERE u.phone = '9876543210'
UNION ALL
SELECT u.id, 'Sunita Devi', '7654321098', '7654321098@surakshapay', true
FROM users u WHERE u.phone = '9876543210'
UNION ALL
SELECT u.id, 'Amit Verma', '6543210987', '6543210987@surakshapay', false
FROM users u WHERE u.phone = '9876543210'
ON CONFLICT (user_id, phone) DO NOTHING;

-- Insert sample transactions
INSERT INTO transactions (sender_id, receiver_id, amount, transaction_type, status, reference_id, description)
SELECT 
    s.id, 
    r.id, 
    1000.00, 
    'sent', 
    'completed', 
    'SP' || EXTRACT(EPOCH FROM NOW())::bigint,
    'Payment via voice command'
FROM users s, users r 
WHERE s.phone = '9876543210' AND r.phone = '8765432109'
UNION ALL
SELECT 
    s.id, 
    r.id, 
    500.00, 
    'sent', 
    'completed', 
    'SP' || (EXTRACT(EPOCH FROM NOW())::bigint + 1),
    'Quick payment'
FROM users s, users r 
WHERE s.phone = '9876543210' AND r.phone = '7654321098'
ON CONFLICT (reference_id) DO NOTHING;

-- Insert app settings for sample users
INSERT INTO app_settings (user_id, voice_enabled, preferred_language, tts_enabled, fraud_alerts_enabled)
SELECT id, true, 'hi-IN', true, true FROM users
ON CONFLICT (user_id) DO NOTHING;

-- Create a view for transaction history with user names
CREATE OR REPLACE VIEW transaction_history AS
SELECT 
    t.id,
    t.amount,
    t.transaction_type,
    t.status,
    t.reference_id,
    t.description,
    t.created_at,
    sender.name as sender_name,
    sender.phone as sender_phone,
    receiver.name as receiver_name,
    receiver.phone as receiver_phone
FROM transactions t
JOIN users sender ON t.sender_id = sender.id
JOIN users receiver ON t.receiver_id = receiver.id
ORDER BY t.created_at DESC;

-- Create a function to check for fraud patterns
CREATE OR REPLACE FUNCTION check_fraud_patterns(
    p_user_id UUID,
    p_transaction_amount DECIMAL,
    p_description TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    gambling_keywords TEXT[] := ARRAY['bet', 'gambling', 'casino', 'poker', 'lottery', 'jackpot', 'शर्त', 'जुआ', 'कैसीनो', 'लॉटरी', 'जैकपॉट'];
    keyword TEXT;
    recent_transactions_count INTEGER;
BEGIN
    -- Check for gambling keywords in description
    IF p_description IS NOT NULL THEN
        FOREACH keyword IN ARRAY gambling_keywords LOOP
            IF LOWER(p_description) LIKE '%' || LOWER(keyword) || '%' THEN
                -- Log fraud attempt
                INSERT INTO fraud_logs (user_id, fraud_type, description, severity)
                VALUES (p_user_id, 'gambling_detected', 'Gambling keyword detected: ' || keyword, 'high');
                RETURN TRUE;
            END IF;
        END LOOP;
    END IF;
    
    -- Check for suspicious transaction patterns
    SELECT COUNT(*) INTO recent_transactions_count
    FROM transactions 
    WHERE sender_id = p_user_id 
    AND created_at > NOW() - INTERVAL '1 hour'
    AND amount > 10000;
    
    IF recent_transactions_count > 5 THEN
        INSERT INTO fraud_logs (user_id, fraud_type, description, severity)
        VALUES (p_user_id, 'suspicious_transaction', 'Multiple large transactions in short time', 'medium');
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- Grant necessary permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO anon;

