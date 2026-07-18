// lib/screens/home_screen.dart — 主页面（底部 Tab 导航）
import 'package:flutter/material.dart';
import 'follow/follow_home_screen.dart';
import 'diy/diy_home_screen.dart';
import 'profile/profile_home_screen.dart';
import '../theme.dart';

/// 应用主页 — 底部 3 Tab 导航容器
///
/// 使用 IndexedStack 保持 Tab 页面状态。
/// 选中项使用森林绿填充圆点指示器（Spec §2.2）。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    FollowHomeScreen(), DiyHomeScreen(), ProfileHomeScreen(),
  ];

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        // 使用高度 64px + 选中态森林绿（Spec §2.2）
        selectedItemColor: MoveOnTheme.colorPrimary,
        unselectedItemColor: MoveOnTheme.colorTextSecondary,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: '跟练'),
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), label: 'DIY'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
