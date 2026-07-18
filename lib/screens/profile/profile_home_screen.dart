// lib/screens/profile/profile_home_screen.dart — 个人中心（"我的"Tab）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'change_password_screen.dart';

/// 个人中心页面 — "我的"Tab 的内容
///
/// 根据 [AuthProvider.isLoggedIn] 切换两种显示模式：
/// - 未登录：登录 / 注册入口
/// - 已登录：用户名、修改密码、退出登录（含确认对话框）
class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isLoggedIn) {
          return _buildLoggedOut(context); // 游客模式
        }
        return _buildLoggedIn(context, auth); // 已登录
      },
    );
  }

  /// 游客模式 UI
  Widget _buildLoggedOut(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('登录后使用完整功能', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('登录'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('注册新账号'),
            ),
          ],
        ),
      ),
    );
  }

  /// 已登录 UI
  Widget _buildLoggedIn(BuildContext context, AuthProvider auth) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
            const SizedBox(height: 12),
            Text(auth.currentUser!.username, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            // ---- 修改密码入口 ----
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('修改密码'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            const Divider(),
            // ---- 退出登录入口（含确认对话框 / SR3 step 3） ----
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('退出登录', style: TextStyle(color: Colors.red)),
              onTap: () => _showLogoutConfirm(context, auth),
            ),
          ],
        ),
      ),
    );
  }

  /// 退出登录确认对话框（SR3 step 3-4）
  void _showLogoutConfirm(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(), // 取消
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.of(ctx).pop(); // 关闭对话框
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
