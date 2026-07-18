# MoveOn UI 风格改造设计文档

> 将默认 Material Design 升级为"清爽自然风"，打造年轻向上的健身体验

**版本**：V1.0 | **日期**：2026-07-18 | **设计方向**：森林系 × 呼吸感

---

## 1. Design Tokens

### 1.1 配色系统

| Token | 色值 | 用途 |
|-------|------|------|
| `primary` | `#4CAF50` | 主按钮、选中态、强调元素 |
| `primaryLight` | `#81C784` | 卡片浅色背景、标签 |
| `primaryDark` | `#388E3C` | 按压态、文字链接 |
| `surface` | `#F1F8E9` | 页面背景 |
| `card` | `#FFFFFF` | 卡片底色 |
| `accent` | `#FF7043` | 警示/高亮（倒计时最后5秒） |
| `textPrimary` | `#263238` | 主文字 |
| `textSecondary` | `#546E7A` | 副文字、标签 |
| `divider` | `#E0E8E0` | 分割线 |

### 1.2 分类专属色

每个运动类型有独立浅色背景，用于卡片和标签快速识别。

| 运动类型 | 卡片底色 | 说明 |
|---------|---------|------|
| 体操 | `#E8F5E9` | 浅森林绿 |
| 瑜伽 | `#E0F2F1` | 浅湖水绿 |
| 有氧操 | `#FFF3E0` | 浅活力橙 |
| 跳绳 | `#FCE4EC` | 浅玫瑰粉 |
| 塑形 | `#F3E5F5` | 浅优雅紫 |
| 普拉提 | `#E8EAF6` | 浅静谧蓝 |
| 拉伸 | `#FFF8E1` | 浅温暖黄 |
| 冥想 | `#E1F5FE` | 浅天空蓝 |

### 1.3 字体系统

| Token | 字体 | 字号 | 字重 | 用途 |
|-------|------|------|------|------|
| `headline` | Noto Sans SC | 24px | Medium | 页面标题 |
| `title` | Noto Sans SC | 16px | Medium | 卡片名称、按钮文字 |
| `body` | Noto Sans SC | 14px | Regular | 正文、列表副标题 |
| `caption` | Noto Sans SC | 12px | Regular | 标签、角标 |
| `countdown` | Noto Sans Mono | 96px | Light | 倒计时大数字 |

### 1.4 间距与圆角

| Token | 值 | 应用场景 |
|-------|-----|----------|
| `pagePadding` | 24px | 页面四周留白 |
| `cardPadding` | 20px | 卡片内容内边距 |
| `cardRadius` | 16px | 卡片、列表项圆角 |
| `buttonRadius` | 24px | 按钮圆角（胶囊形） |
| `cardGap` | 16px | 卡片之间间距 |
| `itemGap` | 12px | 列表项之间间距 |

### 1.5 阴影

| 状态 | elevation | 说明 |
|------|-----------|------|
| 默认 | 1 | 极淡阴影，若有若无 |
| 悬停/按压 | 3 | 轻微浮起 |
| 选中 | 3 + 1.5px 绿色边框 | 醒目标记 |

---

## 2. 组件规范

### 2.1 按钮

| 类型 | 样式 |
|------|------|
| **主按钮** | 森林绿填充 `#4CAF50`，白字 `#FFFFFF`，胶囊形 `buttonRadius` 24px |
| **次按钮** | 森林绿描边 `#4CAF50`，透明底，绿字 |
| **文字按钮** | 无边框，深绿字 `#388E3C` |
| **危险按钮** | 珊瑚橙描边 `#FF7043`，红色文字 |
| **禁用态** | 灰底 `#E0E0E0`，灰字 `#9E9E9E` |

### 2.2 底部导航栏

| 属性 | 规范 |
|------|------|
| 高度 | 64px |
| 背景 | `card` 白色 + 顶部 1px 阴影 |
| 选中态 | 森林绿填充小圆点指示器（非整块变色） |
| 未选中 | `textSecondary` 灰蓝色 |
| 分割线 | 无 |

### 2.3 卡片

| 属性 | 规范 |
|------|------|
| 形状 | 圆角 `cardRadius` 16px |
| 背景 | `card` 白色 |
| 阴影 | elevation 1 |
| 按压反馈 | `InkWell` + 浅绿色 splash `primaryLight` 30% 透明度 |

### 2.4 进度条

| 属性 | 规范 |
|------|------|
| 高度 | 6px |
| 底色 | `divider` |
| 填充色 | `primary` → `primaryLight` 水平渐变 |
| 圆角 | 3px |

