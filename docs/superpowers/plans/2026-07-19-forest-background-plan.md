# 森林系背景图 实现计划

> **Goal:** 三个 Tab 页面共用一张写实森林背景图，通过白色遮罩保证 UI 可读性

**Architecture:** HomeScreen 的 Scaffold 替换为 Stack（背景图 + 白色遮罩 + IndexedStack），三个子页面 Scaffold 背景改为透明。

---

## Global Constraints

- 图片格式 JPEG，大小 ≤ 500 KB，分辨率 ≥ 1080×2400
- 白��遮罩不透明度 75%（`Colors.white.withAlpha(190)`）
- 背景固定不随内容滚动
- Windows + Android 双平台验证
- TDD + 原子提交

---

### Task 1: 获取森林背景图

- [ ] 从 Unsplash/Pexels 搜索并下载森林照片
- [ ] 压缩至 ≤ 500KB JPEG 1080×2400
- [ ] 保存到 `assets/images/forest_background.jpg`

### Task 2: 注册资源并修改 HomeScreen

- [ ] `pubspec.yaml` 添加 `assets/images/forest_background.jpg`
- [ ] `lib/screens/home_screen.dart` — Scaffold 改为 Stack 结构

```dart
@override Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // 底层：森林背景图
        Positioned.fill(
          child: Image.asset(
            'assets/images/forest_background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // 中层：白色遮罩（75% 不透明度）
        Positioned.fill(
          child: Container(color: Colors.white.withAlpha(190)),
        ),
        // 顶层：原有 Tab 页面
        IndexedStack(index: _currentIndex, children: _pages),
      ],
    ),
    bottomNavigationBar: ...,
  );
}
```

### Task 3: 子页面背景透明

- [ ] `lib/screens/follow/follow_home_screen.dart` — Scaffold + AppBar 背景透明
- [ ] `lib/screens/diy/diy_home_screen.dart` — 同上
- [ ] `lib/screens/profile/profile_home_screen.dart` — 同上

```dart
// 每个子页面 Scaffold 修改：
backgroundColor: Colors.transparent,
// AppBar:
backgroundColor: Colors.white.withAlpha(190),
```

### Task 4: 验证

- [ ] `flutter test` — 所有测试通过
- [ ] `flutter build apk --debug` — Android 构建成功
- [ ] 模拟器安装验证
