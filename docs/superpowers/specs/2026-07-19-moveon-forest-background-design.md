# MoveOn 森林系背景图功能设计文档

> 基于 brainstorming 讨论结论，2026-07-19

---

## 概述

为 MoveOn 三个 Tab 页面（跟练 / DIY / 我的）添加**写实森林照片背景**，通过半透明白色遮罩层保证 UI 可读性，营造"在林中锻炼"的沉浸氛围。

## 视觉方案

| 决策项 | 选择 | 说明 |
|--------|------|------|
| **背景风格** | 写实森林照片（自然光、晨雾、林间小径） | 与森林系配色呼应 |
| **图片数量** | **1 张**，三 Tab 共享 | 视觉统一，减少 APK 体积 |
| **遮罩层** | 白色半透明，不透明度 75-80% | 保证卡片文字清晰可读 |
| **遮罩实现** | 代码层 `Stack` + `Container(color: white.withAlpha(N))` | 方便 hot reload 微调 |
| **滚动行为** | 背景固定不动（视觉差效果） | "窗外就是森林"的空间感 |

## 图片规格

| 参数 | 要求 |
|------|------|
| 分辨率 | ≥ 1080 × 2400（手机竖屏） |
| 宽高比 | 约 9:16 |
| 文件格式 | JPEG |
| 文件大小 | ≤ 500 KB（压缩后） |
| 存储路径 | `assets/images/forest_background.jpg` |

## 图片获取路线

**路线：B（免费图库）→ C（Midjourney AI）**

### 第一阶段：免费图库搜索

在 Unsplash / Pexels 搜索关键词：
- `sunlight forest path`
- `morning woods mist`
- `green forest trail peaceful`

选择标准：偏暗色调、有纵深感、绿色基调为主。

### 第二阶段：Midjourney 生成（如未找到满意图片）

Prompt：
```
sunlit forest path, morning mist through pine trees, soft golden light,
dappled shadows on mossy ground, peaceful woodland atmosphere,
nature photography, 8K, shallow depth of field,
natural green tones, zen vibes --ar 9:16 --style raw
```

## 实现方案

### 架构

```
HomeScreen (Stack)
├── [底层] forest_background.jpg — 全屏铺满，fit: BoxFit.cover
├── [中层] 白色遮罩 — Container(color: Colors.white.withAlpha(190))  // ~75%
└── [顶层] IndexedStack(3 Tabs) — 各子页面 Scaffold 背景透明
```

### 代码改动

| 文件 | 改动 |
|------|------|
| `lib/screens/home_screen.dart` | `Scaffold` 改为 `Stack`，底层加背景图 + 遮罩，`IndexedStack` 保持顶层 |
| `lib/theme.dart` | 新增 `colorSurface` 的背景透明度 Token，子页面 Scaffold 透出背景 |
| `lib/screens/follow/follow_home_screen.dart` | `Scaffold` 背景改为 `Colors.transparent` |
| `lib/screens/diy/diy_home_screen.dart` | `Scaffold` 背景改为 `Colors.transparent` |
| `lib/screens/profile/profile_home_screen.dart` | `Scaffold` 背景改为 `Colors.transparent` |
| `pubspec.yaml` | `assets` 添加 `assets/images/forest_background.jpg` |
| `assets/images/` | 新增 `forest_background.jpg` |

### 子页面适配

各子页面 `Scaffold` 的 `backgroundColor` 从默认的 `colorSurface` 改为 `Colors.transparent`：

```dart
// 之前
return Scaffold(
  appBar: AppBar(...),
  body: ...,
);

// 之后
return Scaffold(
  backgroundColor: Colors.transparent, // 透出父级背景
  appBar: AppBar(
    backgroundColor: Colors.white.withAlpha(200), // AppBar 半透白色
    ...
  ),
  body: ...,
);
```

### 卡片不受影响

- 运动类型卡片底色为不透明白色 + 4px 彩色侧条 — `colorCard = Colors.white`
- 模组列表卡片同理 — 不透明白色
- 个人中心页面按钮为绿色/白底 — 不透明白色
- **背景只出现在卡片间隙和页面边缘**

## 验收标准

- [ ] 三个 Tab 页面均显示森林背景图
- [ ] 背景图在内容滚动时保持固定
- [ ] 文字和卡片在背景上清晰可读
- [ ] 横竖屏切换时背景图正常铺满
- [ ] Windows + Android 双平台验证通过
- [ ] APK 增量 ≤ 600 KB  

## 版本说明

| 版本 | 作者 | 日期 | 变更说明 |
|------|------|------|----------|
| V1.0 | - | 2026-07-19 | 初版创建 |
