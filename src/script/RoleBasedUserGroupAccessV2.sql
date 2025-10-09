-- Create Database
CREATE DATABASE IF NOT EXISTS UserRoleDB;
USE UserRoleDB;

-- ======================
-- Users Table
-- ======================
CREATE TABLE Users (
    user_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100) NOT NULL UNIQUE,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_global_admin BOOLEAN DEFAULT FALSE, -- ✅ Global admin flag
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ======================
-- Roles Table (only group roles)
-- ======================
CREATE TABLE Roles (
    role_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL UNIQUE, -- Admin, Edit, Viewer
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ======================
-- Groups Table
-- ======================
CREATE TABLE UserGroups (
    group_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    group_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ======================
-- User ↔ Group Mapping (only for non-global admins)
-- ======================
CREATE TABLE UserGroupAccess (
    user_group_access_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    group_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL, -- Admin/Edit/Viewer
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (group_id) REFERENCES UserGroups(group_id),
    FOREIGN KEY (role_id) REFERENCES Roles(role_id)
);

-- ======================
-- Audit Logs (separated)
-- ======================

-- 1. User Audit Log
CREATE TABLE UserAuditLog (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    actor_user_id BIGINT,
    target_user_id BIGINT,
    action_type VARCHAR(50) NOT NULL, -- e.g., CREATE_USER, PROMOTE_GLOBALADMIN, DEACTIVATE_USER
    old_value TEXT,
    new_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (actor_user_id) REFERENCES Users(user_id),
    FOREIGN KEY (target_user_id) REFERENCES Users(user_id)
);

-- 2. Group Audit Log
CREATE TABLE GroupAuditLog (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    actor_user_id BIGINT,
    group_id BIGINT,
    action_type VARCHAR(50) NOT NULL, -- e.g., CREATE_GROUP, UPDATE_GROUP, DEACTIVATE_GROUP
    old_value TEXT,
    new_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (actor_user_id) REFERENCES Users(user_id),
    FOREIGN KEY (group_id) REFERENCES UserGroups(group_id)
);

-- 3. User ↔ Group Access Audit Log
CREATE TABLE UserGroupAccessAuditLog (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    actor_user_id BIGINT,
    target_user_id BIGINT,
    group_id BIGINT,
    action_type VARCHAR(50) NOT NULL, -- e.g., ASSIGN_ROLE, REMOVE_ROLE, CHANGE_ROLE
    old_role VARCHAR(50),
    new_role VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (actor_user_id) REFERENCES Users(user_id),
    FOREIGN KEY (target_user_id) REFERENCES Users(user_id),
    FOREIGN KEY (group_id) REFERENCES UserGroups(group_id)
);

-- ======================
-- Default Roles
-- ======================
INSERT INTO Roles (role_name, description) VALUES
('Admin', 'Can manage assigned group'),
('Edit', 'Can edit assigned group'),
('Viewer', 'Can only view assigned group');
