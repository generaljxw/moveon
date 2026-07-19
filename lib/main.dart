// lib/main.dart — MoveOn 应用入口
//
/// 启动流程：
/// 1. 初始化数据库引擎（跨平台适配：Windows FFI / Android 原生）
/// 2. 注册 Windows 视频播放器插件（非 Windows 无操作）
/// 3. 初始化本地数据库
/// 4. 启动 Flutter 应用（Provider 层自动恢复登录状态）
import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/video_player_init.dart';
import 'app.dart';

void main() async {
  // Flutter 绑定必须在异步操作前初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 sqflite FFI 引擎（内部自动判断平台：Windows 加载 sqlite3.dll，Android 跳过）
  await initDatabaseEngine();

  // 注册 video_player_win 插件（内部自动判断平台，非 Windows 无操作）
  registerVideoPlayer();

  // 初始化本地数据库（生产模式，文件存储）
  // databaseFactory 由 database_service_stub.dart 条件导出自动选择正确实现
  await DatabaseService.instance.initialize();

  runApp(const MoveOnApp());
}
