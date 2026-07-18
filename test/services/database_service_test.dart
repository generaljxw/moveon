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
    // ---- 建表：四张核心表 ----
    test('initialize creates all 4 tables', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      )).map((r) => r['name'] as String).toList();

      expect(tables, containsAll(['users', 'exercise_modules', 'exercise_actions', 'online_videos']));
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
      expect(tables.length, greaterThanOrEqualTo(4));
    });

    // ---- online_videos 表创建 ----
    test('initialize creates online_videos table', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      )).map((r) => r['name'] as String).toList();

      expect(tables, contains('online_videos'));
    });

    // ---- online_videos 表 Schema 检查 ----
    test('online_videos table has correct columns', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      final cols = (await db.rawQuery("PRAGMA table_info('online_videos')"))
          .map((c) => c['name'] as String).toList();

      expect(cols, containsAll([
        'id', 'user_id', 'category', 'title',
        'url', 'video_type', 'created_at',
      ]));
    });

    // ---- online_videos 外键关联验证 ----
    test('online_videos references users via foreign key', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      // 验证外键列存在
      final cols = (await db.rawQuery("PRAGMA table_info('online_videos')"))
          .map((c) => c['name'] as String).toList();
      expect(cols.contains('user_id'), true);

      // 验证可正常插入和查询关联数据
      await db.insert('users', {
        'username': 'fk_video_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });
      await db.insert('online_videos', {
        'user_id': 1, 'category': '瑜伽', 'title': '测试视频',
        'url': 'https://example.com/v.mp4', 'video_type': 'direct',
        'created_at': '2026-07-18T00:00:00.000',
      });
      final videos = await db.query('online_videos');
      expect(videos.length, 1);
      expect(videos.first['user_id'], 1);
    });

    // ---- online_videos 允许不同用户添加相同 URL ----
    test('online_videos allows same URL for different users', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      // 创建两个用户
      await db.insert('users', {
        'username': 'user_a', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });
      await db.insert('users', {
        'username': 'user_b', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      // 两个用户添加相同 URL
      await db.insert('online_videos', {
        'user_id': 1, 'category': '瑜伽', 'title': 'A的视频',
        'url': 'https://same-url.com/v.mp4', 'video_type': 'direct',
        'created_at': '2026-07-18T00:00:00.000',
      });
      await db.insert('online_videos', {
        'user_id': 2, 'category': '瑜伽', 'title': 'B的视频',
        'url': 'https://same-url.com/v.mp4', 'video_type': 'direct',
        'created_at': '2026-07-18T00:00:00.000',
      });
      final all = await db.query('online_videos');
      expect(all.length, 2);
    });
  });
}
