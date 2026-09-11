---
name: "database-change-management"
description: "数据库变更管理规范。在进行涉及数据库结构或数据变更的程序修改时必须使用，确保提供完整可执行的SQL升级脚本、版本控制信息、回滚方案，并符合项目数据库编码规范。"
---

# 数据库变更管理

## 概述

数据库变更是生产环境中最高风险的操作之一。一次错误的DDL操作可能导致数据丢失、服务中断，甚至造成不可挽回的损失。

**核心原则：** 任何涉及数据库结构或数据变更的代码修改，都必须配备完整、经过验证的SQL升级脚本，并随代码一同提交至版本控制。

**没有SQL脚本的数据库变更 = 禁止提交**

## 规则引导（最高优先级，执行本技能前必须加载）

本技能运行于 CMSPRO 工作区，执行任何动作前必须先读取并全程遵循以下三份规则文件：

| 规则文件 | 核心约束 |
|----------|----------|
| `rules/01-CMSPRO开发规范.md` | ① 全局框架保护：禁改 `vendor/`、`config/`、`routes/` 等全局代码，扩展一律走 `app/Apps/{AppName}/`；② 动手前必读开发文档与应用自身 `doc/` 文档；③ 应用调整后必须用 Laravel 内置测试验证、必须同步更新应用文档；④ 日期时间统一 `Y-m-d H:i:s`，禁止 ISO 8601；⑤ 排查问题先看数据（var_dump/查库），禁止从报错文案反推猜测 |
| `rules/02-CMSPRO协作总则.md` | ① 全程中文思考与回复；② 收到任务先检查匹配技能；③ 设计先于编码（brainstorming）；④ 测试先于实现（TDD）；⑤ 验证先于完成 |
| `rules/03-通用编码准则.md` | ① 编码前先思考：列明假设、主动澄清，不臆测业务；② 优先简洁：不做需求之外的抽象与配置；③ 精准修改：每行改动对应需求，不碰无关代码；④ 目标驱动：任务转化为可验证目标，循环验证至达标 |

> 冲突处理：本技能流程与上述规则冲突时，以规则为准；规则未覆盖的场景按本技能流程执行。

## 何时使用

**必须在以下场景使用此技能：**
- 新建数据表（CREATE TABLE）
- 修改表结构（ALTER TABLE - 添加/修改/删除字段、索引、约束）
- 数据迁移（INSERT/UPDATE/DELETE 批量数据处理）
- 修改字段类型或属性
- 添加/删除索引
- 创建/修改视图、存储过程、触发器
- 修改表名或字段名
- 数据归档或清理
- 任何影响数据库结构或数据的程序修改

**即使看起来很小的变更也必须遵循此流程：**
- "只是加一个字段" → 必须有SQL脚本
- "只是改个字段类型" → 必须有SQL脚本 + 数据迁移方案
- "只是加个索引" → 必须有SQL脚本 + 性能评估

## 铁律

```
涉及数据库变更的代码提交，必须包含对应SQL升级脚本
```

## SQL脚本标准模板

每个数据库变更必须创建独立的SQL文件，命名格式为：

```
V{版本号}__{简短描述}.sql
```

### 示例文件名
```
V2026050401__add_user_avatar_field.sql
V2026050402__create_order_index.sql
V2026050403__migrate_user_phone_data.sql
```

### SQL脚本完整模板

