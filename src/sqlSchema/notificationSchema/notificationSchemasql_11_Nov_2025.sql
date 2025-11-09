-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1️⃣ Create enum for Role Key
CREATE TYPE role_key_enum AS ENUM (
    'ADMIN',
    'MANAGER',
    'USER',
    'VIEWER'
);

-- 2️⃣ Create Role Table
CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_key role_key_enum NOT NULL UNIQUE,       -- Enum key, ensures consistent role identification
    role_name VARCHAR(100) NOT NULL UNIQUE,       -- Readable name (e.g., "Administrator")
    description TEXT,                             -- Optional description of the role
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3️⃣ Create User Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role_id UUID REFERENCES roles(id) ON DELETE SET NULL, -- FK to roles
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB,                                      -- store extra info (optional)
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);


CREATE TYPE notification_type AS ENUM (
  'SYSTEM',
  'USER',
  'REQUEST',
  'APPROVAL',
  'ALERT'
);

CREATE TABLE notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  type notification_type NOT NULL,
  title_template TEXT NOT NULL,
  message_template TEXT NOT NULL,
  default_metadata JSONB DEFAULT '{}'::jsonb,
  is_actionable BOOLEAN DEFAULT FALSE,
  action_config JSONB DEFAULT '{}'::jsonb,    -- e.g. {"approve_label": "Approve", "reject_label": "Reject"}
  default_duration INTERVAL,                  -- e.g. '2 hours'
  auto_schedule BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TYPE notification_action_status AS ENUM ('NONE', 'PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID REFERENCES notification_templates(id),
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,         -- dynamic data such as {"folderName": "Finance", "user": "John"}

  -- Actionable Config
  is_actionable BOOLEAN DEFAULT FALSE,
  action_config JSONB DEFAULT '{}'::jsonb,
  action_status notification_action_status DEFAULT 'NONE',
  action_taken_by UUID REFERENCES users(id),
  action_taken_at TIMESTAMP,

  -- Time-bound visibility
  start_time TIMESTAMP DEFAULT NOW(),
  end_time TIMESTAMP,
  is_expired BOOLEAN DEFAULT FALSE,

  -- Audit metadata
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE notification_senders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  metadata JSONB DEFAULT '{}'::jsonb,
  UNIQUE (notification_id, sender_id)
);

CREATE TABLE notification_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  metadata JSONB DEFAULT '{}'::jsonb,  
  is_read BOOLEAN DEFAULT FALSE,
  is_delivered BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  delivered_at TIMESTAMP,
  UNIQUE (notification_id, recipient_id)
);

CREATE TABLE notification_action_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  acted_by UUID REFERENCES users(id),
  action_type VARCHAR(50) NOT NULL,        -- e.g., SENT, DELIVERED, VIEWED, CLICKED, READ, DISMISSED, FAILED, APPROVED, REJECTED,
  action_metadata JSONB,
  remarks TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE notification_schedule_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID REFERENCES notification_templates(id),
  payload JSONB DEFAULT '{}'::jsonb,        -- data to merge into template
  scheduled_for TIMESTAMP NOT NULL,         -- when to send
  executed_at TIMESTAMP,
  status TEXT DEFAULT 'PENDING',            -- PENDING | EXECUTED | FAILED
  created_at TIMESTAMP DEFAULT NOW()
);

-- CREATE TABLE event_logs (
--     id CHAR(36) PRIMARY KEY,
--     event_type VARCHAR(100),
--     payload JSON,
--     source_service VARCHAR(100),
--     status ENUM('received','processed','failed') DEFAULT 'received',
--     processed_at TIMESTAMP NULL,
--     error TEXT
-- );

-- CREATE TABLE notification_action_log (
--     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

--     notification_id UUID NOT NULL,           -- FK → notification table
--     user_id UUID NOT NULL,                   -- FK → user who received or acted on it
--     channel VARCHAR(50),                     -- e.g., 'EMAIL', 'SMS', 'WEB', 'PUSH'

--     action_type VARCHAR(50) NOT NULL,        -- e.g., SENT, DELIVERED, VIEWED, CLICKED, READ, DISMISSED, FAILED
--     action_metadata JSONB,                   -- optional details (e.g., IP, device info, failure reason)

--     created_at TIMESTAMP DEFAULT NOW(),      -- when the action occurred
--     updated_at TIMESTAMP DEFAULT NOW(),

--     CONSTRAINT fk_notification
--         FOREIGN KEY (notification_id) REFERENCES notifications(id)
--         ON DELETE CASCADE
-- );


