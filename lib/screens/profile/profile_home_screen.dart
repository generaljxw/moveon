// lib/screens/profile/profile_home_screen.dart — 个人中心（"我的"Tab）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'change_password_screen.dart';

/// 个人中心页面 — "我的"Tab 的内容
///
/// 根据登录状态切换：未登录显示登录/注册入口（新风格），
/// 已登录显示用户名+森林绿头像+操作列表。
class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) return _buildLoggedOut(context);
        return _buildLoggedIn(context, auth);
      },
    );
  }

  Widget _buildLoggedOut(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 森林绿渐变圆形背景 + 运动人物图标
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MoveOnTheme.colorPrimary, MoveOnTheme.colorPrimaryLight],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fitness_center, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text('登录后使用完整功能',
                style: TextStyle(fontSize: 16, color: MoveOnTheme.colorTextSecondary)),
              const SizedBox(height: 28),
              // 主按钮：绿色填充 + 胶囊形
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('登录'),
                ),
              ),
              const SizedBox(height: 12),
              // 次按钮：绿色描边
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('注册新账号'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedIn(BuildContext context, AuthProvider auth) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // 森林绿渐变头像 — 显示用户名首字
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.transparent,
              child: Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MoveOnTheme.colorPrimary, MoveOnTheme.colorPrimaryLight],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    auth.currentUser!.username[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(auth.currentUser!.username, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            // 修改密码
            ListTile(
              leading: const Icon(Icons.lock_outline, color: MoveOnTheme.colorPrimary),
              title: const Text('修改密码'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            const Divider(color: MoveOnTheme.colorDivider),
            // 退出登录
            ListTile(
              leading: const Icon(Icons.logout, color: MoveOnTheme.colorAccent),
              title: const Text('退出登录', style: TextStyle(color: MoveOnTheme.colorAccent)),
              onTap: () => _showLogoutConfirm(context, auth),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () { auth.logout(); Navigator.of(ctx).pop(); },
            child: const Text('确定', style: TextStyle(color: MoveOnTheme.colorAccent)),
          ),
        ],
      ),
    );
  }
}
