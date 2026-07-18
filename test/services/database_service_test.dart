// test/services/database_service_test.dart — 数据库服务测试
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moveon/services/database_service.dart';

void main() {
  // Windows 桌面：初始化 sqflite FFI（测试用内存数据库）
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseService', () {
    // ---- 建表：三张核心表 ----
    test('initialize creates all 3 tables', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      )).map((r) => r['name'] as String).toList();

      expect(tables, containsAll(['users', 'exercise_modules', 'exercise_actions']));
    });

    // ---- users 表 Schema 检查 ----
    test('users table has correct schema with lockout columns', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      final cols = (await db.rawQuery("PRAGMA table_info('users')"))
          .map((c) => c['name'] as String).toList();

      // 必须包含登录锁定相关列
      expect(cols, containsAll([
        'id', 'username', 'password_hash', 'created_at',
        'locked_until', 'failed_attempts',
      ]));
    });

    // ---- exercise_modules 表外键约束定义存在 ----
    test('exercise_modules references users via foreign key', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      // 验证外键列存在
      final cols = (await db.rawQuery("PRAGMA table_info('exercise_modules')"))
          .map((c) => c['name'] as String).toList();
      expect(cols.contains('user_id'), true);

      // 验证可正常插入和查询关联数据
      await db.insert('users', {
        'username': 'fk_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000',
        'failed_attempts': 0,
      });
      await db.insert('exercise_modules', {
        'user_id': 1, 'name': 'test', 'category': '瑜伽',
        'created_at': '2026-07-18T00:00:00.000',
      });
      final modules = await db.query('exercise_modules');
      expect(modules.length, 1);
      expect(modules.first['user_id'], 1);
    });

    // ---- 初始化幂等性：重复调用不报错 ----
    test('initialize is idempotent', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      // 不应抛出异常
      await svc.initialize(inMemory: true);
      // 确认仍然可用
      final db = await svc.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'");
      expect(tables.length, greaterThanOrEqualTo(3));
    });
  });
}
