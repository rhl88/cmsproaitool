# SQL模板示例集合

本文档提供各类数据库变更的完整可执行SQL模板，可直接复制使用或根据实际需求修改。

## 目录

1. [新建表示例](#1-新建表示例)
2. [添加字段示例](#2-添加字段示例)
3. [修改字段类型示例](#3-修改字段类型示例)
4. [添加索引示例](#4-添加索引示例)
5. [数据迁移示例](#5-数据迁移示例)
6. [批量更新示例](#6-批量更新示例)
7. [软删除实现](#7-软删除实现)
8. [视图创建示例](#8-视图创建示例)
9. [存储过程示例](#9-存储过程示例)

---

## 1. 新建表示例

### 用户表（基础版）

```sql
-- ============================================================================
-- V2026050401__create_users_table.sql
-- 创建用户基础信息表
-- ============================================================================

-- 幂等性：先检查表是否存在
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN

        CREATE TABLE users (
            id BIGSERIAL PRIMARY KEY,
            username VARCHAR(50) NOT NULL UNIQUE,
            email VARCHAR(100) NOT NULL UNIQUE,
            phone VARCHAR(20),
            password_hash VARCHAR(255) NOT NULL,
            nickname VARCHAR(50),
            avatar_url VARCHAR(500),
            status SMALLINT NOT NULL DEFAULT 1,
            last_login_time TIMESTAMP,
            create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        );

        -- 索引
        CREATE INDEX idx_users_status ON users(status);
        CREATE INDEX idx_users_create_time ON users(create_time);
        CREATE INDEX idx_users_phone ON users(phone) WHERE phone IS NOT NULL;

        -- 注释
        COMMENT ON TABLE users IS '用户表';
        COMMENT ON COLUMN users.id IS '主键ID';
        COMMENT ON COLUMN users.username IS '用户名（唯一）';
        COMMENT ON COLUMN users.email IS '邮箱地址（唯一）';
        COMMENT ON COLUMN users.phone IS '手机号';
        COMMENT ON COLUMN users.password_hash IS '密码哈希值';
        COMMENT ON COLUMN users.nickname IS '昵称';
        COMMENT ON COLUMN users.avatar_url IS '头像URL';
        COMMENT ON COLUMN users.status IS '状态：1-正常 0-禁用 2-锁定';
        COMMENT ON COLUMN users.last_login_time IS '最后登录时间';

        RAISE NOTICE '✅ 表 users 创建成功';

    ELSE
        RAISE NOTICE '⚠️ 表 users 已存在，跳过创建';
    END IF;
END $$;

-- 验证
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- 回滚方案:
-- DROP TABLE IF EXISTS users CASCADE;
```

### 订单表（含外键和计算字段）

```sql
-- ============================================================================
-- V2026050402__create_orders_table.sql
-- 创建订单表（包含外键约束和生成列）
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'orders') THEN

        CREATE TABLE orders (
            id BIGSERIAL PRIMARY KEY,
            order_no VARCHAR(32) NOT NULL UNIQUE,
            user_id BIGINT NOT NULL,
            total_amount DECIMAL(12,2) NOT NULL,
            discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
            shipping_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
            tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
            pay_amount DECIMAL(12,2) GENERATED ALWAYS AS (
                total_amount - discount_amount + shipping_fee + tax_amount
            ) STORED,
            status SMALLINT NOT NULL DEFAULT 1,
            payment_method SMALLINT,
            payment_time TIMESTAMP,
            delivery_address TEXT,
            remark TEXT,
            create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

            CONSTRAINT fk_orders_user FOREIGN KEY (user_id)
                REFERENCES users(id) ON DELETE RESTRICT
        );

        -- 索引
        CREATE INDEX idx_orders_user_id ON orders(user_id);
        CREATE INDEX idx_orders_order_no ON orders(order_no);
        CREATE INDEX idx_orders_status ON orders(status);
        CREATE INDEX idx_orders_create_time ON orders(create_time);
        CREATE INDEX idx_orders_user_status ON orders(user_id, status);

        -- 部分索引：只索引待支付订单
        CREATE INDEX idx_orders_pending_payment ON orders(create_time)
            WHERE status = 1 AND payment_time IS NULL;

        -- 注释
        COMMENT ON TABLE orders IS '订单主表';
        COMMENT ON COLUMN orders.order_no IS '订单编号（业务唯一）';
        COMMENT ON COLUMN orders.pay_amount IS '实付金额（自动计算）';
        COMMENT ON COLUMN orders.status IS '状态：1-待支付 2-已支付 3-已发货 4-已完成 5-已取消';
        COMMENT ON COLUMN orders.payment_method IS '支付方式：1-支付宝 2-微信 3-银行卡';

        RAISE NOTICE '✅ 表 orders 创建成功';

    ELSE
        RAISE NOTICE '⚠️ 表 orders 已存在，跳过创建';
    END IF;
END $$;

-- 回滚方案:
-- DROP TABLE IF EXISTS orders CASCADE;
```

---

## 2. 添加字段示例

### 添加单个字段（低风险）

```sql
-- ============================================================================
-- V2026050403__add_user_email_verified.sql
-- 为用户表添加邮箱验证标志字段
-- ============================================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'email_verified'
    ) THEN
        ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
        COMMENT ON COLUMN users.email_verified IS '邮箱是否已验证';
        RAISE NOTICE '✅ 字段 email_verified 添加成功';
    ELSE
        RAISE NOTICE '⚠️ 字段 email_verified 已存在';
    END IF;
END $$;

-- 回滚: ALTER TABLE users DROP COLUMN IF EXISTS email_verified;
```

### 添加多个相关字段（中风险）

```sql
-- ============================================================================
-- V2026050404__add_user_address_fields.sql
-- 为用户表添加地址相关字段
-- ============================================================================

BEGIN;

-- 检查并添加省份字段
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'province'
    ) THEN
        ALTER TABLE users ADD COLUMN province VARCHAR(50) DEFAULT NULL;
        COMMENT ON COLUMN users.province IS '省份';
    END IF;
END $$;

-- 检查并添加城市字段
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'city'
    ) THEN
        ALTER TABLE users ADD COLUMN city VARCHAR(50) DEFAULT NULL;
        COMMENT ON COLUMN users.city IS '城市';
    END IF;
END $$;

-- 检查并添加详细地址字段
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'detail_address'
    ) THEN
        ALTER TABLE users ADD COLUMN detail_address VARCHAR(200) DEFAULT NULL;
        COMMENT ON COLUMN users.detail_address IS '详细地址';
    END IF;
END $$;

COMMIT;

-- 验证所有字段已添加
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name IN ('province', 'city', 'detail_address');

-- 回滚:
-- ALTER TABLE users DROP COLUMN IF EXISTS province;
-- ALTER TABLE users DROP COLUMN IF EXISTS city;
-- ALTER TABLE users DROP COLUMN IF EXISTS detail_address;
```

### 添加带默认值和数据迁移的字段

```sql
-- ============================================================================
-- V2026050405__add_user_fullname_and_migrate.sql
-- 添加全名字段并从现有数据迁移
-- ============================================================================

BEGIN;

-- 第一步：添加可为空的字段
ALTER TABLE users ADD COLUMN IF NOT EXISTS full_name VARCHAR(100) DEFAULT NULL;
COMMENT ON COLUMN users.full_name IS '姓名（用于显示）';

-- 第二步：从现有字段迁移数据（如果nickname有值则使用nickname）
UPDATE users
SET full_name = COALESCE(NULLIF(TRIM(nickname), ''), username)
WHERE full_name IS NULL;

-- 第三步：验证迁移结果
RAISE INFO '迁移完成，统计信息:';
RAISE INFO '  总用户数: %', (SELECT COUNT(*) FROM users);
RAISE INFO '  已填充full_name: %', (SELECT COUNT(*) FROM users WHERE full_name IS NOT NULL);
RAISE INFO '  未填充full_name: %', (SELECT COUNT(*) FROM users WHERE full_name IS NULL);

COMMIT;

-- 后续版本可考虑添加非空约束（在确认所有数据都已填充后）
-- ALTER TABLE users ALTER COLUMN full_name SET NOT NULL;

-- 回滚:
-- ALTER TABLE users DROP COLUMN IF EXISTS full_name;
```

---

## 3. 修改字段类型示例

### 扩大VARCHAR长度（安全）

```sql
-- ============================================================================
-- V2026050406__extend_username_length.sql
-- 将用户名最大长度从50扩展到100
-- ============================================================================

-- PostgreSQL允许扩大VARCHAR长度，这是安全操作
ALTER TABLE users ALTER COLUMN username TYPE VARCHAR(100);

COMMENT ON COLUMN users.username IS '用户名（唯一，最大100字符）';

-- 验证
SELECT character_maximum_length
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'username';

-- 回滚: ALTER TABLE users ALTER COLUMN username TYPE VARCHAR(50);
```

### 类型转换（需谨慎）

```sql
-- ============================================================================
-- V2026050407__convert_price_to_decimal.sql
-- 将价格字段从VARCHAR转换为DECIMAL
-- ============================================================================

-- ⚠️ 高风险操作！必须在测试环境充分验证！

BEGIN;

-- 先检查是否有非法数据
DO $$
DECLARE
    invalid_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO invalid_count
    FROM products
    WHERE price IS NOT NULL
      AND price ~ '[^0-9.]';

    IF invalid_count > 0 THEN
        RAISE EXCEPTION '发现 % 条非法价格数据，请先清洗数据！', invalid_count;
    ELSE
        RAISE NOTICE '✅ 数据验证通过，开始转换';
    END IF;
END $$;

-- 执行类型转换
ALTER TABLE products
    ALTER COLUMN price TYPE DECIMAL(10,2)
    USING CAST(price AS DECIMAL(10,2));

-- 验证转换结果
SELECT COUNT(*), MIN(price), MAX(price), AVG(price)
FROM products
WHERE price IS NOT NULL;

COMMIT;

-- 回滚: ALTER TABLE products ALTER COLUMN price TYPE VARCHAR(50);
```

---

## 4. 添加索引示例

### 普通索引

```sql
-- ============================================================================
-- V2026050408__create_search_index.sql
-- 为常用查询添加索引
-- ============================================================================

-- 单字段索引
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 复合索引（注意字段顺序很重要）
CREATE INDEX IF NOT EXISTS idx_orders_user_create
    ON orders(user_id, create_time DESC);

-- 函数索引（用于表达式查询）
CREATE INDEX IF NOT EXISTS idx_users_lower_email
    ON users(LOWER(email));

-- 验证索引已创建
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename IN ('users', 'orders')
  AND indexname LIKE 'idx_%'
ORDER BY indexname;

-- 回滚:
-- DROP INDEX IF EXISTS idx_users_email;
-- DROP INDEX IF EXISTS idx_orders_user_create;
-- DROP INDEX IF EXISTS idx_users_lower_email;
```

### 唯一索引

```sql
-- ============================================================================
-- V2026050409__create_unique_constraints.sql
-- 添加唯一性约束
-- ============================================================================

-- 确保手机号唯一（如果已填入）
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_unique_phone
    ON users(phone)
    WHERE phone IS NOT NULL;  -- 部分唯一索引，允许多个NULL

-- 联合唯一索引：确保同一订单下商品不重复
CREATE UNIQUE INDEX IF NOT EXISTS idx_order_items_unique
    ON order_items(order_id, product_id);

-- 验证
SELECT indexname, uniqueness, indexdef
FROM pg_indexes
WHERE tablename IN ('users', 'order_items')
  AND uniqueness = 'unique';
```

---

## 5. 数据迁移示例

### 表拆分（垂直拆分）

```sql
-- ============================================================================
-- V2026050410__split_user_profile.sql
-- 将用户详细信息拆分到独立表
-- ============================================================================

BEGIN;

-- 创建新表
CREATE TABLE IF NOT EXISTS user_profiles (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    gender SMALLINT,
    birthday DATE,
    bio TEXT,
    website VARCHAR(200),
    location VARCHAR(100),
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_profiles_user FOREIGN KEY (user_id)
        REFERENCES users(id) ON DELETE CASCADE
);

-- 迁移数据
INSERT INTO user_profiles (user_id, gender, birthday, bio, website, location, create_time)
SELECT
    id,
    gender,
    birthday,
    bio,
    website,
    location,
    create_time
FROM users
WHERE id NOT IN (SELECT user_id FROM user_profiles)
ON CONFLICT (user_id) DO NOTHING;

-- 迁移结果统计
RAISE NOTICE '✅ 迁移完成，共迁移 % 条记录',
    (SELECT COUNT(*) FROM user_profiles);

-- 验证数据完整性
SELECT
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM user_profiles) AS migrated_profiles,
    (SELECT COUNT(*) FROM users WHERE id NOT IN (SELECT user_id FROM user_profiles)) AS not_migrated;

COMMIT;

-- 验证完成后，原表的这些字段可在下一版本清理
-- ALTER TABLE users DROP COLUMN IF EXISTS gender;
-- （需要确保应用代码已切换到新表查询）

-- 回滚方案:
-- BEGIN;
-- INSERT INTO users (id, gender, birthday, bio, website, location)
-- SELECT user_id, gender, birthday, bio, website, location
-- FROM user_profiles
-- ON CONFLICT (id) DO UPDATE SET
--     gender = EXCLUDED.gender,
--     birthday = EXCLUDED.birthday,
--     bio = EXCLUDED.bio,
--     website = EXCLUDED.website,
--     location = EXCLUDED.location;
-- DROP TABLE IF EXISTS user_profiles;
-- COMMIT;
```

### 数据清洗与标准化

```sql
-- ============================================================================
-- V2026050411__standardize_phone_numbers.sql
-- 标准化手机号格式
-- ============================================================================

BEGIN;

-- 备份原始数据（使用临时表）
CREATE TEMPORARY TABLE temp_phones_backup AS
SELECT id, phone FROM users WHERE phone IS NOT NULL;

-- 标准化：去除空格、横线等
UPDATE users
SET phone = REGEXP_REPLACE(phone, '[\s\-]', '', 'g')
WHERE phone ~ '[\s\-]';

-- 标准化：统一加86前缀（如果没有国际区号）
UPDATE users
SET phone = '86' || phone
WHERE phone IS NOT NULL
  AND phone !~ '^86'
  AND LENGTH(phone) = 11
  AND phone ~ '^[0-9]{11}$';

-- 统计变更
RAISE NOTICE '标准化完成:';
RAISE NOTICE '  处理记录数: %', (SELECT COUNT(*) FROM temp_phones_backup);
RAISE NOTICE '  变更记录数: %',
    (SELECT COUNT(*) FROM users u JOIN temp_phones_backup b ON u.id = b.id WHERE u.phone != b.phone);

-- 清理临时备份
DROP TABLE temp_phones_backup;

COMMIT;

-- 回滚: 从应用日志或数据库binlog恢复原始数据
```

---

## 6. 批量更新示例

### 状态批量更新

```sql
-- ============================================================================
-- V2026050412__expire_old_orders.sql
-- 将超时未支付的订单标记为已取消
-- ============================================================================

BEGIN;

-- 先查看影响范围
RAISE NOTICE '将要取消的超时订单数量: %',
    (SELECT COUNT(*) FROM orders
     WHERE status = 1
       AND payment_time IS NULL
       AND create_time < NOW() - INTERVAL '30 minutes');

-- 执行更新
UPDATE orders
SET status = 5,  -- 5=已取消
    update_time = NOW()
WHERE status = 1
  AND payment_time IS NULL
  AND create_time < NOW() - INTERVAL '30 minutes';

-- 记录操作结果
RAISE NOTICE '✅ 已取消 % 条超时订单',
    (SELECT COUNT(*) FROM orders
     WHERE status = 5
       AND update_time >= NOW() - INTERVAL '1 minute');

COMMIT;

-- 回滚: 需要从备份恢复或重新计算状态
```

### 基于条件的批量修复

```sql
-- ============================================================================
-- V2026050413__fix_order_amounts.sql
-- 修复订单金额计算错误的数据
-- ============================================================================

BEGIN;

-- 先查找异常数据
CREATE TEMPORARY TABLE temp_fix_orders AS
SELECT id, total_amount, expected_amount
FROM orders
WHERE ABS(total_amount - expected_amount) > 0.01;

RAISE NOTICE '发现 % 条金额异常的订单需要修复',
    (SELECT COUNT(*) FROM temp_fix_orders);

-- 展示前10条样本（供人工审核）
-- SELECT * FROM temp_fix_orders LIMIT 10;

-- 确认后执行修复
UPDATE orders
SET total_amount = expected_amount,
    update_time = NOW()
WHERE id IN (SELECT id FROM temp_fix_orders);

-- 验证修复结果
RAISE NOTICE '✅ 修复完成，剩余异常数量: %',
    (SELECT COUNT(*) FROM orders
     WHERE ABS(total_amount - expected_amount) > 0.01);

DROP TABLE temp_fix_orders;

COMMIT;
```

---

## 7. 软删除实现

```sql
-- ============================================================================
-- V2026050414__implement_soft_delete.sql
-- 实现软删除机制（替代硬删除）
-- ============================================================================

BEGIN;

-- 第一步：为需要的表添加删除标记字段（如果不存在）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'articles' AND column_name = 'is_deleted'
    ) THEN
        ALTER TABLE articles ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT FALSE;
        ALTER TABLE articles ADD COLUMN deleted_at TIMESTAMP;
        COMMENT ON COLUMN articles.is_deleted IS '软删除标记';
        COMMENT ON COLUMN articles.deleted_at IS '删除时间';
    END IF;
END $$;

-- 第二步：创建部分索引排除已删除数据（提升查询性能）
CREATE INDEX IF NOT EXISTS idx_articles_active
    ON articles(status, create_time)
    WHERE is_deleted = FALSE;

-- 第三步：修改现有查询（需要在应用层配合）
-- 原查询: SELECT * FROM articles WHERE status = 1;
-- 新查询: SELECT * FROM articles WHERE status = 1 AND is_deleted = FALSE;

-- 第四步：软删除函数（可选）
CREATE OR REPLACE FUNCTION soft_delete_article(article_id BIGINT)
RETURNS VOID AS $$
BEGIN
    UPDATE articles
    SET is_deleted = TRUE,
        deleted_at = NOW(),
        update_time = NOW()
    WHERE id = article_id AND is_deleted = FALSE;

    IF NOT FOUND THEN
        RAISE EXCEPTION '文章 % 不存在或已被删除', article_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

COMMIT;

-- 使用示例：
-- SELECT soft_delete_article(123);

-- 回滚:
-- ALTER TABLE articles DROP COLUMN IF EXISTS is_deleted;
-- ALTER TABLE articles DROP COLUMN IF EXISTS deleted_at;
-- DROP FUNCTION IF EXISTS soft_delete_article(BIGINT);
```

---

## 8. 视图创建示例

### 只读汇总视图

```sql
-- ============================================================================
-- V2026050415__create_order_summary_view.sql
-- 创建订单汇总视图（简化复杂查询）
-- ============================================================================

CREATE OR REPLACE VIEW v_order_summary AS
SELECT
    o.id AS order_id,
    o.order_no,
    o.user_id,
    u.username,
    u.email,
    o.total_amount,
    o.pay_amount,
    o.status,
    CASE o.status
        WHEN 1 THEN '待支付'
        WHEN 2 THEN '已支付'
        WHEN 3 THEN '已发货'
        WHEN 4 THEN '已完成'
        WHEN 5 THEN '已取消'
        ELSE '未知'
    END AS status_text,
    o.payment_time,
    o.create_time,
    (SELECT COUNT(*) FROM order_items oi WHERE oi.order_id = o.id) AS item_count,
    (SELECT COALESCE(SUM(oi.quantity), 0) FROM order_items oi WHERE oi.order_id = o.id) AS total_quantity
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE o.is_deleted = FALSE;  -- 如果实现了软删除

-- 视图注释
COMMENT ON VIEW v_order_summary IS '订单汇总视图（关联用户信息和订单明细统计）';

-- 验证视图
SELECT * FROM v_order_summary LIMIT 5;

-- 授权（如果需要）
-- GRANT SELECT ON v_order_summary TO app_readonly_role;

-- 回滚: DROP VIEW IF EXISTS v_order_summary;
```

---

## 9. 存储过程示例

### 数据归档存储过程

```sql
-- ============================================================================
-- V2026050416__create_archive_procedure.sql
-- 创建日志归档存储过程
-- ============================================================================

CREATE OR REPLACE PROCEDURE archive_logs(
    p_days_old INTEGER DEFAULT 90,
    p_batch_size INTEGER DEFAULT 10000,
    p_dry_run BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_archived INTEGER := 0;
    v_batch_count INTEGER;
    v_cutoff_date TIMESTAMP := NOW() - (p_days_old || ' days')::INTERVAL;
BEGIN
    RAISE NOTICE '开始归档 % 天前的日志数据...', p_days_old;
    RAISE NOTICE '截止日期: %', v_cutoff_date;

    LOOP
        -- 每批处理指定数量的记录
        WITH archived AS (
            DELETE FROM logs
            WHERE create_time < v_cutoff_date
            LIMIT p_batch_size
            RETURNING *
        )
        INSERT INTO logs_archive (table_name, operation, old_data, new_data, operator, create_time)
        SELECT table_name, operation, old_data::JSONB, new_data::JSONB, operator, create_time
        FROM archived;

        GET DIAGNOSTICS v_batch_count = ROW_COUNT;
        v_total_archived := v_total_archived + v_batch_count;

        EXIT WHEN v_batch_count = 0;

        RAISE NOTICE '已归档 % 条（本批 % 条）', v_total_archived, v_batch_count;

        -- 每10万条提交一次，避免长事务
        IF MOD(v_total_archived, 100000) = 0 THEN
            RAISE NOTICE '提交中间点...';
        END IF;
    END LOOP;

    IF p_dry_run THEN
        RAISE NOTICE '🔍 [DRY RUN] 将归档约 % 条记录', v_total_archived;
        ROLLBACK;
    ELSE
        RAISE NOTICE '✅ 归档完成！共处理 % 条记录', v_total_archived;
        COMMIT;
    END IF;
END;
$$;

-- 使用示例：
-- 1. 先试运行（不会真正删除）
-- CALL archive_logs(p_days_old => 365, p_dry_run => TRUE);

-- 2. 确认无误后正式执行
-- CALL archive_logs(p_days_old => 365, p_batch_size => 50000);

-- 回滚: DROP PROCEDURE IF EXISTS archive_logs;
```

---

## 快速复制清单

根据您的需求选择对应模板：

| 需求 | 对应章节 | 风险等级 |
|------|---------|---------|
| 新建业务表 | §1 | 低 |
| 添加简单字段 | §2 | 低 |
| 添加多个字段 | §2 | 中 |
| 数据迁移 | §2/§5 | 高 |
| 修改字段类型 | §3 | 高 |
| 添加索引优化 | §4 | 低 |
| 批量数据处理 | §6 | 高 |
| 实现软删除 | §7 | 中 |
| 创建视图 | §8 | 低 |
| 存储过程 | §9 | 中 |

**提示**: 所有模板都遵循幂等性原则，支持重复执行。在使用前请根据实际表名、字段名进行调整。
