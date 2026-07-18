// lib/screens/diy/diy_home_screen.dart — DIY 模组列表
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/exercise_module.dart';
import '../../models/exercise_action.dart';
import 'module_create_screen.dart';
import 'module_detail_screen.dart';

/// DIY 模组列表页面
///
/// 已登录：展示用户创建的模组列表（最多 10 个）。
/// 未登录（游客模式）：提示登录。
class DiyHomeScreen extends StatefulWidget {
  const DiyHomeScreen({super.key});
  @override State<DiyHomeScreen> createState() => _DiyHomeScreenState();
}

class _DiyHomeScreenState extends State<DiyHomeScreen> {
  List<ExerciseModule> _modules = [];
  bool _loaded = false;

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    _loadModules();
  }

  Future<void> _loadModules() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    final db = await DatabaseService.instance.database;
    final rows = await db.query('exercise_modules',
      where: 'user_id = ?', whereArgs: [auth.currentUser!.id],
      orderBy: 'created_at DESC');
    if (mounted) setState(() {
      _modules = rows.map((r) => ExerciseModule.fromMap(r)).toList();
      _loaded = true;
    });
  }

  /// 左滑删除（SR2 step 8-10）
  Future<void> _deleteModule(ExerciseModule module) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模组「${module.name}」吗？删除后不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      final db = await DatabaseService.instance.database;
      await db.delete('exercise_modules', where: 'id = ?', whereArgs: [module.id]);
      _loadModules();
    }
  }

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return _buildGuestPrompt(context); // 游客模式
    }
    return Scaffold(
      appBar: AppBar(title: const Text('DIY 练习')),
      body: _modules.isEmpty && _loaded
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('还没有练习模组，点击下方按钮创建',
                      style: TextStyle(color: Colors.grey)),
                ],
              ))
          : RefreshIndicator(
              onRefresh: _loadModules,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _modules.length,
                itemBuilder: (context, index) {
                  final module = _modules[index];
                  return Dismissible(
                    key: Key('module_${module.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      await _deleteModule(module);
                      return false; // 手动刷新
                    },
                    child: Card(
                      child: ListTile(
                        title: Text(module.name),
                        subtitle: Text(module.category),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) =>
                                ModuleDetailScreen(module: module)));
                          _loadModules(); // 返回后刷新
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
      // ---- FAB: 创建模组（满 10 个时禁用 / SR1 1a） ----
      floatingActionButton: _modules.length >= 10
          ? null  // 已满 → 不显示按钮
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ModuleCreateScreen()));
                _loadModules();
              },
              icon: const Icon(Icons.add),
              label: const Text('创建练习模组'),
            ),
    );
  }

  /// 游客提示：请先登录
  Widget _buildGuestPrompt(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DIY 练习')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('请先登录后使用 DIY 功能', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