### 2.5 AppBar

| 属性 | 规范 |
|------|------|
| 背景 | `surface` 页面背景色（非白色） |
| 标题 | `title` 字体，`textPrimary` 颜色 |
| 底部分割线 | 无 |
| 返回按钮 | `primary` 森林绿色 |

---

## 3. 页面改造

### 3.1 跟练首页（分类网格）

**变更**：
- 每个分类卡片使用对应**浅色专属背景**代替白色 `Card`
- 图标改为深色版本（`primaryDark` 色），尺寸 32px
- 去掉 `Card` 阴影 → 使用 `Container` + `BoxDecoration(color, borderRadius)`，更轻量
- 标题区加一行 subtitle "选择运动，开始跟练"
- 视频角标改为小圆点（绿色=有视频，灰色=暂无）

### 3.2 视频播放页面

**变更**：
- 进度条使用新规范（6px 高 + 绿色渐变）
- 控制栏背景改为半透明白色
- 全屏适配时保持 16:9 比例

### 3.3 DIY 模组列表

**变更**：
- 卡片左侧 4px 彩色竖条（用分类专属色）
- 空状态插画改为森林绿配色 + 运动主题简单图形
- FAB 改为森林绿胶囊形，文案"创建模组"
- 列表刷新 → `RefreshIndicator` 使用 `primary` 绿色

### 3.4 模组执行页面

**变更**：
- 倒计时区域背景 → `surface` 浅绿底
- 大字倒计时数字 → `Noto Sans Mono`，最后 5 秒变色为珊瑚橙 `accent`
- 动作名称上方添加圆形头像框（分类浅色背景 + 序号）
- 进度条 6px 高绿色渐变
- 暂停/继续按钮改为圆形+投影，提升操作感
- 动作切换 → `AnimatedSwitcher` 300ms 水平翻转入场

### 3.5 个人中心

**变更**：
- 未登录：头像区域替换为森林绿渐变圆形背景 + 运动人物图标
- 已登录：头像显示用户名首字，森林绿渐变底色
- 登录按钮 → 主按钮（绿色填充 + 胶囊形）
- 注册入口 → 次按钮（绿色描边）
- 列表项每行左侧缩进 24px
- 退出登录保留红色预警色

---

## 4. 动效

| 场景 | 效果 | 时长 |
|------|------|------|
| 页面推入 | 轻微上滑 + 淡入（`PageRouteBuilder`） | 200ms |
| 卡片点击 | 浅绿色 ripple splash | 默认 |
| 倒计时动作切换 | `AnimatedSwitcher` 横向翻转 | 300ms |
| 列表项删除 | `Dismissible` 左滑 + 红色背景 | 默认 |
| 倒计时最后5秒 | 数字变珊瑚橙 + 缩放脉冲 | 100ms × 5 |

---

## 5. 实现方式

采用 **Flutter ThemeData 集中配置** 方式，在 `app.dart` 中扩展 `ThemeData`：

1. 定义 `MoveOnTheme` 类，集中管理所有 Design Token（颜色、字体、间距）
2. 覆盖 `ThemeData` 的 `colorScheme`、`textTheme`、`cardTheme`、`elevatedButtonTheme` 等
3. 各页面引用 `Theme.of(context)` 获取 token，不硬编码色值
4. `WorkoutCategory` 模型添加 `backgroundColor` 字段，存储专属浅色

---

## 6. 实施影响范围

| 文件 | 改动类型 |
|------|---------|
| `lib/app.dart` | 重写 ThemeData 配置 |
| `lib/models/workout_category.dart` | 添加 `backgroundColor` 字段 |
| `lib/screens/follow/follow_home_screen.dart` | 卡片颜色、间距、标题 |
| `lib/screens/follow/video_player_screen.dart` | 进度条样式 |
| `lib/screens/diy/diy_home_screen.dart` | 卡片色条、FAB |
| `lib/screens/diy/module_execute_screen.dart` | 倒计时、进度条、动画 |
| `lib/screens/diy/module_create_screen.dart` | 按钮样式 |
| `lib/screens/diy/module_detail_screen.dart` | 按钮、间距 |
| `lib/screens/home_screen.dart` | 底部导航栏样式 |
| `lib/screens/profile/profile_home_screen.dart` | 头像、按钮 |

---

## 版本说明

| 版本 | 日期 | 变更说明 |
|------|------|----------|
| V1.0 | 2026-07-18 | 初版创建：森林系配色、Noto Sans SC 字体、Design Token 体系、页面改造规范 |
