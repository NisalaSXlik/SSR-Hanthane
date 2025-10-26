-- Drop existing tables
DROP TABLE IF EXISTS users, groups, posts CASCADE;

-- Users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'student',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Groups table  
CREATE TABLE groups (
    group_id SERIAL PRIMARY KEY,
    group_name VARCHAR(200) NOT NULL,
    description TEXT,
    created_by INTEGER REFERENCES users(user_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Posts table
CREATE TABLE posts (
    post_id SERIAL PRIMARY KEY,
    group_id INTEGER REFERENCES groups(group_id),
    user_id INTEGER REFERENCES users(user_id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO users (email, password_hash, first_name, last_name, role) VALUES
('admin@hanthana.lk', 'hashed_password', 'System', 'Admin', 'admin'),
('student1@ucsc.lk', 'hashed_password', 'John', 'Doe', 'student');

INSERT INTO groups (group_name, description, created_by) VALUES
('Computer Science 2024', 'CS students batch 2024', 1),
('Research Club', 'Academic research discussions', 1);

INSERT INTO posts (group_id, user_id, content) VALUES
(1, 1, 'Welcome to CS 2024 group!'),
(1, 2, 'Hello everyone!');