```sql
-- ============================================================================
-- 数据库变更脚本
-- ============================================================================
-- 版本号: V2026050401
-- 变更描述: 为用户表添加头像字段
-- 影响表: users
-- 变更类型: DDL (结构变更)
-- 作者: [开发者姓名]
-- 创建日期: 2026-05-04
-- 关联需求/Issue: #1234
-- 预计执行时间: < 1秒
-- 风险等级: 低
-- ============================================================================

-- ---------- 前置检查 ----------
-- 确认字段不存在，避免重复执行报错
SELECT COUNT(*)
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name = 'avatar_url';

-- 如果字段已存在，跳过后续操作（幂等性保证）
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'users' AND column_name = 'avatar_url'
    ) THEN
        -- ---------- 正向变更 ----------
        ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500) DEFAULT NULL;

        -- 添加注释
        COMMENT ON COLUMN users.avatar_url IS '用户头像URL地址';

        RAISE NOTICE '字段 avatar_url 添加成功';
    ELSE
        RAISE NOTICE '字段 avatar_url 已存在，跳过添加';
    END IF;
END $$;

-- ---------- 数据验证 ----------
-- 验证字段是否添加成功
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
  AND column_name = 'avatar_url';

-- ---------- 回滚方案 ----------
-- 如需回滚，执行以下SQL:
-- ALTER TABLE users DROP COLUMN IF EXISTS avatar_url;
```

## 变更分类与要求

### 一、DDL变更（结构变更）

#### 1. 新建表 (CREATE TABLE)

```sql
-- V{版本号}__{表名}_table_creation.sql
-- 变更类型: DDL - 新建表

-- 必须包含的内容:
-- ✓ 表结构定义（所有字段、类型、约束）
-- ✓ 主键定义
-- ✓ 索引定义（根据查询需求）
-- ✓ 字段注释
-- ✓ 表注释
-- ✓ 基础字段（id, status, create_time, update_time）
-- ✓ 幂等性处理（IF NOT EXISTS）
-- ✓ 回滚方案（DROP TABLE）

CREATE TABLE IF NOT EXISTS order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    status SMALLINT NOT NULL DEFAULT 1,
    create_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    update_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- 约束
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(id),
    CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(id)
);

-- 索引
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON order_items(product_id);

-- 表注释
COMMENT ON TABLE order_items IS '订单商品明细表';

-- 字段注释
COMMENT ON COLUMN order_items.id IS '主键ID';
COMMENT ON COLUMN order_items.order_id IS '关联订单ID';
COMMENT ON COLUMN order_items.product_id IS '关联商品ID';
COMMENT ON COLUMN order_items.quantity IS '购买数量';
COMMENT ON COLUMN order_items.unit_price IS '单价';
COMMENT ON COLUMN order_items.total_price IS '小计金额（自动计算）';
COMMENT ON COLUMN order_items.status IS '状态：1-正常 2-已取消';

-- 回滚方案:
-- DROP TABLE IF EXISTS order_items CASCADE;
```

#### 2. 添加字段 (ALTER TABLE ADD)

```sql
-- 关键要点:
-- ✓ 检查字段是否已存在（幂等性）
-- ✓ 设置合理的默认值（避免NULL问题）
-- ✓ 考虑现有数据的兼容性
-- ✓ 大表添加字段需评估锁表时间
-- ✓ 添加字段注释

-- 示例：为大表添加字段（低风险方式）
ALTER TABLE large_table ADD COLUMN IF NOT EXISTS new_field VARCHAR(100) DEFAULT NULL;

-- 如果需要设置非空约束，分两步执行：
-- 第一步：添加可为空的字段 + 数据迁移
ALTER TABLE users ADD COLUMN IF NOT EXISTS nickname VARCHAR(50) DEFAULT NULL;
UPDATE users SET nickname = username WHERE nickname IS NULL;

-- 第二步：在业务低峰期添加非空约束
-- ALTER TABLE users ALTER COLUMN nickname SET NOT NULL;
```

#### 3. 修改字段类型 (ALTER TABLE ALTER)

```sql
-- ⚠️ 高风险操作，必须谨慎！

-- 场景1: 类型兼容（安全）
-- VARCHAR(50) → VARCHAR(100)
ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(100);

-- 场景2: 类型不兼容（需数据转换）
-- INT → BIGINT（扩大范围，通常安全）
ALTER TABLE orders ALTER COLUMN amount TYPE BIGINT;

-- 场景3: 需要USING表达式转换
-- VARCHAR → TIMESTAMP
ALTER TABLE logs ALTER COLUMN log_time TYPE TIMESTAMP
    USING TO_TIMESTAMP(log_time, 'YYYY-MM-DD HH24:MI:SS');

-- ⚠️ 必须在测试环境充分验证数据转换的正确性
-- ⚠️ 大表操作建议在业务低峰期执行
-- ⚠️ 执行前必须备份相关表数据
```

