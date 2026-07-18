// lib/app.dart — MoveOn 应用根 Widget
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/auth_provider.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

/// MoveOn 应用根 Widget
///
/// 管理 Provider 状态层和 MaterialApp 配置。
/// 启动时自动尝试恢复登录状态。
class MoveOnApp extends StatelessWidget {
  const MoveOnApp({super.key});

  @override Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
      ],
      child: MaterialApp(
        title: '动起来 - MoveOn',
        debugShowCheckedModeBanner: false,
        // 使用 MoveOnTheme 集中管理的 Design Token（Spec §5）
        theme: MoveOnTheme.buildTheme(),
        home: const HomeScreen(),
      ),
    );
  }
}
