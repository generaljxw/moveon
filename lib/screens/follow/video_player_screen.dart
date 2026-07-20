// lib/screens/follow/video_player_screen.dart — 视频播放器（内置本地 + 在线直链 + 浏览器跳转）
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/category_service.dart';
import '../../models/online_video.dart';
import '../../utils/responsive_helper.dart';

/// 全屏视频播放器 — 支持三种视频来源
///
/// - 内置视频（[video] 非 null）：通过 file:// 路径加载本地 mp4 文件播放
/// - 在线直链（[onlineVideo].videoType = 'direct'）：VideoPlayerController.network 流播放
/// - 在线链接（[onlineVideo].videoType = 'link'）：弹出确认后调用系统浏览器打开
///
/// [video] 和 [onlineVideo] 二选一传入（恰好一个非 null）。
class VideoPlayerScreen extends StatefulWidget {
  /// 内置视频信息（本地文件播放）
  final VideoInfo? video;

  /// 在线视频信息（网络直链或浏览器链接）
  final OnlineVideo? onlineVideo;

  const VideoPlayerScreen({super.key, this.video, this.onlineVideo});

  @override State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _openingBrowser = false; // 正在等待浏览器打开

  @override void initState() {
    super.initState();
    // 延迟到首帧构建完成后执行，确保 showDialog 的 Overlay 已就绪
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initPlayer();
    });
  }

  /// 根据视频类型初始化对应的播放方式
  Future<void> _initPlayer() async {
    // 平台链接 → 弹出确认后系统浏览器打开（无需 VideoPlayerController）
    if (widget.onlineVideo != null && widget.onlineVideo!.videoType == 'link') {
      _openInBrowser();
      return;
    }

    try {
      if (widget.onlineVideo != null) {
        // 在线直链 → 网络流播放
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.onlineVideo!.url));
      } else if (widget.video != null) {
        // 内置视频 → 跨平台播放
        // Windows：通过 file:// 路径直接访问解压后的文件
        // Android/iOS：先从 APK 内 assets 提取到缓存目录，再文件播放
        //   VideoPlayerController.asset() 对大文件（22MB）不稳定，故改用提取方案
        if (Platform.isWindows) {
          final exeDir = File(Platform.resolvedExecutable).parent.path;
          final filePath = '$exeDir/data/flutter_assets/${widget.video!.assetPath}';
          _controller = VideoPlayerController.file(File(filePath));
        } else {
          _controller = await _extractAssetAndPlay(widget.video!.assetPath);
        }
      } else {
        setState(() => _hasError = true);
        return;
      }

      await _controller!.initialize();
      await _controller!.play();
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  /// 从 APK 内 assets 提取视频到缓存目录，返回文件播放控制器
  ///
  /// VideoPlayerController.asset() 对大文件（22MB mp4）在 release 模式下不够稳定，
  /// 因此先将资源提取为独立文件再用 file() 播放。已提取过的文件直接复用。
  Future<VideoPlayerController> _extractAssetAndPlay(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    // 用 asset 路径的 hash 作为缓存文件名，避免路径分隔符冲突
    final fileName = assetPath.replaceAll('/', '_');
    final file = File('${dir.path}/$fileName');

    // 如果已提取过且文件完整，直接播放（幂等）
    if (!await file.exists()) {
      final bytes = await rootBundle.load(assetPath);
      await file.writeAsBytes(bytes.buffer.asUint8List());
    }

    return VideoPlayerController.file(file);
  }

  /// 用系统浏览器打开平台链接（B站等）
  Future<void> _openInBrowser() async {
    setState(() => _openingBrowser = true);
    try {
      final uri = Uri.parse(widget.onlineVideo!.url);
      // 先请用户确认再跳转
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('打开外部链接'),
            content: const Text('将使用系统浏览器打开此视频链接，是否继续？'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('取消')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('打开')),
            ],
          ),
        );
        if (confirmed == true) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开此链接，请检查 URL 是否正确')));
      }
    } finally {
      // 无论成功与否都返回列表页（浏览器接管后本页无意义）
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// 页面标题：内置视频或在线视频的名称
  String get _title {
    if (widget.onlineVideo != null) return widget.onlineVideo!.title;
    if (widget.video != null) return widget.video!.title;
    return '视频播放';
  }

  @override Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);

    // 正在打开浏览器 → 短暂过渡 UI
    if (_openingBrowser) {
      return Scaffold(
        appBar: isLandscape ? null : AppBar(title: Text(_title)),
        body: const Center(child: Text('正在打开浏览器...')),
      );
    }
    return Scaffold(
      // 横屏全屏：隐藏 AppBar
      appBar: isLandscape ? null : AppBar(title: Text(_title)),
      body: _buildBody(isLandscape),
    );
  }

  Widget _buildBody(bool isLandscape) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('视频无法播放',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                widget.onlineVideo != null
                    ? '请检查视频链接是否有效'
                    : '请确认视频文件已正确内置到应用中',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              // 横屏时提供返回按钮（因为没有 AppBar）
              if (isLandscape) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: VideoPlayer(_controller!)),
        VideoProgressIndicator(_controller!, allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Color(0xFF4CAF50))), // 森林绿进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_controller!.value.isPlaying
                    ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
              ),
              const Spacer(),
              // 横屏时显示返回按钮
              if (isLandscape)
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (_controller!.value.position >= _controller!.value.duration)
                TextButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('重新播放'),
                  onPressed: () {
                    _controller!.seekTo(Duration.zero);
                    _controller!.play();
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
