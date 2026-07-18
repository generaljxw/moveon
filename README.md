# 🏃 动起来（MoveOn）

> 面向有健身需求人群的 Windows 桌面运动应用 — 视频跟练 + DIY 自定义练习

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📖 项目简介

**动起来（MoveOn）** 是一款 Windows 桌面运动健身应用，提供视频跟练和自定义练习两大核心功能，帮助用户在工作间隙科学运动、保持健康。

### V1.0 功能

| 模块 | 功能说明 |
|------|----------|
| 🔐 **用户系统** | 注册 / 登录 / 注销 / 修改密码，本地账户管理 |
| 📺 **视频跟练** | 8 大运动类型浏览，预置第八套广播体操跟练视频 |
| 🛠️ **DIY 练习** | 自定义创建练习模组，TTS 语音播报 + 倒计时执行 |
| 🔄 **自动更新** | 启动时版本检测，支持覆盖安装升级 |

---

## 🛠️ 技术栈

| 层面 | 技术选型 |
|------|----------|
| 开发框架 | Flutter 3.2+（Dart） |
| 状态管理 | Provider |
| 本地数据库 | SQLite（sqflite_common_ffi） |
| TTS 语音 | Flutter TTS（Windows 系统语音引擎） |
| 视频播放 | video_player + video_player_win |
| 音频播放 | audioplayers |
| 密码存储 | crypto（SHA-256 哈希） |

---

## 📁 项目结构

```text
moveon/
├── lib/                          # 应用源代码
│   ├── main.dart                 # 应用入口
│   ├── app.dart                  # MaterialApp 配置、路由、主题
│   ├── theme.dart                # 主题定义（Noto Sans SC）
│   ├── models/                   # 数据模型
│   │   ├── user.dart             # 用户模型
│   │   ├── exercise_module.dart  # DIY 练习模组
│   │   ├── exercise_action.dart  # 动作模型
│   │   ├── workout_category.dart # 运动类型
│   │   └── online_video.dart     # 在线视频
│   ├── services/                 # 业务逻辑与数据服务
│   │   ├── database_service.dart # SQLite 数据库
│   │   ├── auth_service.dart     # 用户认证
│   │   ├── tts_service.dart      # TTS 语音合成
│   │   ├── update_service.dart   # 版本检测更新
│   │   ├── category_service.dart # 运动类型管理
│   │   └── video_link_service.dart # 在线视频链接
│   ├── screens/                  # 页面
│   │   ├── home_screen.dart      # 底部 Tab 导航容器
│   │   ├── follow/               # 跟练 Tab
│   │   ├── diy/                  # DIY Tab
│   │   └── profile/              # 我的 Tab
│   ├── state/                    # 状态管理（Provider）
│   │   └── auth_provider.dart    # 认证状态
│   └── widgets/                  # 通用组件
│       └── countdown_timer.dart  # 倒计时组件
├── assets/                       # 资源文件
│   ├── videos/                   # 预置跟练视频
│   ├── audio/                    # 提示音效
│   └── images/category_icons/    # 运动类型图标
├── tests/                        # 测试代码
├── docs/                         # 文档
│   └── superpowers/specs/        # 需求规格文档
├── installer/                    # Windows 安装包配置（Inno Setup）
└── windows/                      # Windows 平台配置
```

---

## 🚀 快速开始

### 环境要求

| 工具 | 版本要求 |
|------|----------|
| Flutter SDK | ≥ 3.2.0 |
| Dart SDK | ≥ 3.2.0 |
| Visual Studio | 2022（含"使用 C++ 的桌面开发"工作负载） |
| Windows SDK | Windows 10 或更高 |

### 开发环境搭建

```bash
# 1. 克隆仓库
git clone git@github.com:generaljxw/moveon.git
cd moveon

# 2. 安装依赖
flutter pub get

# 3. 运行应用（Windows 桌面）
flutter run -d windows

# 4. 运行测试
flutter test
```

### 构建发布包

```bash
# 构建 Windows 发布版本
flutter build windows --release

# 打包为安装程序（需 Inno Setup 6+）
# 使用 installer/setup.iss 配置文件编译
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

## 📋 V1.0 功能模块

### 导航结构

底部 3 Tab 导航：**跟练** | **DIY** | **我的**

### 用户系统
- 注册（用户名 4-20 位字母/数字/下划线，密码 6-20 位）
- 登录（连续 5 次错误锁定 15 分钟）
- 注销 / 密码修改

### 视频跟练
- 8 类运动：瑜伽、有氧操、跳绳、塑形、体操、普拉提、拉伸、冥想
- 体操类预置第八套广播体操视频（480p）
- 支持添加在线视频链接

### DIY 自定义练习
- 创建练习模组（最多 10 个，动作时长 5-600 秒）
- TTS 语音播报 + 倒计时 + 结束前 5 秒提示音
- 模组增删改查

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
