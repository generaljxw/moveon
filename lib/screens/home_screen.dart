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

  // 注意：如需替换为真实森林照片，只需将 Stack 底层的 _ForestBackground() 替换为：
  // Image.asset('assets/images/forest_background.jpg', fit: BoxFit.cover)

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 底层：森林系自然背景 — 多层渐变模拟阳光穿林的氛围
          // 后续替换为真实森林照片时，此层改为 Image.asset()
          const Positioned.fill(
            child: _ForestBackground(),
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

/// 森林系背景 — 代码生成的多层渐变
///
/// 模拟晨光穿过松林的视觉效果：顶部明亮（天空/晨雾），
/// 中段森林绿，底部深绿（树干阴影）。
/// V1.0 代码生成，后续可替换为真实森林照片。
class _ForestBackground extends StatelessWidget {
  const _ForestBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFC5E8B7), // 顶部：晨光浅绿
            Color(0xFF8BC78B), // 上段：明亮草绿
            Color(0xFF5DAE5B), // 中上段：柔和森林绿
            Color(0xFF2E7D32), // 中段：深森林绿
            Color(0xFF1B5E20), // 中下段：暗绿
            Color(0xFF0D3B0F), // 底部：树荫深色
          ],
          stops: [0.0, 0.15, 0.35, 0.55, 0.75, 1.0],
        ),
      ),
    );
  }
}
