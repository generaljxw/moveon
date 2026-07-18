// lib/services/auth_service.dart — 用户认证服务
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'database_service.dart';

/// 认证异常 — 带用户可读的错误消息
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override String toString() => 'AuthException: $message';
}

/// 用户认证服务 — 注册、登录、修改密码
///
/// 所有方法为静态方法，接收 [DatabaseService] 实例以支持测试。
/// 密码使用 SHA-256 哈希存储，绝不明文保存。
class AuthService {
  /// SHA-256 密码哈希
  ///
  /// 对 [password] 执行 SHA-256 后返回 64 位十六进制字符串。
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ==========================================================
  // 注册
  // ==========================================================

  /// 注册新用户
  ///
  /// 校验规则：
  /// - 用户名 4-20 字符，仅 [a-zA-Z0-9_]
  /// - 密码 6-20 字符
  /// - 用户名不可重复
  ///
  /// 注册成功后返回 [User] 对象。
  static Future<User> register(DatabaseService db, String username, String password) async {
    _validateUsername(username);
    _validatePassword(password);

    final dbConn = await db.database;

    // 检查用户名是否已被占用
    final existing = await dbConn.query('users', where: 'username = ?', whereArgs: [username]);
    if (existing.isNotEmpty) {
      throw const AuthException('该用户名已被使用，请更换');
    }

    // 哈希密码后写入数据库
    final now = DateTime.now();
    final userId = await dbConn.insert('users', {
      'username': username,
      'password_hash': hashPassword(password),
      'created_at': now.toIso8601String(),
      'failed_attempts': 0,
    });

    return User(id: userId, username: username, passwordHash: hashPassword(password), createdAt: now);
  }

  // ==========================================================
  // 登录
  // ==========================================================

  /// 用户登录
  ///
  /// 锁定机制：
  /// - 连续 5 次密码错误 → 锁定该账号 15 分钟
  /// - 锁定期间即使用正确密码也无法登录
  /// - 登录成功后重置失败计数
  ///
  /// 安全提示：不区分"用户名不存在"和"密码错误"，
  /// 统一返回"用户名或密码错误"以防止用户枚举。
  static Future<User> login(DatabaseService db, String username, String password) async {
    final dbConn = await db.database;

    // 查找用户（不区分大小写，但 V1.0 暂不支持 — 保持精确匹配）
    final rows = await dbConn.query('users', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty) {
      throw const AuthException('用户名或密码错误');
    }

    final user = User.fromMap(rows.first);

    // 检查是否处于锁定状态
    if (user.lockedUntil != null && user.lockedUntil!.isAfter(DateTime.now())) {
      final minutes = user.lockedUntil!.difference(DateTime.now()).inMinutes + 1;
      throw AuthException('密码错误次数过多，请 $minutes 分钟后重试');
    }

    // 验证密码
    if (user.passwordHash != hashPassword(password)) {
      // 增加失败计数
      final newAttempts = user.failedAttempts + 1;
      final updates = <String, dynamic>{'failed_attempts': newAttempts};

      // 达到 5 次 → 锁定 15 分钟
      if (newAttempts >= 5) {
        updates['locked_until'] = DateTime.now().add(const Duration(minutes: 15)).toIso8601String();
      }

      await dbConn.update('users', updates, where: 'id = ?', whereArgs: [user.id]);
      throw const AuthException('用户名或密码错误');
    }

    // 登录成功 → 清除失败计数和锁定状态
    await dbConn.update('users', {
      'failed_attempts': 0,
      'locked_until': null,
    }, where: 'id = ?', whereArgs: [user.id]);

    return User(
      id: user.id,
      username: user.username,
      passwordHash: user.passwordHash,
      createdAt: user.createdAt,
      failedAttempts: 0,
    );
  }

  // ==========================================================
  // 修改密码
  // ==========================================================

  /// 修改密码
  ///
  /// [oldPassword] 必须与当前密码匹配。
  /// [newPassword] 需通过格式校验且不能与旧密码相同。
  static Future<void> changePassword(DatabaseService db, int userId, String oldPassword, String newPassword) async {
    final dbConn = await db.database;

    // 查找用户
    final rows = await dbConn.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isEmpty) throw const AuthException('用户不存在');

    final user = User.fromMap(rows.first);

    // 验证原密码
    if (user.passwordHash != hashPassword(oldPassword)) {
      throw const AuthException('原密码不正确');
    }

    // 验证新密码格式
    _validatePassword(newPassword);

    // 新密码不能与原密码相同
    if (hashPassword(newPassword) == user.passwordHash) {
      throw const AuthException('新密码不能与原密码相同');
    }

    // 更新密码
    await dbConn.update('users', {
      'password_hash': hashPassword(newPassword),
    }, where: 'id = ?', whereArgs: [userId]);
  }

  // ==========================================================
  // 私有校验方法
  // ==========================================================

  /// 校验用户名格式：4-20 字符，仅 [a-zA-Z0-9_]
  static void _validateUsername(String username) {
    if (username.length < 4 || username.length > 20) {
      throw const AuthException('用户名需为 4-20 位字符');
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(username)) {
      throw const AuthException('用户名仅支持字母、数字和下划线');
    }
  }

  /// 校验密码长度：6-20 字符
  static void _validatePassword(String password) {
    if (password.length < 6 || password.length > 20) {
      throw const AuthException('密码长度为 6-20 位');
    }
  }
}