#### 4. 删除字段/表 (DROP)

```sql
-- ⚠️ 极高风险操作！必须多重确认！

-- 删除前检查清单:
-- [ ] 确认无代码引用该字段/表
-- [ ] 确认无视图、存储过程依赖
-- [ ] 确认无外键关联
-- [ ] 已在代码中移除相关逻辑
-- [ ] 已在测试环境验证通过
-- [ ] 已准备回滚方案（从备份恢复）

-- 删除字段
ALTER TABLE users DROP COLUMN IF EXISTS deprecated_field;

-- 删除表
DROP TABLE IF EXISTS deprecated_table CASCADE;

-- 建议：先标记为废弃，保留1-2个版本后再物理删除
-- ALTER TABLE users RENAME COLUMN old_field TO _deprecated_old_field_20260504;
```

#### 5. 索引管理

```sql
-- 创建索引
CREATE INDEX IF NOT EXISTS idx_table_column ON table_name(column_name);

-- 复合索引（注意字段顺序，遵循最左前缀原则）
CREATE INDEX IF NOT EXISTS idx_orders_user_status ON orders(user_id, status, create_time);

-- 唯一索引
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 部分索引（条件索引，减少索引大小）
CREATE INDEX IF NOT EXISTS idx_orders_pending ON orders(create_time)
WHERE status = 1;

-- 删除索引
DROP INDEX IF EXISTS idx_table_column;

-- ⚠️ 注意事项:
-- - 索引会增加写入开销，不要过度索引
-- - 复合索引字段顺序很重要
-- - 大表创建索引会锁定表，考虑使用 CONCURRENTLY (PostgreSQL)
-- CREATE INDEX CONCURRENTLY idx_large_table_col ON large_table(column);
```

### 二、DML变更（数据变更）

#### 1. 数据插入 (INSERT)

```sql
-- 单条插入
INSERT INTO config (config_key, config_value, description, create_time)
VALUES ('app_version', '2.0.0', '应用版本号', NOW())
ON CONFLICT (config_key) DO UPDATE SET
    config_value = EXCLUDED.config_value,
    update_time = NOW();

-- 批量插入（使用批量操作，避免逐条插入）
INSERT INTO user_roles (user_id, role_id, create_time)
VALUES
    (1, 101, NOW()),
    (1, 102, NOW()),
    (2, 101, NOW())
ON CONFLICT DO NOTHING;
```

#### 2. 数据更新 (UPDATE)

```sql
-- ⚠️ 更新前务必确认 WHERE 条件正确！

-- 安全更新模式：
-- 先用 SELECT 验证影响的行数
-- SELECT COUNT(*) FROM users WHERE status = 0 AND create_time < '2026-01-01';

-- 再执行更新
UPDATE users
SET status = 2,
    update_time = NOW()
WHERE status = 0
  AND create_time < '2026-01-01'
  -- 建议添加 LIMIT 限制意外的大规模更新
  -- （PostgreSQL 不支持 UPDATE ... LIMIT，可用子查询实现）

-- 批量更新示例：数据修复
UPDATE orders
SET total_amount = subtotal + shipping_fee + tax
WHERE total_amount IS NULL
  OR total_amount != subtotal + shipping_fee + tax;
```

#### 3. 数据删除 (DELETE)

