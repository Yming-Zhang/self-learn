精通 SQL，不是记住多少语法，而是能把业务问题写成正确、可靠、性能可控的查询，并解释为什么这样写。

可以按这 6 个维度判断：

维度	达到“精通”的表现
查询能力	熟练使用 JOIN、子查询、CTE、窗口函数，能处理排名、去重、连续区间、累计值、同比环比等问题
正确性	清楚 NULL、重复行、一对多关联、时间边界的影响；能避免金额重复统计、漏数据等隐蔽错误
数据建模	能合理设计主键、唯一约束、外键和字段类型，理解范式与反范式的取舍
性能优化	能读执行计划，理解索引、扫描方式、连接方式、排序和统计信息；通过实测验证优化效果
事务与并发	理解隔离级别、锁、死锁和 MVCC，能处理并发更新、幂等写入，以及事务失败后的恢复
工程实践	大批量修改有分批、校验与恢复方案；分页、迁移、DDL 操作能评估对线上服务的影响

先练手写：多表关联、聚合、条件聚合、子查询、窗口函数，重点练上面那些业务场景。
再练优化：拿具体 SQL 分析执行计划，解释联合索引和排序、分页的关系。
最后串业务：把下单扣库存、支付幂等、事务回滚、死锁讲完整。


建议以 MySQL 8.0 为基准，重点练查询、数据修改和常见语法陷阱。

一、先把 SQL 分成 5 类
分类	作用	常见语句	复习优先级
DQL：数据查询	查数据、统计分析	SELECT、JOIN、子查询、窗口函数	最高
DML：数据操作	新增、修改、删除记录	INSERT、UPDATE、DELETE	高
DDL：结构定义	管理表、字段、索引	CREATE、ALTER、DROP、TRUNCATE	高
TCL：事务控制	提交、回滚、保存点	START TRANSACTION、COMMIT、ROLLBACK、SAVEPOINT	中
DCL：权限控制	授权、撤销权限	GRANT、REVOKE	低
这是常见教学分类；有些资料把查询归入 DML，不必纠结分类名称。

二、查询语法要拆成这些模块
模块	要记住的语法	常见考法或陷阱
条件过滤	WHERE、IN、BETWEEN、LIKE	BETWEEN 两端都包含；AND 优先于 OR
空值处理	IS NULL、IS NOT NULL、COALESCE	不能用 = NULL；NOT IN 遇到 NULL 容易出错
去重排序	DISTINCT、ORDER BY、LIMIT	分页排序要有唯一的兜底字段
多表关联	INNER JOIN、LEFT JOIN ... ON	右表条件放进 WHERE，可能丢掉左表未匹配记录
分组统计	GROUP BY、HAVING、聚合函数	WHERE 过滤明细，HAVING 过滤分组
子查询	标量子查询、IN、EXISTS、NOT EXISTS	查“存在/不存在”、高于平均值
条件表达式	CASE WHEN ... THEN ... ELSE ... END	条件统计、状态转换、行转列
窗口函数	OVER(PARTITION BY ... ORDER BY ...)	每组前 N、排名、累计值、环比
结果集组合	UNION、UNION ALL	前者去重，后者保留重复
公共表表达式	WITH ... AS (...)	拆解复杂查询；MySQL 8.0 支持
记住简化的逻辑处理顺序：FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT。因此，WHERE 不能直接使用同层 SELECT 定义的别名。

三、用同一组表练典型题
假设有用户表 users(id, name)，订单表 orders(id, user_id, amount, status, created_at)；status = 'PAID' 表示已支付。

例 1：统计 2026 年 10 月消费超过 1000 元的用户，按消费额排序。

SELECT user_id, COUNT(*) AS order_count, SUM(amount) AS total_amount
FROM orders
WHERE status = 'PAID'
  AND created_at >= '2026-10-01' AND created_at < '2026-11-01'
GROUP BY user_id
HAVING SUM(amount) > 1000
ORDER BY total_amount DESC, user_id ASC
LIMIT 10;
考点：分组、聚合、HAVING、排序；时间用左闭右开区间，不会漏掉月底带时分秒的数据。

例 2：查询从未有过已支付订单的用户。

SELECT users.id, users.name
FROM users
WHERE NOT EXISTS (
    SELECT 1 FROM orders
    WHERE orders.user_id = users.id AND orders.status = 'PAID'
);
考点：关联子查询、反向查找。也可以用 LEFT JOIN ... WHERE orders.id IS NULL；此时支付状态条件应写在 ON 中。

例 3：查询每个用户金额最高的两笔已支付订单。

WITH ranked_orders AS (
    SELECT id, user_id, amount,
           ROW_NUMBER() OVER (
               PARTITION BY user_id ORDER BY amount DESC, id DESC
           ) AS position
    FROM orders WHERE status = 'PAID'
)
SELECT id, user_id, amount FROM ranked_orders
WHERE position <= 2
ORDER BY user_id, position;
考点：分组 Top N。ROW_NUMBER 连续编号；RANK 并列且跳号；DENSE_RANK 并列不跳号。“两笔订单”和“前两档金额”要用不同函数。

例 4：只允许待支付订单变成已支付，避免覆盖其他状态。

UPDATE orders SET status = 'PAID'
WHERE id = 1001 AND status = 'PENDING';
考点：条件更新，并检查影响行数。这不是完整支付方案，也不能单凭影响行数为 0 就断言订单不存在。

