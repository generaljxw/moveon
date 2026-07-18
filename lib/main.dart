// lib/main.dart — MoveOn 应用入口
///
/// 启动流程：
/// 1. 初始化 sqflite FFI（Windows 桌面必需）
/// 2. 初始化本地数据库
/// 3. 启动 Flutter 应用（Provider 层自动恢复登录状态）
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:video_player_win/video_player_win_plugin.dart';
import 'services/database_service.dart';
import 'app.dart';

void main() async {
  // Flutter 绑定必须在异步操作前初始化
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 桌面：初始化 sqflite FFI 后端
  sqfliteFfiInit();

  // Windows 桌面：注册 video_player_win 插件（提供 VideoPlayerController 的 Windows 实现）
  WindowsVideoPlayer.registerWith();

  // 初始化本地数据库（生产模式，文件存储）
  await DatabaseService.instance.initialize();

  runApp(const MoveOnApp());
}
