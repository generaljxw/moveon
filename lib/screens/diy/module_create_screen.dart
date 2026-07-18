// lib/screens/diy/module_create_screen.dart — 创建/编辑练习模组
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/exercise_module.dart';
import '../../models/exercise_action.dart';
import '../../models/workout_category.dart';
import '../../services/tts_service.dart';

/// 临时动作数据（编辑用，未持久化前存在本地状态）
class _ActionDraft {
  String name;
  int durationSeconds;
  bool isRest;
  _ActionDraft({required this.name, required this.durationSeconds, this.isRest = false});
}

/// 创建/编辑练习模组页面
///
/// 传入 [existingModule] 为编辑模式；否则为新建模式。
class ModuleCreateScreen extends StatefulWidget {
  final ExerciseModule? existingModule;
  final List<ExerciseAction>? existingActions;
  const ModuleCreateScreen({super.key, this.existingModule, this.existingActions});

  @override State<ModuleCreateScreen> createState() => _ModuleCreateScreenState();
}

class _ModuleCreateScreenState extends State<ModuleCreateScreen> {
  late String _name;               // 模组名称
  late String _category;           // 运动类型
  final List<_ActionDraft> _actions = []; // 动作列表

  bool get _isEditing => widget.existingModule != null;

  @override void initState() {
    super.initState();
    _name = widget.existingModule?.name ?? '';
    _category = widget.existingModule?.category ?? WorkoutCategory.defaults.first.name;
    if (widget.existingActions != null) {
      _actions.addAll(widget.existingActions!.map((a) =>
          _ActionDraft(name: a.name, durationSeconds: a.durationSeconds, isRest: a.isRest)));
    }
  }

  /// 保存按钮是否可用：名称非空 + 至少1个非休息动作
  bool get _canSave =>
      _name.trim().isNotEmpty && _actions.any((a) => !a.isRest);

