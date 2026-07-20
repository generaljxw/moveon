# 🏃 动起来（MoveOn）

> 面向有健身需求人群的跨平台运动应用 — 视频跟练 + DIY 自定义练习

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows_|_Android-blue?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📖 项目简介

**动起来（MoveOn）** 是一款跨平台运动健身应用（Windows 桌面 + Android 移动端），同一份 Flutter 代码库驱动两套平台 UI。提供视频跟练和自定义练习两大核心功能，帮助用户在工作间隙或随时随地进行科学运动、保持健康。

### V1.1 功能

| 模块 | 功能说明 |
|------|----------|
| 🔐 **用户系统** | 注册 / 登录 / 注销 / 修改密码，本地账户管理 |
| 📺 **视频跟练** | 8 大运动类型浏览，预置第八套广播体操跟练视频，支持在线视频链接 |
| 🛠️ **DIY 练习** | 自定义创建练习模组，TTS 语音播报 + 倒计时执行 |
| 📱 **跨平台适配** | 一套代码同时运行 Windows 桌面 + Android 移动端 |
| 🎨 **响应式 UI** | 移动端竖屏 2 列 / 桌面端横屏 4 列自适应网格；移动端 BottomSheet / 桌面端 Dialog 弹窗 |
| 🌲 **森林主题** | 各 Tab 独立森林背景图（晨间空地 / 林间深呼吸 / 密林深处），深色渐变遮罩 |
| 🔄 **自动更新** | Windows 桌面端启动时版本检测，支持覆盖安装升级 |
| 📐 **横屏全屏** | 视频播放页 + 练习执行页支持横竖屏旋转全屏模式 |

---

## 🛠️ 技术栈

| 层面 | 技术选型 |
|------|----------|
| 开发框架 | Flutter 3.2+（Dart） |
| 状态管理 | Provider |
| 本地数据库 | SQLite — sqflite_common_ffi（Windows）+ sqflite（Android），条件导出自动切换 |
| TTS 语音 | Flutter TTS（调用系统语音引擎：Windows SAPI / Android TTS） |
| 视频播放 | video_player + video_player_win（Windows）/ Android 原生播放器 |
| 音频播放 | audioplayers（跨平台音频） |
| 密码存储 | crypto（SHA-256 哈希） |
| 屏幕适配 | 自研 ResponsiveHelper — 基于 600dp 断点的横竖屏/平台自适应 |

---

## 📁 项目结构

```text
moveon/
├── lib/                                # 应用源代码
│   ├── main.dart                       # 应用入口（跨平台初始化）
│   ├── app.dart                        # MaterialApp 配置、路由、主题
│   ├── theme.dart                      # 主题定义（Noto Sans SC）
│   ├── models/                         # 数据模型
│   │   ├── user.dart                   # 用户模型
│   │   ├── exercise_module.dart        # DIY 练习模组
│   │   ├── exercise_action.dart        # 动作模型
│   │   ├── workout_category.dart       # 运动类型
│   │   └── online_video.dart           # 在线视频
│   ├── services/                       # 业务逻辑与数据服务
│   │   ├── database_service.dart       # SQLite 数据库（核心）
│   │   ├── database_service_stub.dart  # 跨平台数据库工厂（条件导出）
│   │   ├── auth_service.dart           # 用户认证
│   │   ├── tts_service.dart            # TTS 语音合成
│   │   ├── update_service.dart         # 版本检测更新（Windows）
│   │   ├── category_service.dart       # 运动类型管理
│   │   ├── video_link_service.dart     # 在线视频链接管理
│   │   └── video_player_init.dart      # 视频播放器初始化（条件注册）
│   ├── screens/                        # 页面
│   │   ├── home_screen.dart            # 底部 Tab 导航容器
│   │   ├── follow/                     # 跟练 Tab（运动类型 → 视频列表 → 播放）
│   │   ├── diy/                        # DIY Tab（模组列表 → 创建/编辑 → 执行）
│   │   └── profile/                    # 我的 Tab（登录/注册/个人信息/修改密码）
│   ├── state/                          # 状态管理（Provider）
│   │   └── auth_provider.dart          # 认证状态
│   ├── utils/                          # 工具类
│   │   └── responsive_helper.dart      # 屏幕适配工具（横竖屏+平台检测）
│   └── widgets/                        # 通用组件
│       └── countdown_timer.dart        # 倒计时组件
├── assets/                             # 资源文件
│   ├── videos/                         # 预置跟练视频
│   │   └── radio_calisthenics_8.mp4    # 第八套广播体操（480p）
│   ├── audio/                          # 提示音效
│   │   ├── countdown_beep.wav          # 倒计时提示音
│   │   ├── countdown_soft.wav          # 轻柔倒计时音
│   │   └── workout_complete.wav        # 完成语音
│   └── images/                         # 图片资源
│       ├── category_icons/             # 运动类型图标
│       ├── bg_follow.jpg               # 跟练页森林背景
│       ├── bg_diy.jpg                  # DIY 页森林背景
│       └── bg_profile.jpg              # 我的页森林背景
├── android/                            # Android 平台工程
│   ├── app/                            # Android 应用配置
│   │   └── build.gradle.kts            # 构建配置（compileSdk 34+，minSdk 26）
│   └── gradle/                         # Gradle Wrapper
├── windows/                            # Windows 平台工程
│   └── runner/                         # Windows 应用入口
├── installer/                          # Windows 安装包
│   └── setup.iss                       # Inno Setup 打包脚本
├── tests/                              # 测试代码
├── docs/                               # 文档
│   └── superpowers/
│       ├── specs/                      # 需求规格文档（桌面版 + 移动端）
│       └── plans/                      # 实施计划文档
└── pubspec.yaml                        # Flutter 依赖配置
```

