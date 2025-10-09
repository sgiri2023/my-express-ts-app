CREATE DATABASE IF NOT EXISTS UserRoleDB;
USE UserRoleDB;

-- Insert Sample Users
-- INSERT INTO Users (username, email, password_hash) VALUES
-- ('sumit', 'sumit@example.com', 'hashed_pw1'),
-- ('john', 'john@example.com', 'hashed_pw2'),
-- ('alice', 'alice@example.com', 'hashed_pw3'),
-- ('maria', 'maria@example.com', 'hashed_pw4');

-- Insert Sample Groups
-- INSERT INTO UserGroups (group_name, description) VALUES
-- ('Finance', 'Finance department related operations'),
-- ('HR', 'Human resources and employee management'),
-- ('IT', 'IT infrastructure and support'),
-- ('Sales', 'Sales and marketing operations');

-- Assign Roles to Users
-- Sumit is GlobalAdmin
INSERT INTO UserRoles (user_id, role_id) 
SELECT u.user_id, r.role_id FROM Users u, Roles r
WHERE u.username = 'sumit' AND r.role_name = 'GlobalAdmin';

-- John is Admin
INSERT INTO UserRoles (user_id, role_id) 
SELECT u.user_id, r.role_id FROM Users u, Roles r
WHERE u.username = 'john' AND r.role_name = 'Admin';

-- Alice is Editor
INSERT INTO UserRoles (user_id, role_id) 
SELECT u.user_id, r.role_id FROM Users u, Roles r
WHERE u.username = 'alice' AND r.role_name = 'Edit';

-- Maria is Viewer
INSERT INTO UserRoles (user_id, role_id) 
SELECT u.user_id, r.role_id FROM Users u, Roles r
WHERE u.username = 'maria' AND r.role_name = 'Viewer';