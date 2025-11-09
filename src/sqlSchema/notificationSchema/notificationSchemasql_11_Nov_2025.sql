 
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


