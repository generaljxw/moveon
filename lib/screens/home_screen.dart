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

  // 三张森林背景图 — 每个Tab一张，主题与功能呼应
  static const _backgroundImages = [
    'assets/images/bg_follow.jpg',   // 跟练：林间空地晨光
    'assets/images/bg_diy.jpg',      // DIY：森林中呼吸的女子
    'assets/images/bg_profile.jpg',  // 我的：深林静谧禅意
  ];

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 底层：森林系背景图 — 每Tab不同，带淡入淡出过渡
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: Image.asset(
                _backgroundImages[_currentIndex],
                key: ValueKey(_currentIndex),
                fit: BoxFit.cover,
                // 图片加载失败时静默降级（不影响功能）
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          // 中层：白色遮罩 — 约75%不透明度，保证UI可读性
          Positioned.fill(
            child: Container(color: Colors.white.withAlpha(190)),
          ),
          // 顶层：原有 Tab 页面（子页面 Scaffold 背景透明，透出背景）
          IndexedStack(index: _currentIndex, children: _pages),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
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
