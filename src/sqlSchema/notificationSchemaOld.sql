-- =============================
-- 1️⃣ USERS
-- =============================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    role            VARCHAR(20) CHECK (role IN ('admin', 'user')) NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- =============================
-- 2️⃣ GROUPS
-- =============================
CREATE TABLE groups (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) UNIQUE NOT NULL,
    description     TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- =============================
-- 3️⃣ USER-GROUP MAPPING
-- =============================
CREATE TABLE user_groups (
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    group_id        UUID REFERENCES groups(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, group_id)
);

-- =============================
-- 4️⃣ NOTIFICATIONS
-- =============================
CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           VARCHAR(200) NOT NULL,
    body            TEXT NOT NULL,
    type            VARCHAR(30) CHECK (type IN ('info', 'warning', 'alert', 'system')) DEFAULT 'info',
    priority        VARCHAR(20) CHECK (priority IN ('low', 'medium', 'high')) DEFAULT 'medium',
    sender_id       UUID REFERENCES users(id) ON DELETE SET NULL,
    target_scope    VARCHAR(20) CHECK (target_scope IN ('user','group','admin','all')) NOT NULL,
    metadata        JSONB DEFAULT '{}',
    expires_at      TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW(),
    deleted_at      TIMESTAMP
);

-- =============================
-- 5️⃣ NOTIFICATION TARGETS
-- (specific users or groups)
-- =============================
CREATE TABLE notification_targets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID REFERENCES notifications(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    group_id        UUID REFERENCES groups(id) ON DELETE CASCADE,
    CONSTRAINT chk_target_user_or_group CHECK (
        (user_id IS NOT NULL) OR (group_id IS NOT NULL)
    )
);

-- =============================
-- 6️⃣ NOTIFICATION CHANNELS
-- (tracks email/push/in-app delivery)
-- =============================
CREATE TABLE notification_channels (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID REFERENCES notifications(id) ON DELETE CASCADE,
    channel         VARCHAR(20) CHECK (channel IN ('in_app','email','sms','push')) NOT NULL,
    status          VARCHAR(20) CHECK (status IN ('pending','sent','failed','delivered')) DEFAULT 'pending',
    sent_at         TIMESTAMP,
    details         JSONB DEFAULT '{}'
);

-- =============================
-- 7️⃣ USER NOTIFICATIONS
-- (read/unread tracking)
-- =============================
CREATE TABLE user_notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    notification_id UUID REFERENCES notifications(id) ON DELETE CASCADE,
    is_read         BOOLEAN DEFAULT FALSE,
    read_at         TIMESTAMP,
    delivered_at    TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, notification_id)
);

CREATE INDEX idx_user_notifications_user ON user_notifications(user_id);
CREATE INDEX idx_user_notifications_notification ON user_notifications(notification_id);

-- =============================
-- 8️⃣ USER NOTIFICATION SETTINGS
-- (optional user preferences)
-- =============================
CREATE TABLE user_notification_settings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
    channel         VARCHAR(20) CHECK (channel IN ('in_app','email','sms','push')),
    enabled         BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT NOW(),
    UNIQUE (user_id, channel)
);