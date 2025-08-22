-- 测试数据库连接和权限
USE aquaguardian;

-- 检查表是否存在
SHOW TABLES;

-- 检查水情表结构
DESCRIBE water_situation;

-- 检查数据
SELECT COUNT(*) as total_records FROM water_situation;

-- 检查用户权限
SHOW GRANTS FOR 'root'@'localhost';

-- 测试查询
SELECT reservoir_name, water_level, storage FROM water_situation LIMIT 3; 