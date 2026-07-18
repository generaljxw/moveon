// lib/screens/diy/module_detail_screen.dart — 模组详情页
import 'package:flutter/material.dart';
import '../../models/exercise_module.dart';
import '../../models/exercise_action.dart';
import '../../services/database_service.dart';
import 'module_create_screen.dart';
import 'module_execute_screen.dart';

/// 模组详情页 — 查看模组完整信息
///
/// 三个操作入口：开始练习、编辑、删除。
class ModuleDetailScreen extends StatefulWidget {
  final ExerciseModule module;
  const ModuleDetailScreen({super.key, required this.module});

  @override State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  List<ExerciseAction> _actions = [];

  @override void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query('exercise_actions',
      where: 'module_id = ?', whereArgs: [widget.module.id],
      orderBy: 'sort_order ASC');
    if (mounted) setState(() {
      _actions = rows.map((r) => ExerciseAction.fromMap(r)).toList();
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模组「${widget.module.name}」吗？删除后不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      final db = await DatabaseService.instance.database;
      await db.delete('exercise_modules', where: 'id = ?', whereArgs: [widget.module.id]);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override Widget build(BuildContext context) {
    final totalSec = ExerciseModule.totalDuration(_actions);
    return Scaffold(
      appBar: AppBar(title: Text(widget.module.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'edit') {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) =>
                    ModuleCreateScreen(existingModule: widget.module, existingActions: _actions)));
              } else if (val == 'delete') { _delete(); }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑')),
              const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 模组概要
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Chip(label: Text(widget.module.category)),
              const SizedBox(width: 12),
              Text('${_actions.length} 个动作'),
              const Spacer(),
              Text('共 ${totalSec ~/ 60} 分 ${totalSec % 60} 秒'),
            ]),
          ),
          const Divider(),
          // 动作列表
          Expanded(
            child: ListView.builder(
              itemCount: _actions.length,
              itemBuilder: (context, index) {
                final action = _actions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: action.isRest ? Colors.orange.shade100 : Colors.teal.shade100,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(action.name),
                  subtitle: Text(action.isRest
                      ? '休息 ${action.durationSeconds}秒'
                      : '${action.durationSeconds}秒'),
                  trailing: action.isRest
                      ? const Chip(label: Text('休息', style: TextStyle(fontSize: 12)))
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      // 底部"开始练习"按钮
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始练习'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) =>
                    ModuleExecuteScreen(module: widget.module, actions: _actions))),
            ),
          ),
        ),
      ),
    );
  }
}