```sql
-- ⚠️ 极高风险！删除前必须多重确认！

-- 删除流程：
-- 1. 先 SELECT 确认要删除的数据量和内容
-- SELECT COUNT(*) FROM logs WHERE create_time < '2025-01-01';
-- SELECT * FROM logs WHERE create_time < '2025-01-01' LIMIT 10;

-- 2. 小范围测试删除
-- DELETE FROM logs WHERE create_time < '2025-01-01' LIMIT 100;

-- 3. 验证结果后，再执行正式删除
-- DELETE FROM logs WHERE create_time < '2025-01-01';

-- 4. 硬删除 vs 软删除
-- 推荐软删除（更新状态字段）：
UPDATE users SET status = 0, update_time = NOW() WHERE id = ?;

-- 硬删除仅用于：
-- - 测试数据清理
-- - 明确的业务需求（如GDPR数据删除请求）
-- - 有明确的数据保留策略
```

#### 4. 数据迁移

```sql
-- V{版本号}__migrate_{description}.sql
-- 变更类型: DML - 数据迁移

-- 示例：将手机号从users表迁移到user_phones表

-- 开始事务
BEGIN;

-- 创建临时备份表（安全措施）
CREATE TEMPORARY TABLE temp_user_phones_backup AS
SELECT id AS user_id, phone FROM users WHERE phone IS NOT NULL AND phone != '';

-- 插入数据到新表（去重）
INSERT INTO user_phones (user_id, phone, phone_type, is_verified, create_time)
SELECT DISTINCT ON (phone)
       id,
       phone,
       'mobile',
       CASE WHEN phone_verified THEN 1 ELSE 0 END,
       NOW()
FROM users
WHERE phone IS NOT NULL
  AND phone != ''
  AND NOT EXISTS (
      SELECT 1 FROM user_phones WHERE user_phones.user_id = users.id
  )
ON CONFLICT (user_id) DO NOTHING;

-- 记录迁移结果
RAISE NOTICE '迁移完成，共处理 % 条记录', (SELECT COUNT(*) FROM temp_user_phones_backup);

-- 验证数据完整性
SELECT
    (SELECT COUNT(*) FROM temp_user_phones_backup) AS source_count,
    (SELECT COUNT(*) FROM user_phones) AS target_count;

-- 可选：清空原表中的手机号字段（确认迁移成功后）
-- UPDATE users SET phone = NULL WHERE phone IS NOT NULL;

COMMIT;

-- 回滚方案:
-- 从备份恢复或重新运行迁移前的数据状态
```

## 版本控制与提交规范

### 文件组织结构

```
project-root/
├── sql/
│   └── migrations/
│       ├── V2026050401__create_users_table.sql
│       ├── V2026050402__add_order_status_field.sql
│       ├── V2026050403__migrate_user_data.sql
│       └── rollback/
│           ├── R2026050402__add_order_status_field.sql
│           └── ...
├── src/
│   └── (代码文件)
└── README.md
```

### Git提交规范

每次数据库变更必须是独立的原子提交：

```bash
# 提交格式
git add sql/migrations/V2026050401__xxx.sql
git commit -m "feat(db): V2026050401 添加用户头像字段"

# 如果同时有代码变更，分开提交
git add src/components/UserAvatar.tsx
git commit -m "feat(user): 新增用户头像展示功能")

# 关联Issue（如有）
git commit -m "feat(db): V2026050402 创建订单索引

Closes #1234"
```

### 提交检查清单

在提交数据库变更前，必须确认：

- [ ] SQL脚本文件存在且命名规范
- [ ] 脚本包含完整的版本信息和变更说明
- [ ] 脚本具有幂等性（可重复执行不报错）
- [ ] 包含正向变更语句
- [ ] 包含回滚方案（注释或独立文件）
- [ ] 包含数据验证语句
- [ ] 在开发环境测试通过
- [ ] 在测试环境验证通过
- [ ] 大表操作已评估性能影响
- [ ] 敏感操作（DROP、大规模UPDATE/DELETE）已进行代码审查
- [ ] 相关代码变更已同步提交

## 测试验证流程

### 1. 开发环境验证

```bash
# 连接开发数据库
psql -h localhost -U dev_user -d dev_database

# 执行SQL脚本
\i sql/migrations/V2026050401__xxx.sql

# 验证结果
\d table_name
SELECT * FROM table_name LIMIT 5;
```

