USE blog_hosting_platform;

-- ============================================================
-- ADVANCED SQL IMPLEMENTATION
-- BLOG HOSTING PLATFORM
-- MySQL 8.0+
-- ============================================================


-- ============================================================
-- 1. COMPLEX INNER JOIN
-- ============================================================
-- Business requirement:
-- Display each blog with its author, category and comment count.

SELECT
    b.blog_id,
    b.title AS blog_title,
    u.username AS author,
    c.name AS category,
    COUNT(cm.comment_id) AS total_comments,
    b.created_at
FROM blogs b
INNER JOIN users u
    ON b.user_id = u.user_id
INNER JOIN categories c
    ON b.category_id = c.category_id
LEFT JOIN comments cm
    ON b.blog_id = cm.blog_id
GROUP BY
    b.blog_id,
    b.title,
    u.username,
    c.name,
    b.created_at
ORDER BY total_comments DESC;


-- ============================================================
-- 2. COMPLEX OUTER JOIN
-- ============================================================
-- Business requirement:
-- Find all categories, including categories having no blogs.

SELECT
    c.category_id,
    c.name AS category_name,
    COUNT(b.blog_id) AS total_blogs
FROM categories c
LEFT OUTER JOIN blogs b
    ON c.category_id = b.category_id
GROUP BY
    c.category_id,
    c.name
ORDER BY total_blogs DESC;


-- ============================================================
-- 3. COMPLEX MULTI-TABLE OUTER JOIN
-- ============================================================
-- Business requirement:
-- Display every user, their blogs and comments.
-- Users without blogs/comments must also appear.

SELECT
    u.user_id,
    u.username,
    b.blog_id,
    b.title AS blog_title,
    c.name AS category,
    cm.comment_id,
    cm.content AS comment_content
FROM users u
LEFT JOIN blogs b
    ON u.user_id = b.user_id
LEFT JOIN categories c
    ON b.category_id = c.category_id
LEFT JOIN comments cm
    ON b.blog_id = cm.blog_id
ORDER BY u.user_id, b.blog_id;


-- ============================================================
-- 4. SELF JOIN
-- ============================================================
-- Business requirement:
-- Find pairs of users having the same email domain.
--
-- Example:
-- user001@example.com
-- user002@example.com
--
-- Both users have the same domain: example.com

SELECT
    u1.user_id AS user_1_id,
    u1.username AS user_1,
    u2.user_id AS user_2_id,
    u2.username AS user_2,
    SUBSTRING_INDEX(u1.email, '@', -1) AS email_domain
FROM users u1
INNER JOIN users u2
    ON SUBSTRING_INDEX(u1.email, '@', -1)
       =
       SUBSTRING_INDEX(u2.email, '@', -1)
    AND u1.user_id < u2.user_id
ORDER BY email_domain, u1.user_id;


-- ============================================================
-- 5. CORRELATED SUBQUERY
-- ============================================================
-- Business requirement:
-- Find users whose number of blogs is greater than
-- the average number of blogs created by users.

SELECT
    u.user_id,
    u.username,
    COUNT(b.blog_id) AS total_blogs
FROM users u
LEFT JOIN blogs b
    ON u.user_id = b.user_id
GROUP BY
    u.user_id,
    u.username
HAVING COUNT(b.blog_id) >
(
    SELECT AVG(user_blog_count)
    FROM
    (
        SELECT
            user_id,
            COUNT(*) AS user_blog_count
        FROM blogs
        GROUP BY user_id
    ) AS blog_statistics
)
ORDER BY total_blogs DESC;


-- ============================================================
-- 6. CORRELATED SUBQUERY WITH EXISTS
-- ============================================================
-- Business requirement:
-- Find users who have created at least one blog.

SELECT
    u.user_id,
    u.username,
    u.email
FROM users u
WHERE EXISTS
(
    SELECT 1
    FROM blogs b
    WHERE b.user_id = u.user_id
);


-- ============================================================
-- 7. AGGREGATE + GROUP BY + HAVING
-- ============================================================
-- Business requirement:
-- Find categories containing more than one blog.

SELECT
    c.category_id,
    c.name AS category_name,
    COUNT(b.blog_id) AS total_blogs
FROM categories c
INNER JOIN blogs b
    ON c.category_id = b.category_id
GROUP BY
    c.category_id,
    c.name
HAVING COUNT(b.blog_id) > 1
ORDER BY total_blogs DESC;


-- ============================================================
-- 8. AGGREGATE BUSINESS REPORT
-- ============================================================
-- Business requirement:
-- Display user activity.

