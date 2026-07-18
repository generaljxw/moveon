// lib/services/database_service.dart — SQLite 数据库服务
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// SQLite 数据库服务 — 管理连接和表创建
///
/// 生产代码通过 [DatabaseService.instance] 获取单例。
/// 测试可创建独立实例使用内存数据库。
/// 生产模式使用文件数据库存储在应用数据目录。
class DatabaseService {
  /// 全局单例（供生产代码使用）
  static final DatabaseService instance = DatabaseService();

  DatabaseService();

  Database? _db;

  /// 获取数据库连接（需先调用 [initialize]）
  Future<Database> get database async {
    if (_db != null) return _db!;
    throw StateError('DatabaseService 未初始化，请先调用 initialize()');
  }

  /// 初始化数据库并创建表结构
  ///
  /// [inMemory] = true：使用内存数据库（仅测试用）— 数据进程结束即丢弃
  /// [inMemory] = false：文件数据库存放在应用数据目录下 moveon.db
  Future<void> initialize({bool inMemory = false}) async {
    // 幂等性：已初始化则跳过
    if (_db != null) return;

    if (inMemory) {
      // 使用带时间戳的唯一路径确保每个测试实例完全独立
      final testPath = 'file:test_${DateTime.now().microsecondsSinceEpoch}.db?mode=memory&cache=shared';
      _db = await databaseFactoryFfi.openDatabase(
        testPath,
        options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
      );
      return;
    }

    // 生产模式：文件存储
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'moveon.db');
    _db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 1, onCreate: _onCreate),
    );
  }

  /// 建表回调 — version=1 时执行
  ///
  /// 三张表：users, exercise_modules, exercise_actions
  /// 外键约束启用 ON DELETE CASCADE
  Future<void> _onCreate(Database db, int version) async {
    // 开启外键约束支持
    await db.execute('PRAGMA foreign_keys = ON');

    // ---- users: 用户表 ----
    // username 设为 UNIQUE 防止重复注册
    // locked_until: NULL=未锁定, 非NULL=锁定到期时间(ISO 8601)
    // failed_attempts: 连续登录失败次数（成功后归零）
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL,
        locked_until TEXT,
        failed_attempts INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ---- exercise_modules: 练习模组表 ----
    // 外键 ON DELETE CASCADE：删除用户时自动删除其模组
    await db.execute('''
      CREATE TABLE exercise_modules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // ---- exercise_actions: 动作表 ----
    // is_rest: INTEGER 0=动作 1=休息
    // sort_order: 动作在模组中的执行顺序
    await db.execute('''
      CREATE TABLE exercise_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        module_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        is_rest INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (module_id) REFERENCES exercise_modules(id) ON DELETE CASCADE
      )
    ''');
  }
}