### 2. 测试环境验证

```bash
# 使用测试数据库（数据量接近生产）
psql -h test-db.example.com -U test_user -d test_database

# 先备份数据（重要！）
pg_dump -h test-db -U test_user -d test_database > backup_before_migration.sql

# 执行迁移
\i sql/migrations/V2026050401__xxx.sql

# 运行回归测试
npm test

# 验证应用功能正常
# 手动测试相关功能模块
```

### 3. 性能评估（针对大表操作）

```sql
-- 评估ALTER TABLE的锁表时间
-- 对于PostgreSQL，查看当前锁情况
SELECT pid, mode, query, query_start
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE relation = 'table_name'::regclass;

-- 评估索引创建对写入性能的影响
-- 在测试环境模拟高并发写入，观察性能指标
```

## 常见场景速查

| 变更类型 | 操作 | 风险等级 | 是否需要停机 | 备注 |
|---------|------|---------|-------------|------|
| 添加可为空字段 | ALTER TABLE ADD | 低 | 否 | 使用IF NOT EXISTS |
| 添加非空字段 | ALTER TABLE ADD + UPDATE | 中 | 可能需要 | 分两步执行 |
| 修改字段类型（兼容） | ALTER TABLE ALTER TYPE | 低 | 否 | 如VARCHAR扩容 |
| 修改字段类型（不兼容） | ALTER TABLE ALTER TYPE USING | 高 | 建议停机 | 需数据转换 |
| 添加索引 | CREATE INDEX | 低 | 否 | 大表用CONCURRENTLY |
| 删除字段 | ALTER TABLE DROP | 中 | 否 | 确认无依赖 |
| 删除表 | DROP TABLE | 高 | 建议停机 | 多重确认 |
| 批量UPDATE | UPDATE ... WHERE | 高 | 视数据量 | 先SELECT验证 |
| 批量DELETE | DELETE ... WHERE | 极高 | 视数据量 | 优先软删除 |
| 数据迁移 | INSERT ... SELECT | 高 | 视数据量 | 使用事务 |

## 最佳实践

### 1. 幂等性设计

所有SQL脚本必须支持重复执行而不出错：

```sql
-- ✅ 正确：使用 IF EXISTS / IF NOT EXISTS
ALTER TABLE users ADD COLUMN IF NOT EXISTS new_field VARCHAR(100);
CREATE INDEX IF NOT EXISTS idx_name ON table(column);
DROP TABLE IF EXISTS temp_table;

-- ❌ 错误：直接执行，重复运行会报错
ALTER TABLE users ADD COLUMN new_field VARCHAR(100);  -- 第二次执行报错
```

### 2. 事务管理

```sql
-- 相关操作放在同一事务中
BEGIN;

-- 多个相关DDL/DML操作
ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT FALSE;
UPDATE users SET email_verified = TRUE WHERE email LIKE '%@company.com';
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email_verified);

-- 验证
SELECT COUNT(*) FROM users WHERE email_verified IS NULL;

-- 全部成功则提交，否则回滚
COMMIT;
-- 或 ROLLBACK;
```

### 3. 渐进式发布策略

对于高风险变更：

```sql
-- 第一阶段：添加新字段（可为空）
ALTER TABLE users ADD COLUMN new_preference JSONB DEFAULT NULL;

-- 第二阶段：部署代码，双写新旧字段
-- （代码层面处理）

-- 第三阶段：数据迁移（后台任务）
UPDATE users SET new_preference = build_jsonb(old_pref) WHERE new_preference IS NULL;

-- 第四阶段：验证数据一致性
SELECT COUNT(*) FROM users WHERE new_preference != build_jsonb(old_pref);

-- 第五阶段：切换代码到新字段
-- （代码层面处理）

-- 第六阶段：清理旧字段（下一版本）
-- ALTER TABLE users DROP COLUMN old_preference;
```

### 4. 备份策略

