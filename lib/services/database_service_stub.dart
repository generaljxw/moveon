// lib/services/database_service_stub.dart — sqflite 跨平台条件导出 + 引擎初始化
//
// Windows：sqflite_common_ffi（FFI 绑定 sqlite3.dll）
// Android：sqflite_common_ffi（FFI 绑定系统 SQLite，双平台均支持 dart:ffi）
//
// sqflite_common_ffi 的 databaseFactory 是跨平台 API：
// - Windows：通过 FFI 调用 sqlite3.dll
// - Android：通过 FFI 调用系统 libsqlite

/// 重新导出 sqflite 核心 API（databaseFactory、Database、openDatabase 等）
///
/// 两个平台均支持 dart:ffi，sqflite_common_ffi 在双平台均可用。
/// 后续如需按平台选择不同实现，可在此添加条件导出：
/// ```dart
/// export 'package:sqflite/sqflite.dart'
///     if (dart.library.io) 'package:sqflite_common_ffi/sqflite_ffi.dart';
/// ```
// 导出 sqflite API（databaseFactory、Database、openDatabase、sqfliteFfiInit 等）
export 'package:sqflite_common_ffi/sqflite_ffi.dart';
// 导入以供本文件内部使用（sqfliteFfiInit 在 initDatabaseEngine 中被调用）
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'dart:io' show Platform;

/// 初始化数据库引擎（跨平台适配）
///
/// Windows：调用 [sqfliteFfiInit()] 加载 sqlite3.dll
/// 双平台：必须将 [databaseFactoryFfi] 注册为全局 factory，
/// 否则 [databaseFactory] 会抛出 "databaseFactory not initialized"。
Future<void> initDatabaseEngine() async {
  if (Platform.isWindows) {
    // Windows 桌面：需要显式加载 sqlite3.dll
    sqfliteFfiInit();
  }
  // 关键：sqflite_common_ffi 在双平台都需要注册 FFI 工厂
  // 否则 databaseFactory getter 会抛出 Bad state 异常
  databaseFactory = databaseFactoryFfi;
}
