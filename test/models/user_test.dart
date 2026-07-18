// test/models/user_test.dart — User 模型单元测试
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/models/user.dart';

void main() {
  // ============================================================
  // User 模型测试：验证数据序列化/反序列化正确性
  // ============================================================

  group('User model', () {
    // ---- fromMap 测试：从数据库行构造 User ----
    test('fromMap creates User from database row', () {
      final map = {
        'id': 1,
        'username': 'testuser',
        'password_hash': 'abc123hash',
        'created_at': '2026-07-17T10:00:00.000',
        'locked_until': null,         // null = 未锁定
        'failed_attempts': 0,          // 默认 0
      };
      final user = User.fromMap(map);
      expect(user.id, 1);
      expect(user.username, 'testuser');
      expect(user.passwordHash, 'abc123hash');
      expect(user.createdAt, DateTime(2026, 7, 17, 10, 0, 0));
      expect(user.lockedUntil, isNull);       // 未锁定状态
      expect(user.failedAttempts, 0);          // 初始失败计数
    });

    // ---- locked_until 非 null 时的解析 ----
    test('fromMap parses locked_until when set', () {
      final map = {
        'id': 2,
        'username': 'locked_user',
        'password_hash': 'hash2',
        'created_at': '2026-07-17T08:00:00.000',
        'locked_until': '2026-07-17T08:15:00.000', // 锁定 15 分钟
        'failed_attempts': 5,
      };
      final user = User.fromMap(map);
      expect(user.lockedUntil, DateTime(2026, 7, 17, 8, 15, 0));
      expect(user.failedAttempts, 5);             // 触发锁定的标记
    });

    // ---- toMap 测试：新用户 INSERT 不含 id ----
    test('toMap excludes id when null (new user for INSERT)', () {
      final user = User(
        username: 'newuser',
        passwordHash: 'hashed_pw',
        createdAt: DateTime(2026, 7, 17),
      );
      final map = user.toMap();
      // 新用户未分配 id，不应包含在 INSERT 语句中
      expect(map.containsKey('id'), false);
      expect(map['username'], 'newuser');
      expect(map['password_hash'], 'hashed_pw');
    });

    // ---- toMap 测试：已有用户 UPDATE 含 id ----
    test('toMap includes id when set (existing user UPDATE)', () {
      final user = User(
        id: 42,
        username: 'existing',
        passwordHash: 'hash3',
        createdAt: DateTime(2026, 7, 17),
      );
      final map = user.toMap();
      expect(map['id'], 42); // UPDATE 需要 id 定位行
    });

    // ---- toMap 序列化 locked_until ----
    test('toMap serializes lockedUntil as ISO 8601 string', () {
      final user = User(
        username: 'temp_locked',
        passwordHash: 'h',
        createdAt: DateTime(2026, 7, 17),
        lockedUntil: DateTime(2026, 7, 17, 12, 0, 0),
        failedAttempts: 3,
      );
      final map = user.toMap();
      expect(map['locked_until'], '2026-07-17T12:00:00.000');
      expect(map['failed_attempts'], 3);
    });
  });
}
