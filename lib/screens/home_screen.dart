// lib/screens/home_screen.dart — 主页面（底部 Tab 导航）
import 'package:flutter/material.dart';
import 'follow/follow_home_screen.dart';
import 'diy/diy_home_screen.dart';
import 'profile/profile_home_screen.dart';

/// 应用主页 — 底部 3 Tab 导航容器
///
/// 使用 IndexedStack 保持 Tab 页面状态（切换不重置滚动位置等）。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // 三个 Tab 页面（IndexedStack 保持状态）
  static const _pages = <Widget>[
    FollowHomeScreen(),
    DiyHomeScreen(),
    ProfileHomeScreen(),
  ];

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: '跟练'),
          BottomNavigationBarItem(icon: Icon(Icons.build_outlined), label: 'DIY'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