SELECT
    u.user_id,
    u.username,
    COUNT(DISTINCT b.blog_id) AS blogs_created,
    COUNT(DISTINCT cm.comment_id) AS comments_created
FROM users u
LEFT JOIN blogs b
    ON u.user_id = b.user_id
LEFT JOIN comments cm
    ON u.user_id = cm.user_id
GROUP BY
    u.user_id,
    u.username
HAVING
    COUNT(DISTINCT b.blog_id) > 0
    OR
    COUNT(DISTINCT cm.comment_id) > 0
ORDER BY blogs_created DESC, comments_created DESC;


-- ============================================================
-- 9. STORED PROCEDURE
-- ============================================================
-- Operational transaction:
-- Create a new blog inside a transaction.
--
-- Parameters:
-- p_user_id
-- p_category_id
-- p_title
-- p_content
-- p_image_url
--
-- The procedure validates the user/category and inserts
-- the blog only when both are valid.

DROP PROCEDURE IF EXISTS sp_create_blog;

DELIMITER $$

CREATE PROCEDURE sp_create_blog(
    IN p_user_id INT,
    IN p_category_id INT,
    IN p_title VARCHAR(200),
    IN p_content TEXT,
    IN p_image_url VARCHAR(500)
)
BEGIN

    DECLARE v_user_count INT DEFAULT 0;
    DECLARE v_category_count INT DEFAULT 0;

    -- Start transaction
    START TRANSACTION;

    -- Validate user
    SELECT COUNT(*)
    INTO v_user_count
    FROM users
    WHERE user_id = p_user_id;

    -- Validate category
    SELECT COUNT(*)
    INTO v_category_count
    FROM categories
    WHERE category_id = p_category_id;

    -- Validate user
    IF v_user_count = 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid user ID';

    -- Validate category
    ELSEIF v_category_count = 0 THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid category ID';

    -- Validate title
    ELSEIF p_title IS NULL OR TRIM(p_title) = '' THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Blog title cannot be empty';

    -- Validate content
    ELSEIF p_content IS NULL OR TRIM(p_content) = '' THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Blog content cannot be empty';

    ELSE

        INSERT INTO blogs
        (
            user_id,
            category_id,
            title,
            content,
            image_url
        )
        VALUES
        (
            p_user_id,
            p_category_id,
            p_title,
            p_content,
            p_image_url
        );

        COMMIT;

        SELECT
            LAST_INSERT_ID() AS new_blog_id,
            'Blog created successfully' AS message;

    END IF;

END$$

DELIMITER ;


-- ============================================================
-- TEST STORED PROCEDURE
-- ============================================================

CALL sp_create_blog(
    1,
    1,
    'Advanced MySQL Performance Tuning',
    'This blog explains indexing, EXPLAIN and query optimization.',
    'https://example.com/mysql.jpg'
);


-- ============================================================
-- 10. TRIGGER
-- ============================================================
-- Business rule:
-- Every blog update must be automatically recorded.
--
-- This demonstrates dynamic auditing.

CREATE TABLE IF NOT EXISTS blog_update_audit
(
    audit_id INT AUTO_INCREMENT PRIMARY KEY,

    blog_id INT NOT NULL,

    old_title VARCHAR(200),
    new_title VARCHAR(200),

    old_content TEXT,
    new_content TEXT,

    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (blog_id)
        REFERENCES blogs(blog_id)
        ON DELETE CASCADE
);


DROP TRIGGER IF EXISTS trg_blog_update_audit;

DELIMITER $$

CREATE TRIGGER trg_blog_update_audit
AFTER UPDATE ON blogs
FOR EACH ROW
BEGIN

    INSERT INTO blog_update_audit
    (
        blog_id,
        old_title,
        new_title,
        old_content,
        new_content
    )
    VALUES
    (
        OLD.blog_id,
        OLD.title,
        NEW.title,
        OLD.content,
        NEW.content
    );

END$$

DELIMITER ;


-- ============================================================
-- TEST TRIGGER
-- ============================================================

UPDATE blogs
SET title = 'Updated Advanced MySQL Performance Guide'
WHERE blog_id = 1;


-- Verify audit
SELECT *
FROM blog_update_audit
ORDER BY audit_id DESC;


-- ============================================================
-- 11. VIRTUAL VIEW 1
-- ============================================================
-- Business reporting:
-- Complete blog details.

DROP VIEW IF EXISTS vw_blog_business_report;

CREATE VIEW vw_blog_business_report AS
SELECT
    b.blog_id,
    b.title AS blog_title,
    u.username AS author,
    c.name AS category,
    COUNT(cm.comment_id) AS total_comments,
    b.created_at,
    b.updated_at
