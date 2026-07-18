// lib/screens/profile/login_screen.dart — 用户登录页面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

/// 用户登录页面
///
/// 两个输入框（用户名 + 密码）+ 登录按钮。
/// 底部提供"注册新账号"入口跳转。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String? _errorText;
  bool _loading = false;

  bool get _canSubmit =>
      _usernameCtrl.text.isNotEmpty && _passwordCtrl.text.isNotEmpty && !_loading;

  @override void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _errorText = null; _loading = true; });
    try {
      await context.read<AuthProvider>().login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (mounted) Navigator.of(context).pop(); // 成功 → 返回
    } on AuthException catch (e) {
      setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: '用户名'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: '密码'),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('登录'),
              ),
            ),
            const SizedBox(height: 16),
            // ---- "注册新账号"入口 ----
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen())),
              child: const Text('注册新账号'),
            ),
          ],
        ),
      ),
    );
  }
}
