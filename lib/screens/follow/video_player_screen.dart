// lib/screens/follow/video_player_screen.dart — 视频播放器
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/category_service.dart';

/// 全屏视频播放器 — 播放 assets 中的跟练视频
///
/// 支持暂停/播放、拖动进度和音量调节。
/// 播放完毕显示"重新播放"按钮。
/// 返回后再次进入从头播放。
class VideoPlayerScreen extends StatefulWidget {
  final VideoInfo video;
  const VideoPlayerScreen({super.key, required this.video});

  @override State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // 从 assets 加载视频文件
      _controller = VideoPlayerController.asset(widget.video.assetPath);
      await _controller.initialize();
      await _controller.play(); // 自动开始播放
      setState(() => _initialized = true);
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  @override void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.video.title)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 视频文件缺失或损坏 (SR2 2a)
    if (_hasError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('视频无法播放，请检查安装包是否完整',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 视频画面
        Expanded(child: VideoPlayer(_controller)),
        // 进度条和播放时间
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,              // 允许拖动跳转 (SR2 4b)
          colors: const VideoProgressColors(playedColor: Colors.teal),
        ),
        // 控制栏：播放/暂停 + 音量
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // ---- 播放/暂停按钮 (SR2 4a) ----
              IconButton(
                icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  });
                },
              ),
              const Spacer(),
              // ---- 重新播放按钮（播放完成时显示 / SR2 6a） ----
              if (_controller.value.position >= _controller.value.duration)
                TextButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('重新播放'),
                  onPressed: () {
                    _controller.seekTo(Duration.zero);
                    _controller.play();
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
