USE UserRoleDB;

-- ======================
-- Insert Sample Users
-- ======================
INSERT INTO Users (username, email, password_hash, is_global_admin) VALUES
('sumit', 'sumit@example.com', 'hashed_pw1', TRUE),   -- ✅ GlobalAdmin
('john', 'john@example.com', 'hashed_pw2', FALSE),    -- Normal user
('alice', 'alice@example.com', 'hashed_pw3', FALSE),  -- Normal user
('maria', 'maria@example.com', 'hashed_pw4', FALSE);  -- Normal user

-- ======================
-- Insert Sample Groups
-- ======================
INSERT INTO UserGroups (group_name, description) VALUES
('Finance', 'Finance department operations'),
('HR', 'Human resources management'),
('IT', 'IT infrastructure and support');

-- ======================
-- Assign Group Roles (only for non-global admins)
-- ======================

-- John → Admin in Finance + HR
INSERT INTO UserGroupAccess (user_id, group_id, role_id)
SELECT u.user_id, g.group_id, r.role_id
FROM Users u, UserGroups g, Roles r
WHERE u.username = 'john' AND g.group_name = 'Finance' AND r.role_name = 'Admin';

INSERT INTO UserGroupAccess (user_id, group_id, role_id)
SELECT u.user_id, g.group_id, r.role_id
FROM Users u, UserGroups g, Roles r
WHERE u.username = 'john' AND g.group_name = 'HR' AND r.role_name = 'VIEWER';

-- Alice → Edit in IT
INSERT INTO UserGroupAccess (user_id, group_id, role_id)
SELECT u.user_id, g.group_id, r.role_id
FROM Users u, UserGroups g, Roles r
WHERE u.username = 'alice' AND g.group_name = 'IT' AND r.role_name = 'Edit';

-- Maria → Viewer in HR
INSERT INTO UserGroupAccess (user_id, group_id, role_id)
SELECT u.user_id, g.group_id, r.role_id
FROM Users u, UserGroups g, Roles r
WHERE u.username = 'maria' AND g.group_name = 'HR' AND r.role_name = 'Viewer';

-- ======================
-- Insert Sample Audit Logs
-- ======================

-- UserAuditLog (user-level actions)
INSERT INTO UserAuditLog (actor_user_id, target_user_id, action_type, old_value, new_value)
VALUES
((SELECT user_id FROM Users WHERE username='sumit'),
 (SELECT user_id FROM Users WHERE username='sumit'),
 'PROMOTE_GLOBALADMIN', 'NormalUser', 'GlobalAdmin'),
((SELECT user_id FROM Users WHERE username='sumit'),
 (SELECT user_id FROM Users WHERE username='john'),
 'CREATE_USER', NULL, 'User john created');

-- GroupAuditLog (group-level actions)
INSERT INTO GroupAuditLog (actor_user_id, group_id, action_type, old_value, new_value)
VALUES
((SELECT user_id FROM Users WHERE username='sumit'),
 (SELECT group_id FROM UserGroups WHERE group_name='Finance'),
 'CREATE_GROUP', NULL, 'Finance created'),
((SELECT user_id FROM Users WHERE username='sumit'),
 (SELECT group_id FROM UserGroups WHERE group_name='HR'),
 'CREATE_GROUP', NULL, 'HR created');

-- UserGroupAccessAuditLog (group-role assignments)
INSERT INTO UserGroupAccessAuditLog (actor_user_id, target_user_id, group_id, action_type, old_role, new_role)
VALUES
((SELECT user_id FROM Users WHERE username='sumit'),
 (SELECT user_id FROM Users WHERE username='john'),
 (SELECT group_id FROM UserGroups WHERE group_name='Finance'),
 'ASSIGN_ROLE', NULL, 'Admin'),
((SELECT user_id FROM Users WHERE username='sumit'),
 (SELECT user_id FROM Users WHERE username='alice'),
 (SELECT group_id FROM UserGroups WHERE group_name='IT'),
 'ASSIGN_ROLE', NULL, 'Edit'),
((SELECT user_id FROM Users WHERE username='sumit'),
 (SELECT user_id FROM Users WHERE username='maria'),
 (SELECT group_id FROM UserGroups WHERE group_name='HR'),
 'ASSIGN_ROLE', NULL, 'Viewer');
