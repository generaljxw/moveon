// lib/models/user.dart — 用户数据模型
import 'package:shared_preferences/shared_preferences.dart';

/// 用户数据模型 — 对应 SQLite users 表
///
/// 密码通过 SHA-256 哈希后存入 [passwordHash]，绝不明文存储。
/// [lockedUntil] 记录登录锁定到期时间（null = 未锁定）。
/// [failedAttempts] 记录当前连续登录失败次数。
class User {
  /// 自增主键（新建用户时为 null，由数据库自动分配）
  final int? id;

  /// 用户名 — 4-20 字符，仅允许字母、数字、下划线
  final String username;

  /// SHA-256 哈希后的密码，绝不明文存储
  final String passwordHash;

  /// 账号创建时间
  final DateTime createdAt;

  /// 登录锁定到期时间（ISO 8601）；null 表示未被锁定
  final DateTime? lockedUntil;

  /// 当前连续登录失败次数（成功后重置为 0）
  final int failedAttempts;

  const User({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.createdAt,
    this.lockedUntil,
    this.failedAttempts = 0, // 新用户失败计数从 0 开始
  });

  /// 从数据库查询结果构造 User
  ///
  /// [map] 的键对应 SQLite 列名：
  /// - id, username, password_hash, created_at
  /// - locked_until (可为 null)
  /// - failed_attempts (可为 null，默认为 0)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      // locked_until: null 表示未锁定
      lockedUntil: map['locked_until'] != null
          ? DateTime.parse(map['locked_until'] as String)
          : null,
      // failed_attempts: 兼容旧数据中可能为 null 的情况
      failedAttempts: map['failed_attempts'] as int? ?? 0,
    );
  }

  /// 序列化为 SQLite 可存储的 Map
  ///
  /// id 为 null 时不包含，让 SQLite 自动生成自增主键。
  /// locked_until 为 null 时不包含，保持数据库列也为 NULL。
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'username': username,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
      'failed_attempts': failedAttempts,
    };
    // INSERT 不需要 id，UPDATE 需要
    if (id != null) {
      map['id'] = id;
    }
    // locked_until 为 null 时存储 SQL NULL
    if (lockedUntil != null) {
      map['locked_until'] = lockedUntil!.toIso8601String();
    }
    return map;
  }
}