```bash
# 变更前自动备份（推荐集成到CI/CD）
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
    --table=affected_table \
    > backups/${TIMESTAMP}_${TABLE_NAME}_pre_migration.sql

# 验证备份完整性
pg_restore --list backups/*.sql | head -20
```

## 错误预防清单

在执行数据库变更前，逐一确认：

### 语法与逻辑检查
- [ ] SQL语法正确（在测试环境解析通过）
- [ ] 所有表名、字段名拼写正确
- [ ] 数据类型匹配
- [ ] WHERE条件逻辑正确（防止误操作）
- [ ] 外键关系正确维护

### 兼容性检查
- [ ] 与现有数据兼容（无类型冲突）
- [ ] 与现有索引兼容
- [ ] 与现有约束兼容
- [ ] 与应用程序ORM/查询兼容
- [ ] 与数据库版本特性兼容

### 性能评估
- [ ] 评估锁表时间（ALTER TABLE）
- [ ] 评估索引对写入性能的影响
- [ ] 评估查询计划变化（EXPLAIN ANALYZE）
- [ ] 大表操作选择合适的执行时间窗口

### 安全检查
- [ ] 无硬编码敏感信息
- [ ] 无SQL注入风险（动态SQL场景）
- [ ] 权限最小化原则
- [ ] 审计日志记录关键操作

## 红线——绝对禁止的行为

❌ **禁止在没有SQL脚本的情况下提交数据库相关的代码变更**

❌ **禁止在生产环境直接执行未经验证的SQL**

❌ **禁止省略回滚方案**

❌ **禁止在业务高峰期执行高风险DDL操作**

❌ **禁止DELETE/WHERE 1=1 或没有WHERE条件的UPDATE/DELETE**

❌ **禁止跳过测试环境直接上生产**

❌ **禁止使用SELECT * 生产查询（明确列出所需字段）**

❌ **禁止在循环中执行单条SQL（使用批量操作）**

## 快速参考卡片

### SQL脚本必备要素

```
✅ 版本号 (VYYYYMMDDNN)
✅ 变更描述
✅ 影响范围（表/字段）
✅ 变更类型（DDL/DML）
✅ 作者和日期
✅ 正向变更语句
✅ 幂等性处理
✅ 数据验证语句
✅ 回滚方案
```

### 风险等级判断

🟢 **低风险**: 添加可为空字段、创建索引、添加注释
🟡 **中风险**: 修改字段属性、批量数据更新、添加非空字段
🔴 **高风险**: 修改字段类型、删除字段/表、大规模数据迁移、Schema重构

### 紧急回滚流程

```bash
# 1. 立即停止应用（如果有正在执行的变更）
# 2. 从备份恢复（如果已有备份）
pg_restore -h localhost -U db_user -d database backup_file.sql

# 3. 或者执行回滚SQL脚本
psql -h localhost -U db_user -d database -f sql/rollback/Rxxxxxx__rollback.sql

# 4. 验证数据完整性
# 5. 通知相关人员
# 6. 记录事故报告
```

---

## 辅助文档

本目录下的辅助资源：

- **`sql-template-examples.md`** - 各类SQL变更的完整示例模板
- **`checklist.md`** - 变更前检查清单（可打印）
- **`troubleshooting.md`** - 常见问题和解决方案

**相关技能：**
- **superpowers:dev-standards** - 通用开发规范（本技能的基础）
- **superpowers:test-driven-development** - 测试驱动开发（用于编写数据库变更的测试）
- **superpowers:verification-before-completion** - 完成前验证（确保SQL脚本经过充分测试）
- **superpowers:systematic-debugging** - 系统化调试（排查数据库变更引起的问题）

## 实际效果

实施数据库变更管理规范后的改进：
- 数据库事故率降低 90%
- 变更回滚时间从小时级缩短到分钟级
- 团队协作效率提升（清晰的变更历史）
- 审计合规性显著改善
- 新人上手时间缩短（标准化流程）