---

## 🚀 快速开始

### 环境要求

| 工具 | 版本要求 | 用途 |
|------|----------|------|
| Flutter SDK | ≥ 3.2.0 | 跨平台框架 |
| Dart SDK | ≥ 3.2.0 | 开发语言 |
| Visual Studio | 2022（含"使用 C++ 的桌面开发"） | Windows 桌面构建 |
| Android Studio | Hedgehog+（含 Android SDK 34+） | Android 移动端构建 |
| Android SDK | API 34+（compileSdk），≥ 26（minSdk） | Android 编译目标 |

### 开发环境搭建

```bash
# 1. 克隆仓库
git clone git@github.com:generaljxw/moveon.git
cd moveon

# 2. 安装依赖
flutter pub get

# 3. 运行应用
# Windows 桌面
flutter run -d windows

# Android（需连接设备或启动模拟器）
flutter run -d android

# 4. 运行测试
flutter test
```

### 构建发布包

```bash
# Windows 桌面 — 构建 Release 版本
flutter build windows --release
# 打包为安装程序（需 Inno Setup 6+），使用 installer/setup.iss

# Android — 构建 APK（侧载分发）
flutter build apk --release          # 单架构 APK
flutter build apk --split-per-abi    # 按 CPU 架构分包（推荐）
```

---

## 🧪 测试

```bash
# 运行所有测试
flutter test

# 运行指定测试文件
flutter test tests/services/auth_service_test.dart
```

---

## 📋 功能模块详情

### 导航结构

底部 3 Tab 导航：**跟练** | **DIY** | **我的**

各 Tab 页采用森林主题背景图（跟练 — 晨间空地 / DIY — 林间深呼吸 / 我的 — 密林深处），深色渐变遮罩确保内容可读性。

### 用户系统
- 注册（用户名 4-20 位字母/数字/下划线，密码 6-20 位）
- 登录（连续 5 次错误锁定 15 分钟）
- 注销 / 密码修改
- 跨平台登录状态持久化（SharedPreferences）

### 视频跟练
- 8 类运动：瑜伽、有氧操、跳绳、塑形、体操、普拉提、拉伸、冥想
- 体操类预置第八套广播体操视频（480p）
- 支持添加在线视频链接
- 移动端：双策略视频加载（缓存提取 + Asset 回退），兼容华为等设备
- 视频播放页 + 练习执行页横竖屏自动旋转，全屏沉浸模式

### DIY 自定义练习
- 创建练习模组（最多 10 个，动作时长 5-600 秒）
- TTS 语音播报 + 倒计时 + 结束前 5 秒提示音
- 模组增删改查
- 移动端创建/编辑/确认弹窗自动切换 BottomSheet 样式

### 屏幕适配策略

| 场景 | 移动端（≤ 600dp） | 桌面端（> 600dp） |
|------|-------------------|-------------------|
| 运动类型网格 | 竖屏 2 列 / 横屏 4 列 | 横屏 4 列 |
| 确认弹窗 | BottomSheet | Dialog |
| 内容浮层 | BottomSheet | Dialog |
| 视频/练习 | 支持横竖屏旋转全屏 | 窗口 / 全屏 |

---

## 📄 许可证

MIT License

---

## 👤 维护者

- **generaljxw** — [GitHub](https://github.com/generaljxw)

---

<p align="center">
  <sub>Made with ❤️ & Flutter</sub>
</p>
