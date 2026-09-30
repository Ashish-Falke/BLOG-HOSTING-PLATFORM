-- ============================================
-- BLOG HOSTING PLATFORM - DATABASE
-- MySQL 8.0+
-- ============================================

CREATE DATABASE IF NOT EXISTS blog_hosting_platform;

USE blog_hosting_platform;

-- ============================================
-- 1. USERS TABLE
-- ============================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

SELECT * FROM users;

-- ============================================
-- 2. CATEGORIES TABLE
-- ============================================

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255)
) ENGINE=InnoDB;


SELECT * FROM categories;

-- ============================================
-- 3. BLOGS TABLE
-- ============================================

CREATE TABLE blogs (
    blog_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,
    category_id INT NOT NULL,

    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    image_url VARCHAR(500),

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_blog_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_blog_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

SELECT * FROM blogs;

-- ============================================
-- 4. COMMENTS TABLE
-- ============================================

CREATE TABLE comments (
    comment_id INT AUTO_INCREMENT PRIMARY KEY,

    blog_id INT NOT NULL,
    user_id INT NOT NULL,

    content TEXT NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comment_blog
        FOREIGN KEY (blog_id)
        REFERENCES blogs(blog_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_comment_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

SELECT * FROM comments;

-- ============================================
-- 5. INDEXES
-- ============================================

CREATE INDEX idx_blogs_user
ON blogs(user_id);

CREATE INDEX idx_blogs_category
ON blogs(category_id);

CREATE INDEX idx_blogs_created_at
ON blogs(created_at);

CREATE INDEX idx_comments_blog
ON comments(blog_id);

CREATE INDEX idx_comments_user
ON comments(user_id);

CREATE INDEX idx_blog_category_created
ON blogs(category_id, created_at);

CREATE INDEX idx_comment_blog_created
ON comments(blog_id, created_at);


-- ============================================
-- 6. CHECK CONSTRAINTS
-- ============================================

ALTER TABLE users
ADD CONSTRAINT chk_username_length
CHECK (CHAR_LENGTH(username) >= 3);

ALTER TABLE categories
ADD CONSTRAINT chk_category_name
CHECK (CHAR_LENGTH(name) >= 2);


-- ============================================
-- 7. VERIFY TABLES
-- ============================================

SHOW TABLES;

DESCRIBE users;
DESCRIBE categories;
DESCRIBE blogs;
DESCRIBE comments;