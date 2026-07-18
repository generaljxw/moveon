// lib/state/auth_provider.dart — 登录状态管理
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

/// 用户认证状态管理 — 通过 Provider 向全应用暴露登录状态
///
/// [currentUser] 为 null 表示游客模式。
/// 登录状态通过 shared_preferences 持久化 user_id，
/// 应用重启时调用 [tryAutoLogin] 自动恢复。
class AuthProvider extends ChangeNotifier {
  User? _currentUser;

  /// 当前登录用户；null = 游客模式
  User? get currentUser => _currentUser;

  /// 是否已登录
  bool get isLoggedIn => _currentUser != null;

  /// 应用启动：尝试从本地恢复登录状态
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('logged_in_user_id');
    if (userId == null) return; // 游客模式

    // 从数据库重新加载用户信息
    final db = await DatabaseService.instance.database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (rows.isNotEmpty) {
      _currentUser = User.fromMap(rows.first);
      notifyListeners();
    }
  }

  /// 注册 → 自动登录
  Future<void> register(String username, String password) async {
    _currentUser = await AuthService.register(
      DatabaseService.instance, username, password);
    await _persistLogin();
    notifyListeners();
  }

  /// 登录
  Future<void> login(String username, String password) async {
    _currentUser = await AuthService.login(
      DatabaseService.instance, username, password);
    await _persistLogin();
    notifyListeners();
  }

  /// 退出登录 → 清除本地状态
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    notifyListeners();
  }

  /// 修改密码（需当前处于登录状态）
  Future<void> changePassword(String oldPw, String newPw) async {
    if (_currentUser == null) throw const AuthException('未登录');
    await AuthService.changePassword(
      DatabaseService.instance, _currentUser!.id!, oldPw, newPw);
  }

  /// 持久化用户 ID 到 shared_preferences
  Future<void> _persistLogin() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('logged_in_user_id', _currentUser!.id!);
  }
}
