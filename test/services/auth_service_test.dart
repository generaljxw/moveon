// test/services/auth_service_test.dart — 认证服务测试
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moveon/services/database_service.dart';
import 'package:moveon/services/auth_service.dart';

void main() {
  setUpAll(() { sqfliteFfiInit(); databaseFactory = databaseFactoryFfi; });

  late DatabaseService db;
  setUp(() async {
    db = DatabaseService();
    await db.initialize(inMemory: true);
  });

  // ============================================================
  // hashPassword 测试
  // ============================================================
  group('hashPassword', () {
    test('produces 64-char SHA-256 hex string', () {
      final hash = AuthService.hashPassword('mypassword');
      expect(hash.length, 64); // SHA-256 → 64 hex chars
    });

    test('same input produces same hash (deterministic)', () {
      expect(AuthService.hashPassword('same'), AuthService.hashPassword('same'));
    });

    test('different inputs produce different hashes', () {
      expect(AuthService.hashPassword('a'), isNot(AuthService.hashPassword('b')));
    });
  });

  // ============================================================
  // register 测试
  // ============================================================
  group('register', () {
    test('creates user with hashed password', () async {
      final user = await AuthService.register(db, 'player1', 'pass123');
      expect(user.username, 'player1');
      expect(user.passwordHash, isNot('pass123')); // 非明文
      expect(user.passwordHash.length, 64);        // SHA-256
    });

    test('rejects duplicate username', () async {
      await AuthService.register(db, 'duplicate', 'pass12');
      await expectLater(
        () => AuthService.register(db, 'duplicate', 'pass22'),
        throwsA(predicate((e) => e is AuthException && e.message.contains('已被使用'))),
      );
    });

    test('rejects username < 4 chars', () async {
      await expectLater(
        () => AuthService.register(db, 'ab', '123456'),
        throwsA(isA<AuthException>()),
      );
    });

    test('rejects username > 20 chars', () async {
      await expectLater(
        () => AuthService.register(db, 'a' * 21, '123456'),
        throwsA(isA<AuthException>()),
      );
    });

    test('rejects username with special chars', () async {
      await expectLater(
        () => AuthService.register(db, 'bad!name', '123456'),
        throwsA(isA<AuthException>()),
      );
    });

    test('rejects password < 6 chars', () async {
      await expectLater(
        () => AuthService.register(db, 'valid_user', '12345'),
        throwsA(isA<AuthException>()),
      );
    });

    test('rejects password > 20 chars', () async {
      await expectLater(
        () => AuthService.register(db, 'valid_user', '1' * 21),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // ============================================================
  // login 测试
  // ============================================================
  group('login', () {
    setUp(() async {
      await AuthService.register(db, 'tester', 'correct');
    });

    test('login succeeds with correct credentials', () async {
      final user = await AuthService.login(db, 'tester', 'correct');
      expect(user.username, 'tester');
      expect(user.failedAttempts, 0); // 成功后重置
    });

    test('login fails with wrong password (generic message)', () async {
      await expectLater(
        () => AuthService.login(db, 'tester', 'wrong'),
        throwsA(predicate((e) =>
            e is AuthException && e.message == '用户名或密码错误')),
      );
    });

    test('login fails for non-existent user (same error to prevent enumeration)', () async {
      await expectLater(
        () => AuthService.login(db, 'nobody', 'x'),
        throwsA(predicate((e) =>
            e is AuthException && e.message == '用户名或密码错误')),
      );
    });

    test('locks account after 5 consecutive failures', () async {
      // 连续 5 次失败
      for (int i = 0; i < 5; i++) {
        try { await AuthService.login(db, 'tester', 'wrong'); } catch (_) {}
      }
      // 第 6 次即使用正确密码也应提示锁定
      await expectLater(
        () => AuthService.login(db, 'tester', 'correct'),
        throwsA(predicate((e) =>
            e is AuthException && e.message.contains('15 分钟'))),
      );
    });

    test('successful login resets failedAttempts to 0', () async {
      // 先失败 2 次
      try { await AuthService.login(db, 'tester', 'wrong'); } catch (_) {}
      try { await AuthService.login(db, 'tester', 'wrong'); } catch (_) {}
      // 成功后清零
      await AuthService.login(db, 'tester', 'correct');
      final dbConn = await db.database;
      final rows = await dbConn.query('users', where: 'username = ?', whereArgs: ['tester']);
      expect(rows.first['failed_attempts'], 0);
    });
  });

  // ============================================================
  // changePassword 测试
  // ============================================================
  group('changePassword', () {
    late int userId;
    setUp(() async {
      final user = await AuthService.register(db, 'pw_user', 'oldpass');
      userId = user.id!;
    });

    test('changes password when old password is correct', () async {
      await AuthService.changePassword(db, userId, 'oldpass', 'newpass');
      // 用新密码可登录
      final user = await AuthService.login(db, 'pw_user', 'newpass');
      expect(user.username, 'pw_user');
    });

    test('rejects when old password is incorrect', () async {
      await expectLater(
        () => AuthService.changePassword(db, userId, 'wrong', 'newpass'),
        throwsA(predicate((e) => e is AuthException && e.message.contains('原密码不正确'))),
      );
    });

    test('rejects when new password same as old', () async {
      await expectLater(
        () => AuthService.changePassword(db, userId, 'oldpass', 'oldpass'),
        throwsA(predicate((e) => e is AuthException && e.message.contains('不能与原密码相同'))),
      );
    });

    test('rejects new password < 6 chars', () async {
      await expectLater(
        () => AuthService.changePassword(db, userId, 'oldpass', '12345'),
        throwsA(isA<AuthException>()),
      );
    });
  });
}
