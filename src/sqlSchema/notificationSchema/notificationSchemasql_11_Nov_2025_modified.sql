-- =====================================================
-- 🚀 ROLE-BASED NOTIFICATION SYSTEM (PostgreSQL)
-- =====================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- ENUM DEFINITIONS
-- =====================================================

-- Role keys
CREATE TYPE role_key_enum AS ENUM (
    'ADMIN',
    'MANAGER',
    'USER',
    'VIEWER'
);

-- Notification types
CREATE TYPE notification_type AS ENUM (
    'SYSTEM',
    'USER',
    'REQUEST',
    'APPROVAL',
    'ALERT'
);

-- Notification action statuses
CREATE TYPE notification_action_status AS ENUM (
    'NONE',
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED'
);

-- Notification delivery channels
CREATE TYPE notification_channel AS ENUM (
    'WEB',
    'EMAIL',
    'SMS',
    'PUSH'
);

-- Notification action types
CREATE TYPE notification_action_enum AS ENUM (
    'SENT',
    'DELIVERED',
    'VIEWED',
    'CLICKED',
    'READ',
    'DISMISSED',
    'FAILED',
    'APPROVED',
    'REJECTED'
);

-- =====================================================
-- ROLE & USER TABLES
-- =====================================================

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_key role_key_enum NOT NULL UNIQUE,
    role_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role_id UUID REFERENCES roles(id) ON DELETE SET NULL ON UPDATE CASCADE,
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- NOTIFICATION TEMPLATE TABLE
-- =====================================================

CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    type notification_type NOT NULL,
    title_template TEXT NOT NULL,
    message_template TEXT NOT NULL,
    default_metadata JSONB DEFAULT '{}'::jsonb,
    is_actionable BOOLEAN DEFAULT FALSE,
    action_config JSONB DEFAULT '{}'::jsonb,   -- e.g. {"approve_label": "Approve", "reject_label": "Reject"}
    default_duration INTERVAL,                 -- e.g. '2 hours'
    auto_schedule BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES notification_templates(id) ON DELETE SET NULL ON UPDATE CASCADE,
    type notification_type NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,

    -- Actionable Config
    is_actionable BOOLEAN DEFAULT FALSE,
    action_config JSONB DEFAULT '{}'::jsonb,
    action_status notification_action_status DEFAULT 'NONE',
    action_taken_by UUID REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    action_taken_at TIMESTAMP,

    -- Time-bound visibility
    start_time TIMESTAMP DEFAULT NOW(),
    end_time TIMESTAMP,
    is_expired BOOLEAN DEFAULT FALSE,
    CHECK ((end_time IS NULL) OR (end_time > start_time)),

    -- Audit
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- SENDERS TABLE
-- =====================================================

CREATE TABLE notification_senders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE ON UPDATE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (notification_id, sender_id)
);

-- =====================================================
-- RECIPIENTS TABLE
-- =====================================================

CREATE TABLE notification_recipients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE ON UPDATE CASCADE,
    recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    channel notification_channel DEFAULT 'WEB',
    metadata JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT FALSE,
    is_delivered BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    delivered_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (notification_id, recipient_id)
);

-- =====================================================
-- ACTION LOG TABLE
-- =====================================================

CREATE TABLE notification_action_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE ON UPDATE CASCADE,
    acted_by UUID REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE,
    channel notification_channel,
    action_type notification_action_enum NOT NULL,
    provider VARCHAR(100),
    provider_message_id VARCHAR(200),
    action_metadata JSONB,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- SCHEDULE JOBS TABLE
-- =====================================================

CREATE TABLE notification_schedule_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES notification_templates(id) ON DELETE SET NULL ON UPDATE CASCADE,
    payload JSONB DEFAULT '{}'::jsonb,         -- data to merge into template
    scheduled_for TIMESTAMP NOT NULL,          -- when to send
    executed_at TIMESTAMP,
    status TEXT DEFAULT 'PENDING',             -- PENDING | EXECUTED | FAILED
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- =====================================================
-- SAMPLE DATA
-- =====================================================

-- Roles
INSERT INTO roles (role_key, role_name, description) VALUES
('ADMIN', 'Administrator', 'Full access to all system modules'),
('MANAGER', 'Manager', 'Can manage users and notifications'),
('USER', 'Standard User', 'Can receive and act on notifications'),
('VIEWER', 'Viewer', 'Read-only access');

-- Users
INSERT INTO users (full_name, email, password, role_id)
SELECT 'Sumit Giri', 'sumit@example.com', 'hashedpassword123', id FROM roles WHERE role_key = 'ADMIN';

INSERT INTO users (full_name, email, password, role_id)
SELECT 'John Doe', 'john@example.com', 'hashedpassword456', id FROM roles WHERE role_key = 'USER';
