// lib/screens/profile/change_password_screen.dart — 修改密码页面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_provider.dart';
import '../../services/auth_service.dart';

/// 修改密码页面
///
/// 需验证原密码，新密码 6-20 位且不能与原密码相同。
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _errorText;
  bool _loading = false;

  bool get _canSubmit =>
      _oldPwCtrl.text.isNotEmpty &&
      _newPwCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      !_loading;

  @override void dispose() {
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newPwCtrl.text != _confirmCtrl.text) {
      setState(() => _errorText = '两次输入的密码不一致');
      return;
    }
    setState(() { _errorText = null; _loading = true; });
    try {
      await context.read<AuthProvider>().changePassword(
        _oldPwCtrl.text, _newPwCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码修改成功')));
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改密码')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _oldPwCtrl,
              decoration: const InputDecoration(labelText: '原密码'),
              obscureText: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPwCtrl,
              decoration: const InputDecoration(
                labelText: '新密码', hintText: '6-20 位字符'),
              obscureText: true, maxLength: 20,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(labelText: '确认新密码'),
              obscureText: true, maxLength: 20,
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
                    : const Text('确认修改'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
