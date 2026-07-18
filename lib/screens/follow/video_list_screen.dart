// lib/screens/follow/video_list_screen.dart — 分类下的视频列表（内置 + 在线混合）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_category.dart';
import '../../models/online_video.dart';
import '../../services/category_service.dart';
import '../../services/video_link_service.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import 'video_player_screen.dart';
import 'add_video_dialog.dart';

/// 视频列表页 — 展示某运动类型下的内置视频和用户添加的在线视频
///
/// 内置视频和在线视频混合展示，通过标签区分来源。
/// 已登录用户可通过 AppBar 右侧 + 号添加在线视频。
/// 在线视频支持编辑（长按）和删除（左滑）。
class VideoListScreen extends StatefulWidget {
  final WorkoutCategory category;
  const VideoListScreen({super.key, required this.category});

  @override State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final _categoryService = CategoryService();
  final _videoLinkService = VideoLinkService();
  List<OnlineVideo> _onlineVideos = [];

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOnlineVideos();
  }

  /// 从数据库加载当前用户在此分类下的在线视频
  Future<void> _loadOnlineVideos() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.currentUser?.id == null) return;
    final videos = await _videoLinkService.getVideosForCategory(
      auth.currentUser!.id!, widget.category.name);
    if (mounted) setState(() => _onlineVideos = videos);
  }

  /// 打开添加弹窗 → 保存 → 检查重复 → 写入 → 刷新
  Future<void> _addVideo() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;

    final result = await showAddVideoDialog(context, category: widget.category.name);
    if (result == null || !mounted) return;

    // 检查是否与已有链接重复
    final isDup = await _videoLinkService.isDuplicateUrl(
      auth.currentUser!.id!, widget.category.name, result.url);
    if (isDup) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该链接已存在于此分类中')));
      }
      return;
    }

    // 填入 userId 并写入数据库
    final toSave = result.copyWith(userId: auth.currentUser!.id);
    await _videoLinkService.addVideo(toSave);
    await _loadOnlineVideos(); // 必须 await，否则后续 SnackBar 检查时数据未更新

    // 首次添加：引导用户发现编辑/删除菜单
    if (_onlineVideos.length == 1 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('点击右侧 ⋮ 可编辑或删除视频，也可左滑删除'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// 打开编辑弹窗 → 保存 → 更新 → 刷新
  Future<void> _editVideo(OnlineVideo video) async {
    final result = await showAddVideoDialog(
      context,
      category: widget.category.name,
      existingVideo: video,
    );
    if (result == null || !mounted) return;

    // 检查是否与其它记录重复（排除自身）
    final isDup = await _videoLinkService.isDuplicateUrl(
      video.userId, widget.category.name, result.url, excludeId: video.id);
    if (isDup) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该链接已存在于此分类中')));
      }
      return;
    }

    await _videoLinkService.updateVideo(result);
    _loadOnlineVideos();
  }

  /// 确认后删除在线视频
  Future<void> _deleteVideo(OnlineVideo video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除在线视频「${video.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _videoLinkService.deleteVideo(video.id!);
      _loadOnlineVideos();
    }
  }

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    // 内置视频列表（当前仅体操类有）
    final builtInVideos = _categoryService.getVideosForCategory(widget.category.name);
    final hasAnyVideos = builtInVideos.isNotEmpty || _onlineVideos.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      // 右下角 FAB：「添加在线视频」卡片式按钮（仅登录用户可见）
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: _addVideo,
              icon: const Icon(Icons.add),
              label: const Text('添加在线视频'),
            )
          : null,
      body: !hasAnyVideos
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _loadOnlineVideos,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                // 内置视频在前，在线视频在后
                itemCount: builtInVideos.length + _onlineVideos.length,
                itemBuilder: (context, index) {
                  if (index < builtInVideos.length) {
                    // 内置视频 — 不可编辑删除
                    return _BuiltInVideoTile(video: builtInVideos[index]);
                  } else {
                    // 在线视频 — 支持编辑和删除
                    final onlineVideo = _onlineVideos[index - builtInVideos.length];
                    return _OnlineVideoTile(
                      video: onlineVideo,
                      onTap: () => _playOnlineVideo(onlineVideo),
                      onEdit: () => _editVideo(onlineVideo),
                      onDelete: () => _deleteVideo(onlineVideo),
                    );
                  }
                },
              ),
            ),
    );
  }

  /// 播放在线视频 → 直链用原生播放器 / 链接用浏览器
  void _playOnlineVideo(OnlineVideo video) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(onlineVideo: video)),
    );
  }

  /// 该分类下无任何视频时的空状态
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无视频，敬请期待',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

/// 内置视频列表项 — 绿色播放图标 + "本地" 标签
class _BuiltInVideoTile extends StatelessWidget {
  final dynamic video; // VideoInfo 类型
  const _BuiltInVideoTile({required this.video});

  @override Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: MoveOnTheme.colorPrimaryLight.withAlpha(60),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_circle_fill,
              color: MoveOnTheme.colorPrimary, size: 26),
        ),
        title: Text(video.title),
        subtitle: Row(
          children: [
            Text('${video.durationSeconds ~/ 60} 分钟'),
            const SizedBox(width: 8),
            // "本地" 标签 — 绿色半透明胶囊
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: MoveOnTheme.colorPrimaryLight.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('本地',
                  style: TextStyle(fontSize: 10, color: MoveOnTheme.colorPrimaryDark)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video))),
      ),
    );
  }
}

/// 在线视频列表项 — 地球/浏览器图标 + "在线" 标签 + 左滑删除 + 长按编辑
class _OnlineVideoTile extends StatelessWidget {
  final OnlineVideo video;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OnlineVideoTile({
    required this.video, required this.onTap,
    required this.onEdit, required this.onDelete,
  });

  @override Widget build(BuildContext context) {
    // 根据视频类型选择图标和标签颜色
    final isDirect = video.videoType == 'direct';
    final labelColor = isDirect ? Colors.blue : Colors.orange;
    final labelBg = isDirect ? Colors.blue.shade50 : Colors.orange.shade50;

    return Dismissible(
      key: Key('online_${video.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async { onDelete(); return false; },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: labelBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              // 直链视频 → 视频图标，平台链接 → 地球网页图标
              isDirect ? Icons.ondemand_video : Icons.language,
              color: labelColor, size: 24,
            ),
          ),
          title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Row(
            children: [
              // "在线" 标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('在线',
                    style: TextStyle(fontSize: 10, color: labelColor)),
              ),
            ],
          ),
          // ⋮ 菜单：编辑 / 删除（与手势互补）
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit',
                child: ListTile(leading: Icon(Icons.edit, size: 20), title: Text('编辑'), dense: true)),
              const PopupMenuItem(value: 'delete',
                child: ListTile(leading: Icon(Icons.delete, size: 20, color: Colors.red), title: Text('删除', style: TextStyle(color: Colors.red)), dense: true)),
            ],
          ),
          onTap: onTap,
          onLongPress: onEdit, // 长按编辑（保留作为快捷操作）
        ),
      ),
    );
  }
}
