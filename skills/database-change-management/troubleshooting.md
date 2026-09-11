# 数据库变更常见问题与解决方案

本文档汇总数据库变更过程中常见的问题、错误及其解决方案。

---

## 目录

1. [SQL执行错误](#1-sql执行错误)
2. [锁与并发问题](#2-锁与并发问题)
3. [数据迁移问题](#3-数据迁移问题)
4. [性能问题](#4-性能问题)
5. [回滚失败](#5-回滚失败)
6. [环境差异问题](#6-环境差异问题)

---

## 1. SQL执行错误

### 错误：relation "xxx" already exists

**原因**: 表已存在，尝试重复创建

**解决方案**:
```sql
-- 使用 IF NOT EXISTS
CREATE TABLE IF NOT EXISTS table_name (...);

-- 或者先检查再创建
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'xxx') THEN
        -- 创建表
    END IF;
END $$;
```

### 错误：column "xxx" of relation "xxx" already exists

**原因**: 字段已存在

**解决方案**:
```sql
ALTER TABLE table_name ADD COLUMN IF NOT EXISTS column_name TYPE;
```

### 错误：cannot alter type of a column used by a view or rule

**原因**: 字段被视图或规则引用

**解决方案**:
```sql
-- 先查看依赖关系
SELECT dependent_ns.nspname as dependent_schema,
       dependent_class.relname as dependent_name,
       dependent_class.relkind as dependent_type,
       pg_get_dependent_ddl(objid, refobjid) as dependency_definition
FROM pg_depend
JOIN pg_rewrite ON pg_depend.objid = pg_rewrite.oid
JOIN pg_class as dependent_class ON pg_rewrite.ev_class = dependent_class.oid
JOIN pg_namespace as dependent_ns ON dependent_class.relnamespace = dependent_ns.oid
WHERE pg_depend.refclassid = 'pg_class'::regclass
  AND pg_depend.refobjid = 'your_table'::regclass;

-- 需要先删除或修改依赖的视图/规则，然后再修改字段
```

### 错误：value too long for type character varying(n)

**原因**: 数据超出字段长度限制

**解决方案**:
```sql
-- 方案1: 先清理超长数据
UPDATE table_name SET column_name = LEFT(column_name, n)
WHERE LENGTH(column_name) > n;

-- 方案2: 扩大字段长度（如果业务允许）
ALTER TABLE table_name ALTER COLUMN column_name TYPE VARCHAR(new_length);
```

### 错误：duplicate key value violates unique constraint

**原因**: 唯一约束冲突

**解决方案**:
```sql
-- 查找重复数据
SELECT column_name, COUNT(*)
FROM table_name
GROUP BY column_name
HAVING COUNT(*) > 1;

-- 处理重复数据（保留最新的一条）
DELETE FROM table_name a
WHERE EXISTS (
    SELECT 1 FROM table_name b
    WHERE b.column_name = a.column_name
      AND b.id > a.id
);
```

---

## 2. 锁与并发问题

### 问题：ALTER TABLE 导致应用超时

**现象**: 执行DDL时，应用查询超时或报错

**原因**: DDL操作会获取排他锁，阻塞其他操作

**解决方案**:
```sql
-- PostgreSQL: 使用 CONCURRENTLY 创建索引（不锁表）
CREATE INDEX CONCURRENTLY idx_name ON table(column);

-- 对于大表的 ALTER TABLE：
-- 1. 使用 pt-online-schema-change (MySQL)
-- 2. 使用 pg_repack (PostgreSQL)
-- 3. 选择低峰期执行
-- 4. 分阶段执行（先添加可为空字段，后续再添加约束）

-- 查看当前锁情况
SELECT pid, mode, granted, query, query_start, age(now(), query_start) AS duration
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE relation = 'table_name'::regclass
ORDER BY duration DESC;
```

### 问题：长事务阻塞DDL

**现象**: ALTER TABLE一直等待

**原因**: 有长时间运行的事务持有表锁

**解决方案**:
```sql
-- 查找阻塞的事务
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes'
  AND state != 'idle'
  AND pid != pg_backend_pid();

-- 如果确认可以安全终止
-- SELECT pg_terminate_pid(pid);

-- 更安全的方式：通知相关应用先释放连接
```

---

## 3. 数据迁移问题

### 问题：数据迁移后数量不一致

**原因**: 源数据和目标数据统计不一致

**诊断步骤**:
```sql
-- 对比源和目标的数据量
SELECT
    (SELECT COUNT(*) FROM source_table) AS source_count,
    (SELECT COUNT(*) FROM target_table) AS target_count;

-- 检查是否有NULL值导致的不一致
SELECT COUNT(*)
FROM source_table s
LEFT JOIN target_table t ON s.id = t.id
WHERE t.id IS NULL;  -- 未迁移的记录

-- 检查是否有重复键导致插入失败
SELECT column_name, COUNT(*) as cnt
FROM source_table
GROUP BY column_name
HAVING COUNT(*) > 1;
```

### 问题：类型转换导致数据丢失或错误

**现象**: 迁移后数据异常（截断、乱码等）

**预防措施**:
```sql
-- 转换前验证数据兼容性
-- 检查是否有无法转换的数据
SELECT * FROM table_name
WHERE column_name !~ '^[0-9]+$'  -- 应该是数字但包含非数字字符
   OR LENGTH(column_name) > max_length;  -- 超出目标长度

-- 使用安全的转换函数
CAST(column_name AS INTEGER)  -- 可能报错
column_name::INTEGER           -- 同上

-- 安全转换（返回NULL而非报错）
NULLIF(column_name, '')::INTEGER

-- 或使用CASE处理异常
CASE
    WHEN column_name ~ '^[0-9]+$' THEN column_name::INTEGER
    ELSE NULL
END
```

### 问题：外键约束导致导入失败

**现象**: 导入数据时报外键约束违反错误

**解决方案**:
```sql
-- 方案1: 先禁用外键约束，导入后再启用（PostgreSQL不支持直接禁用）
-- 改为：按依赖顺序导入（先父表后子表）

-- 方案2: 使用 DEFERRABLE 约束（事务结束时检查）
ALTER TABLE child_table
DROP CONSTRAINT fk_constraint,
ADD CONSTRAINT fk_constraint
FOREIGN KEY (parent_id) REFERENCES parent_table(id)
DEFERRABLE INITIALLY DEFERRED;

-- 方案3: 分批导入，先导入无关联数据
INSERT INTO child_table (...)
SELECT ...
FROM temp_data
WHERE parent_id IN (SELECT id FROM parent_table);
```

---

## 4. 性能问题

### 问题：批量更新导致数据库负载飙升

**现象**: CPU/IO使用率100%，查询变慢

**优化方案**:
```sql
-- 分批次处理（每批1000-5000条）
DO $$
DECLARE
    batch_count INTEGER := 0;
    total_updated INTEGER := 0;
BEGIN
    LOOP
        WITH updated AS (
            UPDATE large_table
            SET status = new_value
            WHERE status = old_value
            LIMIT 5000
            RETURNING id
        )
        SELECT COUNT(*) INTO batch_count FROM updated;

        total_updated := total_updated + batch_count;
        RAISE NOTICE '已更新 % 条（本批 % 条）', total_updated, batch_count;

        EXIT WHEN batch_count = 0;

        -- 短暂暂停，给其他操作让出资源
        PERFORM pg_sleep(0.1);
    END LOOP;
END $$;
```

### 问题：索引过多导致写入性能下降

**现象**: INSERT/UPDATE变慢

**诊断**:
```sql
-- 查看表的索引数量
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'your_table';

-- 分析未使用的索引
SELECT schemaname || '.' || relname AS table_name,
       indexrelname AS index_name,
       idx_scan AS index_scans,
       pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
       idx_tup_read + idx_tup_fetch AS tuples_read
FROM pg_stat_user_indexes
JOIN pg_index ON pg_stat_user_indexes.indexrelid = pg_index.indexrelid
WHERE schemaname = 'public'
  AND idx_scan < 50  -- 很少使用的索引
  AND NOT indisunique  -- 排除唯一索引
ORDER BY idx_scan ASC;
```

### 问题：全表扫描导致查询慢

**现象**: 某些查询突然变慢

**解决**:
```sql
-- 分析执行计划
EXPLAIN ANALYZE SELECT * FROM table_name WHERE column = value;

-- 如果发现 Seq Scan（全表扫描），考虑添加索引
CREATE INDEX IF NOT EXISTS idx_name ON table_name(column);

-- 更新统计信息
ANALYZE table_name;
```

---

## 5. 回滚失败

### 问题：回滚脚本执行失败

**可能原因及解决**:

1. **回滚脚本本身有语法错误**
   - 在测试环境充分测试回滚脚本
   - 保持回滚脚本的幂等性

2. **回滚期间有其他依赖变更**
   - 记录完整的变更历史
   - 按反向顺序回滚

3. **数据已被其他操作修改**
   ```sql
   -- 从备份恢复是最可靠的方式
   psql -h host -U user -d database < backup_file.sql

   -- 或使用时间点恢复（PITR）(PostgreSQL)
   ```

4. **缺少备份**
   - **教训**: 这是最大的教训！永远在变更前备份！
   - 尝试从binlog/wal日志中提取原始数据
   - 联系DBA协助专业恢复

### 最佳实践：可靠的回滚方案

```sql
-- ✅ 好的回滚方案示例：

-- 正向变更
ALTER TABLE users ADD COLUMN IF NOT EXISTS new_field VARCHAR(100) DEFAULT NULL;

-- 在同一文件末尾提供回滚SQL（注释形式）
/*
-- ========== 回滚方案 ==========
-- 执行时间: 即时
-- 影响范围: users表
-- 风险等级: 低

ALTER TABLE users DROP COLUMN IF EXISTS new_field;

-- 验证回滚成功
SELECT column_name FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'new_field';
-- （应无结果返回）
*/
```

---

## 6. 环境差异问题

### 问题：开发环境正常，生产环境报错

**常见差异点**:

| 差异项 | 开发环境 | 生产环境 |
|--------|---------|---------|
| 数据量 | 几千条 | 百万/千万级 |
| 数据分布 | 均匀 | 可能有极端值 |
| 数据库版本 | 较新 | 可能较旧 |
| 配置参数 | 默认 | 已调优 |
| 权限 | 超级用户 | 受限用户 |

**解决方案**:

1. **使用接近生产数据的测试环境**
   - 数据脱敏后的生产数据副本
   - 至少保证数据量级相近

2. **版本兼容性检查**
   ```sql
   SELECT version();  -- 确认数据库版本
   -- 某些语法特性在不同版本间可能有差异
   ```

3. **配置参数对比**
   ```sql
   SHOW all;  -- 查看所有配置参数
   -- 特别关注: work_mem, shared_buffers, max_connections 等
   ```

4. **权限预检**
   ```sql
   -- 在生产环境用实际执行账号测试
   -- SET ROLE app_user;
   -- \i your_script.sql
   ```

### 问题：字符集/编码问题

**现象**: 中文显示为乱码或问号

**解决方案**:
```sql
-- 检查数据库编码
SHOW server_encoding;  -- 应该是 UTF8

-- 检查客户端编码
SHOW client_encoding;  -- 应该是 UTF8

-- 设置正确的编码
SET client_encoding TO 'UTF8';

-- 如果已有乱码数据，尝试修复（复杂且不一定成功）
-- 最好从源头确保编码一致性
```

---

## 🆘 紧急情况处理流程

### 场景：生产环境执行SQL后出现严重问题

#### 第一步：立即止损（0-5分钟）
```bash
# 1. 如果正在执行，立即停止（Ctrl+C 或终止会话）
# 2. 停止应用服务器（防止继续写入错误数据）
# 3. 通知团队和负责人
# 4. 启动事故响应流程
```

#### 第二步：评估影响（5-15分钟）
```sql
-- 评估受影响的记录数
SELECT COUNT(*) FROM affected_table WHERE condition;

-- 查看最近的变更
-- 检查binlog/wal日志确定具体影响范围
```

#### 第三步：决策与执行（15-30分钟）

**选项A**: 从最近备份恢复
```bash
# 最快最可靠的方式
pg_restore -h host -U user -d database backup_file.sql
```

**选项B**: 执行回滚SQL
```bash
psql -h host -U user -d database -f rollback_script.sql
```

**选项C**: 手动修复数据（仅限小范围精确修复）
```sql
-- 仅当你完全理解问题时使用
UPDATE affected_table SET ... WHERE ...;
```

#### 第四步：验证与复盘（30分钟后）
- [ ] 验证数据完整性
- [ ] 验证应用功能正常
- [ ] 编写事故报告
- [ ] 复盘并改进流程

---

## 📞 何时寻求帮助

遇到以下情况时，不要犹豫，立即求助：

- ⚠️ 不确定SQL的影响范围
- ⚠️ 涉及生产环境的大规模数据操作
- ⚠️ 回滚失败或没有有效的回滚方案
- ⚠️ 出现数据丢失或损坏
- ⚠️ 性能问题影响用户体验超过阈值
- ⚠️ 任何你不确定的情况

**记住：宁可多问，不可蛮干！**

---

**文档版本**: v1.0
**最后更新**: 2026-05-04
**维护者**: DBA团队 / 技术委员会