四、剩下这些细节务必过一遍
DDL：练熟 CREATE TABLE，以及 ALTER TABLE ... ADD COLUMN / MODIFY COLUMN / DROP COLUMN / ADD INDEX 你现在适合补的是 “把思路翻译成 SQL 的手感”，不必重新啃数据库理论。对 5 年 Java 开发的面试，建议以 MySQL 8.0 为基准，重点练查询、数据修改和常见语法陷阱。
一、先把 SQL 分成 5 类
分类	作用	常见语句	复习优先级
DQL：数据查询	查数据、统计分析	SELECT、JOIN、子查询、窗口函数	最高
DML：数据操作	新增、修改、删除记录	INSERT、UPDATE、DELETE	高
DDL：结构定义	管理表、字段、索引	CREATE、ALTER、DROP、TRUNCATE	高
TCL：事务控制	提交、回滚、保存点	START TRANSACTION、COMMIT、ROLLBACK、SAVEPOINT	中
DCL：权限控制	授权、撤销权限	GRANT、REVOKE	低
这是常见教学分类；有些资料把查询归入 DML，不必纠结分类名称。

二、查询语法要拆成这些模块
模块	要记住的语法	常见考法或陷阱
条件过滤	WHERE、IN、BETWEEN、LIKE	BETWEEN 两端都包含；AND 优先于 OR
空值处理	IS NULL、IS NOT NULL、COALESCE	不能用 = NULL；NOT IN 遇到 NULL 容易出错
去重排序	DISTINCT、ORDER BY、LIMIT	分页排序要有唯一的兜底字段
多表关联	INNER JOIN、LEFT JOIN ... ON	右表条件放进 WHERE，可能丢掉左表未匹配记录
分组统计	GROUP BY、HAVING、聚合函数	WHERE 过滤明细，HAVING 过滤分组
子查询	标量子查询、IN、EXISTS、NOT EXISTS	查“存在/不存在”、高于平均值
条件表达式	CASE WHEN ... THEN ... ELSE ... END	条件统计、状态转换、行转列
窗口函数	OVER(PARTITION BY ... ORDER BY ...)	每组前 N、排名、累计值、环比
结果集组合	UNION、UNION ALL	前者去重，后者保留重复
公共表表达式	WITH ... AS (...)	拆解复杂查询；MySQL 8.0 支持
记住简化的逻辑处理顺序：FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → DISTINCT → ORDER BY → LIMIT。因此，WHERE 不能直接使用同层 SELECT 定义的别名。

三、用同一组表练典型题
假设有用户表 users(id, name)，订单表 orders(id, user_id, amount, status, created_at)；status = 'PAID' 表示已支付。

例 1：统计 2026 年 10 月消费超过 1000 元的用户，按消费额排序。

SELECT user_id, COUNT(*) AS order_count, SUM(amount) AS total_amount
FROM orders
WHERE status = 'PAID'
  AND created_at >= '2026-10-01' AND created_at < '2026-11-01'
GROUP BY user_id
HAVING SUM(amount) > 1000
ORDER BY total_amount DESC, user_id ASC
LIMIT 10;
考点：分组、聚合、HAVING、排序；时间用左闭右开区间，不会漏掉月底带时分秒的数据。

例 2：查询从未有过已支付订单的用户。

SELECT users.id, users.name
FROM users
WHERE NOT EXISTS (
    SELECT 1 FROM orders
    WHERE orders.user_id = users.id AND orders.status = 'PAID'
);
考点：关联子查询、反向查找。也可以用 LEFT JOIN ... WHERE orders.id IS NULL；此时支付状态条件应写在 ON 中。

例 3：查询每个用户金额最高的两笔已支付订单。

WITH ranked_orders AS (
    SELECT id, user_id, amount,
           ROW_NUMBER() OVER (
               PARTITION BY user_id ORDER BY amount DESC, id DESC
           ) AS position
    FROM orders WHERE status = 'PAID'
)
SELECT id, user_id, amount FROM ranked_orders
WHERE position <= 2
ORDER BY user_id, position;
考点：分组 Top N。ROW_NUMBER 连续编号；RANK 并列且跳号；DENSE_RANK 并列不跳号。“两笔订单”和“前两档金额”要用不同函数。

例 4：只允许待支付订单变成已支付，避免覆盖其他状态。

UPDATE orders SET status = 'PAID'
WHERE id = 1001 AND status = 'PENDING';
考点：条件更新，并检查影响行数。这不是完整支付方案，也不能单凭影响行数为 0 就断言订单不存在。

四、剩下这些细节务必过一遍
DDL：练熟 CREATE TABLE，以及 ALTER TABLE ... ADD COLUMN / MODIFY COLUMN / DROP COLUMN / ADD INDEX；区分 DELETE、TRUNCATE、DROP。MySQL 中很多 DDL 会隐式提交，不能照搬 DML 的回滚经验。
新增与更新：会写批量 INSERT ... VALUES (...), (...)、INSERT ... SELECT、UPDATE ... JOIN；知道 ON DUPLICATE KEY UPDATE 由主键或唯一键冲突触发。
统计陷阱：COUNT(*) 数行，COUNT(column) 忽略 NULL；外连接统计订单数通常用 COUNT(orders.id)。
事务与锁：会写 START TRANSACTION ... COMMIT/ROLLBACK、SELECT ... FOR UPDATE；理解锁定读需要结合事务使用。
分页与执行计划：会写 LIMIT 20 OFFSET 40，以及基于上一页排序键的游标分页；会执行 EXPLAIN SELECT ...。
突击顺序：单表查询 → JOIN → 分组统计 → EXISTS → 每组 Top N → DML/DDL → 事务。每类闭卷手写两题，比只看答案更能补上你现在缺的语法记忆。