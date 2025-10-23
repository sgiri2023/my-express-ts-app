CREATE TABLE notification_templates (
    id CHAR(36) PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    title_template TEXT,
    body_template TEXT,
    channels JSON,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications (
    id CHAR(36) PRIMARY KEY,
    event_type VARCHAR(100),
    title VARCHAR(255),
    body TEXT,
    sender_ref VARCHAR(100),
    data JSON,
priority Enum('low','normal','high','critical'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
tenant_id CHAR(36) NULL,
);

CREATE TABLE recipients (
    id CHAR(36) PRIMARY KEY,
    external_ref VARCHAR(100) NOT NULL,
    type VARCHAR(50),
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notification_recipients (
    id CHAR(36) PRIMARY KEY,
    notification_id CHAR(36),
    recipient_id CHAR(36),
    status ENUM('pending','delivered','read','failed') DEFAULT 'pending',
    delivered_at TIMESTAMP NULL,
    read_at TIMESTAMP NULL,
    FOREIGN KEY (notification_id) REFERENCES notifications(id),
    FOREIGN KEY (recipient_id) REFERENCES recipients(id)
);

CREATE TABLE delivery_channels (
    id CHAR(36) PRIMARY KEY,
    notification_recipient_id CHAR(36),
    channel ENUM('in_app','email','push','sms','webhook'),
    status ENUM('pending','sent','delivered','failed') DEFAULT 'pending',
    details JSON,
    sent_at TIMESTAMP NULL,
    FOREIGN KEY (notification_recipient_id) REFERENCES notification_recipients(id)
);

CREATE TABLE channel_preferences (
    id CHAR(36) PRIMARY KEY,
    recipient_id CHAR(36),
    channel ENUM('in_app','email','push','sms'),
    enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (recipient_id) REFERENCES recipients(id)
);

CREATE TABLE event_logs (
    id CHAR(36) PRIMARY KEY,
    event_type VARCHAR(100),
    payload JSON,
    source_service VARCHAR(100),
    status ENUM('received','processed','failed') DEFAULT 'received',
    processed_at TIMESTAMP NULL,
    error TEXT
);



=======================================================

-- Table to store reusable notification templates
CREATE TABLE notification_templates (
    id CHAR(36) PRIMARY KEY,                        -- Unique ID for the template
    event_type VARCHAR(100) NOT NULL,               -- Type of event this template corresponds to
    title_template TEXT,                            -- Template for notification title
    body_template TEXT,                             -- Template for notification body/content
    channels JSON,                                  -- Channels to send notification (e.g., ["email","push"])
    active BOOLEAN DEFAULT TRUE,                    -- Whether the template is active
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Creation timestamp
);

-- Table to store actual notifications sent or to be sent
CREATE TABLE notifications (
    id CHAR(36) PRIMARY KEY,                        -- Unique notification ID
    event_type VARCHAR(100),                         -- Event type of the notification
    title VARCHAR(255),                              -- Actual notification title
    body TEXT,                                      -- Actual notification body/content
    sender_ref VARCHAR(100),                        -- Reference to sender (user/system)
    data JSON,                                      -- Additional dynamic data (e.g., {"invoiceId":123})
    priority Enum('low','normal','high','critical'), -- Notification priority
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Timestamp when notification was created
    tenant_id CHAR(36) NULL                         -- Optional tenant ID for multi-tenant systems
);

-- Table to store recipients of notifications
CREATE TABLE recipients (
    id CHAR(36) PRIMARY KEY,                        -- Unique recipient ID
    external_ref VARCHAR(100) NOT NULL,            -- Reference ID from external system (e.g., user ID)
    type VARCHAR(50),                               -- Recipient type (user/admin/system)
    metadata JSON,                                  -- Additional info about recipient
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Creation timestamp
);

-- Table to map notifications to recipients
CREATE TABLE notification_recipients (
    id CHAR(36) PRIMARY KEY,                        -- Unique ID
    notification_id CHAR(36),                        -- ID of the notification
    recipient_id CHAR(36),                            -- ID of the recipient
    status ENUM('pending','delivered','read','failed') DEFAULT 'pending', -- Status of notification for this recipient
    delivered_at TIMESTAMP NULL,                     -- Timestamp when delivered
    read_at TIMESTAMP NULL,                          -- Timestamp when read
    FOREIGN KEY (notification_id) REFERENCES notifications(id), -- Foreign key to notifications
    FOREIGN KEY (recipient_id) REFERENCES recipients(id)         -- Foreign key to recipients
);

-- Table to track delivery status per channel
CREATE TABLE delivery_channels (
    id CHAR(36) PRIMARY KEY,                        -- Unique ID
    notification_recipient_id CHAR(36),             -- References notification_recipient
    channel ENUM('in_app','email','push','sms','webhook'), -- Delivery channel type
    status ENUM('pending','sent','delivered','failed') DEFAULT 'pending', -- Status per channel
    details JSON,                                   -- Additional delivery info (e.g., response, webhook payload)
    sent_at TIMESTAMP NULL,                          -- Timestamp when sent
    FOREIGN KEY (notification_recipient_id) REFERENCES notification_recipients(id) -- Foreign key
);

-- Table to store recipient channel preferences
CREATE TABLE channel_preferences (
    id CHAR(36) PRIMARY KEY,                        -- Unique ID
    recipient_id CHAR(36),                          -- Recipient reference
    channel ENUM('in_app','email','push','sms'),   -- Channel type
    enabled BOOLEAN DEFAULT TRUE,                   -- Whether this channel is enabled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,-- Creation timestamp
    FOREIGN KEY (recipient_id) REFERENCES recipients(id) -- Foreign key to recipients
);

-- Table to log events related to notifications
CREATE TABLE event_logs (
    id CHAR(36) PRIMARY KEY,                        -- Unique log ID
    event_type VARCHAR(100),                         -- Event type
    payload JSON,                                   -- Full event payload
    source_service VARCHAR(100),                    -- Which service triggered this event
    status ENUM('received','processed','failed') DEFAULT 'received', -- Processing status
    processed_at TIMESTAMP NULL,                     -- Timestamp when processed
    error TEXT                                      -- Error message if failed
);


=====================================================================
-- Example for notification_templates
INSERT INTO notification_templates (id, event_type, title_template, body_template, channels, active)
VALUES (
    '11111111-1111-1111-1111-111111111111',
    'invoice_generated',
    'Invoice #{{invoiceId}} Generated',
    'Your invoice #{{invoiceId}} for amount ${{amount}} is ready.',
    '["email","push"]',  -- JSON array of channels
    TRUE
);

-- Example for notifications
INSERT INTO notifications (id, event_type, title, body, sender_ref, data, priority, tenant_id)
VALUES (
    '22222222-2222-2222-2222-222222222222',
    'invoice_generated',
    'Invoice #1234 Generated',
    'Your invoice #1234 for amount $500 is ready.',
    'system',
    '{"invoiceId":1234,"amount":500}',  -- JSON data
    'high',
    'tenant-001'
);

-- Example for recipients
INSERT INTO recipients (id, external_ref, type, metadata)
VALUES 
('33333333-3333-3333-3333-333333333333', 'user_101', 'user', '{"email":"user101@example.com","phone":"+911234567890"}'),
('33333333-3333-3333-3333-333333333334', 'user_102', 'user', '{"email":"user102@example.com","phone":"+911234567891"}');

-- Example for notification_recipients
INSERT INTO notification_recipients (id, notification_id, recipient_id, status)
VALUES 
('44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'pending'),
('44444444-4444-4444-4444-444444444445', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333334', 'pending');

-- Example for delivery_channels
INSERT INTO delivery_channels (id, notification_recipient_id, channel, status, details)
VALUES
('55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', 'email', 'pending', '{"email":"user101@example.com"}'),
('55555555-5555-5555-5555-555555555556', '44444444-4444-4444-4444-444444444445', 'push', 'pending', '{"deviceToken":"abc123"}');

-- Example for channel_preferences
INSERT INTO channel_preferences (id, recipient_id, channel, enabled)
VALUES
('66666666-6666-6666-6666-666666666666', '33333333-3333-3333-3333-333333333333', 'email', TRUE),
('66666666-6666-6666-6666-666666666667', '33333333-3333-3333-3333-333333333334', 'push', TRUE);

-- Example for event_logs
INSERT INTO event_logs (id, event_type, payload, source_service, status)
VALUES
('77777777-7777-7777-7777-777777777777', 'invoice_generated', '{"invoiceId":1234,"recipient":"user_101"}', 'notification_service', 'received');


=======================================================================

Get all notifications for a recipient:

SELECT n.id, n.title, n.body, nr.status
FROM notifications n
JOIN notification_recipients nr ON n.id = nr.notification_id
WHERE nr.recipient_id = '33333333-3333-3333-3333-333333333333';

Get delivery status for a notification:

SELECT dc.channel, dc.status, dc.details
FROM delivery_channels dc
JOIN notification_recipients nr ON dc.notification_recipient_id = nr.id
WHERE nr.notification_id = '22222222-2222-2222-2222-222222222222';

Check recipient channel preferences:

SELECT channel, enabled
FROM channel_preferences
WHERE recipient_id = '33333333-3333-3333-3333-333333333333';

Get events for logging/debugging:

SELECT event_type, payload, status, processed_at
FROM event_logs
ORDER BY processed_at DESC;

Check undelivered per recipient
-- Get all notifications that are still pending or failed for a recipient
SELECT n.id AS notification_id,
       n.title,
       n.body,
       nr.status AS recipient_status
FROM notifications n
JOIN notification_recipients nr ON n.id = nr.notification_id
WHERE nr.status IN ('pending','failed');

Check undelivered per channel
-- Get undelivered notification channels
SELECT n.id AS notification_id,
       r.external_ref AS recipient,
       dc.channel,
       dc.status AS delivery_status,
       dc.details
FROM delivery_channels dc
JOIN notification_recipients nr ON dc.notification_recipient_id = nr.id
JOIN notifications n ON nr.notification_id = n.id
JOIN recipients r ON nr.recipient_id = r.id
WHERE dc.status IN ('pending','failed');

============================================================================================

async function sendAdminNotification(userId, eventType) {
    // Check if notification for this event already exists and pending
    const { rows } = await pool.query(
        `SELECT id, data FROM notifications
         WHERE event_type=$1 AND id IN (
            SELECT notification_id FROM notification_recipients
            WHERE recipient_id=$2 AND status='pending'
         )`,
        [eventType, 'admin-001'] // admin ID
    );

    if (rows.length > 0) {
        // Already exists → update JSON data with new user
        const notification = rows[0];
        const data = JSON.parse(notification.data || '[]');
        if (!data.find(u => u.userId === userId)) {
            data.push({ userId });
            await pool.query(
                `UPDATE notifications SET data=$1 WHERE id=$2`,
                [JSON.stringify(data), notification.id]
            );
        }
    } else {
        // Create new notification
        const notifId = uuidv4();
        await pool.query(
            `INSERT INTO notifications (id, event_type, title, body, data, priority)
             VALUES ($1, $2, $3, $4, $5, 'high')`,
            [notifId, eventType, 'User Requests Pending', 'Some users requested action', JSON.stringify([{ userId }])]
        );

        await pool.query(
            `INSERT INTO notification_recipients (id, notification_id, recipient_id, status)
             VALUES ($1, $2, $3, 'pending')`,
            [uuidv4(), notifId, 'admin-001']
        );

        // Optionally, push to admin via WebSocket
        const ws = connectedUsers.get('admin-001');
        if (ws && ws.readyState === WebSocket.OPEN) {
            ws.send(JSON.stringify({ type: 'NOTIFICATION', data: { id: notifId, title: 'User Requests Pending' } }));
        }
    }
}