  /// 快捷休息对话框 — 仅需输入时长，名称固定为"休息"，默认 10 秒
  Future<void> _showQuickRestDialog() async {
    final durationCtrl = TextEditingController(text: '10');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加休息间隔'),
        content: TextField(
          controller: durationCtrl,
          decoration: const InputDecoration(
            labelText: '休息时长（秒）', hintText: '5-600', helperText: '默认 10 秒'),
          keyboardType: TextInputType.number,
          autofocus: true, // 自动聚焦，方便快速输入
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final dur = int.tryParse(durationCtrl.text);
              if (dur == null || dur < 5 || dur > 600) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('时长范围为 5-600 秒')));
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _actions.add(_ActionDraft(
        name: '休息',
        durationSeconds: int.parse(durationCtrl.text),
        isRest: true,
      )));
    }
  }

  /// 弹出"添加动作"对话框
  Future<void> _showAddActionDialog({_ActionDraft? editTarget, int? editIndex}) async {
    final nameCtrl = TextEditingController(text: editTarget?.name ?? '');
    final durationCtrl = TextEditingController(
        text: editTarget?.durationSeconds.toString() ?? '60');
    bool isRest = editTarget?.isRest ?? false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editTarget != null ? '编辑动作' : '添加动作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '动作名称')),
              TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: '时长（秒）', hintText: '5-600'),
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
            TextButton(
              onPressed: () {
                // 校验：名称为空不可添加 (SR1 7a)
                if (nameCtrl.text.trim().isEmpty) return;
                final dur = int.tryParse(durationCtrl.text);
                if (dur == null || dur < 5 || dur > 600) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('时长范围为 5-600 秒')));
                  return;
                }
                // 将校验后的数据暂存，通过Navigator返回
                Navigator.of(ctx).pop(true);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final draft = _ActionDraft(
        name: nameCtrl.text.trim(),
        durationSeconds: int.parse(durationCtrl.text),
        isRest: isRest,
      );
      setState(() {
        if (editIndex != null) {
          _actions[editIndex] = draft; // 编辑模式
        } else {
          _actions.add(draft);          // 新增
        }
      });
    }
  }

  /// 保存模组到数据库
  Future<void> _save() async {
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入模组名称')));
      return;
    }
    final auth = context.read<AuthProvider>();
    final db = await DatabaseService.instance.database;

    if (_isEditing) {
      // 编辑模式：更新模组 + 替换动作列表
      await db.update('exercise_modules', {
        'name': _name.trim(), 'category': _category},
        where: 'id = ?', whereArgs: [widget.existingModule!.id]);
      await db.delete('exercise_actions',
          where: 'module_id = ?', whereArgs: [widget.existingModule!.id]);
      final moduleId = widget.existingModule!.id!;
      for (int i = 0; i < _actions.length; i++) {
        await db.insert('exercise_actions', _actions[i].toModuleAction(moduleId, i).toMap());
      }
    } else {
      // 新建模式
      final moduleId = await db.insert('exercise_modules', {
        'user_id': auth.currentUser!.id,
        'name': _name.trim(), 'category': _category,
        'created_at': DateTime.now().toIso8601String(),
      });
      for (int i = 0; i < _actions.length; i++) {
        await db.insert('exercise_actions', _actions[i].toModuleAction(moduleId, i).toMap());
      }
    }

    // 尝试生成 TTS 语音（失败不阻塞保存 / SR1 14a）
    try {
      final tts = TtsService.instance;
      await tts.init();
      // 为每个动作生成一条语音文本
      for (final action in _actions) {
        await tts.speak('${action.name}，时间${action.durationSeconds}秒');
      }
    } catch (_) {
      // TTS 失败不阻塞保存
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音生成失败，请检查系统语音设置')));
    }

    if (mounted) Navigator.of(context).pop(true); // 返回 DIY 首页
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑模组' : '创建练习模组')),
      body: Column(
        children: [
          // ---- 模组名称 + 运动类型 ----
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              TextField(
                decoration: const InputDecoration(labelText: '模组名称', hintText: '输入名称（最多 30 字）'),
                controller: TextEditingController(text: _name),
                maxLength: 30,
                onChanged: (v) => setState(() => _name = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: '运动类型'),
                items: WorkoutCategory.defaults.map((c) =>
                    DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ]),
          ),
          // ---- 动作列表（可拖拽排序 / SR1 step 12） ----
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _actions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _actions.removeAt(oldIndex);
                  _actions.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final action = _actions[index];
                return ListTile(
                  key: ValueKey('action_$index'),
                  leading: CircleAvatar(
                    backgroundColor: action.isRest ? Colors.orange.shade100 : Colors.teal.shade100,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(action.name),
                  subtitle: Text(action.isRest
                      ? '休息 ${action.durationSeconds}秒'
                      : '${action.durationSeconds}秒'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 编辑按钮
                      IconButton(icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showAddActionDialog(editTarget: action, editIndex: index)),
                      // 滑动删除（SR1 12a）
                      IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => setState(() => _actions.removeAt(index))),
                    ],
                  ),
                  // 休息类型显示橙色标签
                );
              },
            ),
          ),
        ],
      ),
      // ---- 底部操作栏：添加动作 | 快捷休息 | 保存模组 ----
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('添加动作'),
                onPressed: () => _showAddActionDialog(),
              ),
            ),
            const SizedBox(width: 8),
            // 添加休息：弹出时长选择对话框，默认 10 秒
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.bedtime_outlined, size: 18),
                label: const Text('添加休息', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                onPressed: () => _showQuickRestDialog(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _canSave ? _save : null,
                child: const Text('保存模组'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// _ActionDraft 扩展：转换为可持久化的 ExerciseAction
extension _ActionDraftExt on _ActionDraft {
  ExerciseAction toModuleAction(int moduleId, int sortOrder) {
    return ExerciseAction(
      moduleId: moduleId, name: name,
      durationSeconds: durationSeconds, isRest: isRest,
      sortOrder: sortOrder,
    );
  }
}
