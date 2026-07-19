// lib/main.dart — MoveOn 应用入口
//
/// 启动流程：
/// 1. 初始化数据库引擎（跨平台适配：Windows FFI / Android 原生）
/// 2. 初始化本地数据库
/// 3. 启动 Flutter 应用（Provider 层自动恢复登录状态）
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player_win/video_player_win_plugin.dart';
import 'services/database_service.dart';
import 'app.dart';

void main() async {
  // Flutter 绑定必须在异步操作前初始化
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 桌面：初始化 sqflite FFI 后端 + 注册 video_player_win 插件
  if (Platform.isWindows) {
    // 初始化 sqflite FFI 引擎（加载 sqlite3.dll）
    await initDatabaseEngine();

    // 注册 video_player_win 插件（提供 Windows 平台的视频播放能力）
    WindowsVideoPlayer.registerWith();
  }

  // Android：无需额外的引擎初始化，sqflite_common_ffi 通过 FFI 自动绑定系统 SQLite

  // 初始化本地数据库（生产模式，文件存储）
  // databaseFactory 由 database_service_stub.dart 条件导出自动选择正确实现
  await DatabaseService.instance.initialize();

  runApp(const MoveOnApp());
}
