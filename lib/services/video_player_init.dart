// lib/services/video_player_init.dart — 视频播放器平台初始化
//
// 将 video_player_win 的导入隔离到独立文件中，避免 main.dart 直接依赖
// Windows 平台特有的插件包。
//
// 安全说明：
// - video_player_win 的 Dart 代码仅使用 dart:io 和 dart:async
//   （Android 平台也支持），因此顶层导入是安全的。
// - 原生插件注册 (.registerWith()) 仅在 Windows 平台执行。
// - .flutter-plugins-dependencies 中 video_player_win 仅注册到
//   windows 平台，不影响 Android 构建。
import 'dart:io' show Platform;

import 'package:video_player_win/video_player_win_plugin.dart';

/// 注册 Windows 视频播放器插件。
///
/// 仅当运行在 Windows 平台时执行 native 插件注册；
/// Android 等其他平台调用此函数无任何副作用。
void registerVideoPlayer() {
  if (Platform.isWindows) {
    // 注册 video_player_win 插件（提供 Windows 平台的视频播放能力）
    WindowsVideoPlayer.registerWith();
  }
}
