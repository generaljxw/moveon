// lib/screens/profile/register_screen.dart — 用户注册页面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../services/auth_service.dart';

/// 用户注册页面
///
/// 三个输入框（用户名、密码、确认密码）+ 注册按钮。
/// 全部非空且两次密码一致时按钮才可点击。
/// 注册成功后自动登录并返回上一页。
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _errorText;   // 服务器返回的错误消息
  bool _loading = false;

  /// 注册按钮是否可用：三个字段均非空且非加载中
  bool get _canSubmit =>
      _usernameCtrl.text.isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      !_loading;

  @override void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 客户端校验：两次密码需一致
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorText = '两次输入的密码不一致');
      return;
    }
    setState(() { _errorText = null; _loading = true; });
    try {
      await context.read<AuthProvider>().register(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (mounted) Navigator.of(context).pop(); // 成功 → 返回个人中心
    } on AuthException catch (e) {
      setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册新账号')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // ---- 用户名输入 ----
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(
                labelText: '用户名', hintText: '4-20 位字母、数字或下划线'),
              maxLength: 20,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // ---- 密码输入（密文） ----
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(
                labelText: '密码', hintText: '6-20 位字符'),
              obscureText: true, maxLength: 20,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // ---- 确认密码输入（密文） ----
            TextField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(labelText: '确认密码'),
              obscureText: true, maxLength: 20,
              onChanged: (_) => setState(() {}),
            ),
            // ---- 错误提示 ----
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            // ---- 注册按钮 ----
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                child: _loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('注册'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
