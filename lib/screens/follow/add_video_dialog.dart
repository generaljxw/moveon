// lib/screens/follow/add_video_dialog.dart — 添加/编辑在线视频弹窗
import 'package:flutter/material.dart';
import '../../models/online_video.dart';
import '../../services/video_link_service.dart';
import '../../theme.dart';

/// 显示添加或编辑在线视频的弹窗
///
/// [category]：所属分类名（添加模式必传，编辑模式沿用 existingVideo.category）。
/// [existingVideo]：编辑模式传入已有视频数据以预填表单。
///
/// 返回 [OnlineVideo] 表示用户点击了保存，返回 null 表示取消。
Future<OnlineVideo?> showAddVideoDialog(
  BuildContext context, {
  required String category,
  OnlineVideo? existingVideo,
}) {
  return showDialog<OnlineVideo>(
    context: context,
    builder: (ctx) => _AddVideoDialog(
      category: category,
      existingVideo: existingVideo,
    ),
  );
}

/// 添加/编辑在线视频弹窗的内部 StatefulWidget
///
/// 管理表单输入状态和前端校验逻辑。校验规则委托给 [VideoLinkService]。
class _AddVideoDialog extends StatefulWidget {
  final String category;
  final OnlineVideo? existingVideo;
  const _AddVideoDialog({required this.category, this.existingVideo});

  @override State<_AddVideoDialog> createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<_AddVideoDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  // 视频类型：初次渲染时根据 URL 判断，后续URL变化时自动重新判定
  late String _videoType;
  // 表单逐字段校验错误
  String? _nameError;
  String? _urlError;

  /// 是否为编辑模式
  bool get _isEditing => widget.existingVideo != null;

  @override void initState() {
    super.initState();
    final existing = widget.existingVideo;
    _nameCtrl = TextEditingController(text: existing?.title ?? '');
    _urlCtrl = TextEditingController(text: existing?.url ?? '');
    // 编辑模式沿用已有类型，添加模式根据 URL 自动判定
    _videoType = existing?.videoType ??
        VideoLinkService.detectVideoType(_urlCtrl.text);
  }

  @override void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  /// 执行全部表单校验，全部通过返回 true
  bool _validate() {
    setState(() {
      _nameError = VideoLinkService.validateTitle(_nameCtrl.text);
      _urlError = VideoLinkService.validateUrl(_urlCtrl.text);
    });
    return _nameError == null && _urlError == null;
  }

  /// 根据当前表单状态构造 OnlineVideo 对象
  ///
  /// 编辑模式保留已有 id/userId/createdAt；添加模式 id 为 null（由数据库分配）。
  OnlineVideo _buildVideo() {
    return OnlineVideo(
      id: widget.existingVideo?.id,
      userId: widget.existingVideo?.userId ?? 0,
      category: widget.category,
      title: _nameCtrl.text.trim(),
      url: _urlCtrl.text.trim(),
      videoType: _videoType,
      createdAt: widget.existingVideo?.createdAt ?? DateTime.now(),
    );
  }

  @override Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑在线视频' : '添加在线视频'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 视频名称输入
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '视频名称',
                hintText: '给视频起个名字（最长 50 字符）',
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
              maxLength: 50,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // 视频链接输入
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: '视频链接',
                hintText: 'https://...',
                errorText: _urlError,
                border: const OutlineInputBorder(),
              ),
              // URL 变化时自动重新检测视频类型
              onChanged: (value) {
                setState(() {
                  _videoType = VideoLinkService.detectVideoType(value);
                });
              },
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            // 视频类型切换（手动覆盖自动检测结果）
            Row(
              children: [
                const Text('类型：', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('在线链接'),
                  selected: _videoType == 'link',
                  onSelected: (v) {
                    if (v) setState(() => _videoType = 'link');
                  },
                  selectedColor: MoveOnTheme.colorPrimaryLight.withAlpha(80),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('直链视频'),
                  selected: _videoType == 'direct',
                  onSelected: (v) {
                    if (v) setState(() => _videoType = 'direct');
                  },
                  selectedColor: MoveOnTheme.colorPrimaryLight.withAlpha(80),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_validate()) return;
            Navigator.of(context).pop(_buildVideo());
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