FROM blogs b
INNER JOIN users u
    ON b.user_id = u.user_id
INNER JOIN categories c
    ON b.category_id = c.category_id
LEFT JOIN comments cm
    ON b.blog_id = cm.blog_id
GROUP BY
    b.blog_id,
    b.title,
    u.username,
    c.name,
    b.created_at,
    b.updated_at;


-- Test View
SELECT *
FROM vw_blog_business_report
ORDER BY total_comments DESC;


-- ============================================================
-- 12. VIRTUAL VIEW 2
-- ============================================================
-- Business reporting:
-- User activity summary.

DROP VIEW IF EXISTS vw_user_business_report;

CREATE VIEW vw_user_business_report AS
SELECT
    u.user_id,
    u.username,
    u.email,
    COUNT(DISTINCT b.blog_id) AS total_blogs,
    COUNT(DISTINCT cm.comment_id) AS total_comments
FROM users u
LEFT JOIN blogs b
    ON u.user_id = b.user_id
LEFT JOIN comments cm
    ON u.user_id = cm.user_id
GROUP BY
    u.user_id,
    u.username,
    u.email;


-- Test View
SELECT *
FROM vw_user_business_report
ORDER BY total_blogs DESC;


-- ============================================================
-- 13. PERFORMANCE TEST - BEFORE INDEXING
-- ============================================================
-- Run EXPLAIN before creating the additional composite index.

EXPLAIN
SELECT
    b.blog_id,
    b.title,
    b.created_at,
    u.username AS author,
    c.name AS category
FROM blogs b
INNER JOIN users u
    ON b.user_id = u.user_id
INNER JOIN categories c
    ON b.category_id = c.category_id
WHERE b.category_id = 1
ORDER BY b.created_at DESC;


-- ============================================================
-- 14. PERFORMANCE TEST - SECOND COMPLEX QUERY
-- ============================================================

EXPLAIN
SELECT
    b.blog_id,
    b.title,
    COUNT(cm.comment_id) AS total_comments
FROM blogs b
LEFT JOIN comments cm
    ON b.blog_id = cm.blog_id
WHERE b.category_id = 1
GROUP BY
    b.blog_id,
    b.title
ORDER BY total_comments DESC;


-- ============================================================
-- 15. CREATE PERFORMANCE INDEXES
-- ============================================================

-- Composite index for category filtering + date sorting

CREATE INDEX idx_blogs_category_created
ON blogs(category_id, created_at);


-- Composite index for blog comments

CREATE INDEX idx_comments_blog_created
ON comments(blog_id, created_at);


-- Single-column index on blog user

CREATE INDEX idx_blogs_user_id
ON blogs(user_id);


-- ============================================================
-- 16. PERFORMANCE TEST - AFTER INDEXING
-- ============================================================

EXPLAIN
SELECT
    b.blog_id,
    b.title,
    b.created_at,
    u.username AS author,
    c.name AS category
FROM blogs b
INNER JOIN users u
    ON b.user_id = u.user_id
INNER JOIN categories c
    ON b.category_id = c.category_id
WHERE b.category_id = 1
ORDER BY b.created_at DESC;


EXPLAIN
SELECT
    b.blog_id,
    b.title,
    COUNT(cm.comment_id) AS total_comments
FROM blogs b
LEFT JOIN comments cm
    ON b.blog_id = cm.blog_id
WHERE b.category_id = 1
GROUP BY
    b.blog_id,
    b.title
ORDER BY total_comments DESC;


-- ============================================================
-- 17. EXPLAIN ANALYZE
-- ============================================================
-- MySQL 8.0.18+
--
-- This executes the query and reports actual execution
-- statistics.

EXPLAIN ANALYZE
SELECT
    b.blog_id,
    b.title,
    b.created_at,
    u.username AS author,
    c.name AS category
FROM blogs b
INNER JOIN users u
    ON b.user_id = u.user_id
INNER JOIN categories c
    ON b.category_id = c.category_id
WHERE b.category_id = 1
ORDER BY b.created_at DESC;


EXPLAIN ANALYZE
SELECT
    b.blog_id,
    b.title,
    COUNT(cm.comment_id) AS total_comments
FROM blogs b
LEFT JOIN comments cm
    ON b.blog_id = cm.blog_id
WHERE b.category_id = 1
GROUP BY
    b.blog_id,
    b.title
ORDER BY total_comments DESC;


-- ============================================================
-- 18. INDEX INFORMATION
-- ============================================================

SHOW INDEX FROM blogs;

SHOW INDEX FROM comments;


-- ============================================================
-- END OF ADVANCED SQL IMPLEMENTATION
-- ============================================================