# CLAUDE.md

这份文件为Claude Code (claude.ai/code) 在本仓库中工作时提供指引。

## ⚠️ 核心原则：技能强制调用 (REQUIRED)

在采取任何实现行动**之前**，**必须**先调用Superpowers技能。这不是可选的。

*   开始任何新功能或设计工作，**必须**调用 `superpowers:brainstorming`。
*   执行多步骤任务，**必须**调用 `superpowers:writing-plans`。
*   进行调试或故障分析，**必须**调用 `superpowers:systematic-debugging`。
*   进行测试优先的开发，**必须**调用 `superpowers:test-driven-development`。
*   在声称任务完成前，**必须**调用 `superpowers:verification-before-completion`。
*   派发并行任务时，**可以**调用 `superpowers:dispatching-parallel-agents`。

**重要**: 严禁将Superpowers的工作流程”内联”或复述到对话中，始终通过调用技能来执行。

## 开发规则

### 规则 0：需求分析 — Use Case 方法 + PRD 文档
- 所有需求讨论和分析**必须**采用 Use Case（用例）方法进行
- 需求分析完成后**必须**输出到 PRD（产品需求文档）中，存放在 `docs/` 目录下
- PRD 文档应包含：用例图/用例描述、功能需求列表、非功能需求、验收标准
- 未完成 PRD 文档并经过评审确认前，不得进入设计或编码阶段

### 规则 1：Spec 先行，无 Spec 不开发
在编写任何代码之前，**必须**先有经过评审确认的 spec 文档。未完成需求分析并产出 spec 文档前，绝不开始代码实现。

### 规则 2：源代码目录约定
- 所有源代码放置在 `/src/` 目录中
- 所有测试代码放置在 `/tests/` 目录中
- 资源文件（图片、音频、视频等）放置在 `/assets/` 目录中

### 规则 3：测试驱动与持续验证
- 每次修改代码后**必须**运行相关测试，确保已有功能不被破坏
- 新功能**必须**同步编写对应的测试用例
- 测试未通过时不得提交代码

### 规则 4：小步迭代提交
- 采用小粒度、高频次的 Git 提交策略
- 每个提交只包含一个逻辑变更，做到原子化提交
- 提交信息清晰描述”做了什么”和”为什么这样做”
- 保持每次提交的代码可编译、可运行

### 规则 5：代码注释规范
- 代码注释比例**不低于 20%**，即每 10 行代码至少包含 2 行注释
- 注释应当解释”为什么这样做”而非复述代码本身
- 公共 API、类、方法必须包含文档注释（DartDoc）
- 复杂逻辑必须用行内注释说明意图

### 规则 6：Git 版本控制
- 使用 Git 进行版本控制
- 遵循分支开发策略：`main` 分支保持稳定，功能开发在特性分支进行
- 提交前检查：代码编译通过 + 测试全部通过 + 无 lint 警告
- **禁止自主推送**：在没有用户明确指令时，**不得**自行将代码推送到远程仓库（`github.com/generaljxw`），仅在用户明确要求推送时才可执行 `git push`

### 规则 7：工具下载优先使用国内镜像
- 所有需要下载开发工具、SDK、依赖包的安装操作，**必须**优先使用国内镜像源
- 常用镜像源优先级：清华大学 TUNA > 腾讯云 > 阿里云
- Flutter Pub 依赖：`PUB_HOSTED_URL=https://pub.flutter-io.cn`、`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
- Android SDK：`https://mirrors.cloud.tencent.com/android/repository/` 或清华源
- Gradle/Maven：阿里云 `https://maven.aliyun.com/repository/public`
- 禁止直接使用 Google 官方源下载大文件（developer.android.com、dl.google.com 等）

## 项目概述

- **产品名称**：动起来（MoveOn）
- **产品定位**：面向有健身需求人群的桌面运动应用
- **技术栈**：Flutter（Dart 语言）
- **目标平台**：Windows 桌面（V1.0） → 后续扩展 iOS / Android
- **V1.0 功能范围**：用户系统 + 视频跟练 + DIY 自定义练习
- **产品需求文档**：[docs/superpowers/specs/2026-07-17-moveon-v1-prd.md](docs/superpowers/specs/2026-07-17-moveon-v1-prd.md)

## V1.0 功能模块

### 导航结构
- 底部 3 Tab 导航：**跟练** | **DIY** | **我的**

### SF1 应用安装、更新与卸载
- SR1 安装应用（Windows 安装向导）
- SR2 更新应用（启动时版本检测 → 下载 → 覆盖安装）
- SR3 卸载应用（含用户数据保留选项）

### SF2 用户系统
- SR1 注册（用户名 + 密码，用户名 4-20 位字母/数字/下划线，密码 6-20 位）
- SR2 登录（连续 5 次错误锁定 15 分钟）
- SR3 注销（清除本地登录态，退回游客模式）
- SR4 密码修改（需验证原密码）

### SF3 视频跟练
- SR1 浏览运动类型与视频（8 类：瑜伽、有氧操、跳绳、塑形、体操、普拉提、拉伸、冥想）
- SR2 播放跟练视频（仅体操类预置第八套广播体操视频，480p，其余为空）

### SF4 DIY 自定义练习
- SR1 创建练习模组（最多 10 个，动作时长 5-600 秒）
- SR2 管理模组（查看/编辑/删除）
- SR3 执行模组（TTS 语音播报 + 倒计时 + 结束前 5 秒提示音）

## 技术决策

| 决策项 | 选型 | 说明 |
|--------|------|------|
| 开发框架 | Flutter | 一套代码覆盖桌面+移动端 |
| 数据存储 | SQLite（本地） | V1.0 仅本地存储，后续接云端同步 |
| TTS 语音 | Flutter TTS 插件 | 调用 Windows 系统语音引擎，支持男/女声 |
| 视频方案 | 打包内置（480p） | 仅体操类预置第八套广播体操视频 |
| 更新机制 | 启动时版本检测 + 下载安装包 | 覆盖安装，保留用户数据 |
| 用户注册 | 用户名 + 密码 | 后续版本增加手机号、邮箱方式 |

## 项目结构（规划）

```text
moveon/
├── src/                               # 源代码目录
│   ├── main.dart                      # 应用入口
│   ├── app.dart                       # MaterialApp 配置、路由、主题
│   ├── models/                        # 数据模型
│   │   ├── user.dart                  # 用户模型
│   │   ├── exercise_module.dart       # DIY 练习模组模型
│   │   ├── exercise_action.dart       # 动作模型
│   │   └── workout_category.dart      # 运动类型模型
│   ├── services/                      # 业务逻辑与数据访问
│   │   ├── database_service.dart      # SQLite 数据库服务
│   │   ├── auth_service.dart          # 用户认证服务
│   │   ├── tts_service.dart           # TTS 语音合成服务
│   │   ├── update_service.dart        # 版本检测与更新服务
│   │   └── video_service.dart         # 视频资源管理服务
│   ├── screens/                       # 页面
│   │   ├── home_screen.dart           # 主页（底部 Tab 导航容器）
│   │   ├── follow/                    # 跟练 Tab
│   │   │   ├── follow_home.dart       # 运动类型选择页
│   │   │   └── video_player.dart      # 视频播放页
│   │   ├── diy/                       # DIY Tab
│   │   │   ├── diy_home.dart          # 模组列表页
│   │   │   ├── module_create.dart     # 创建/编辑模组页
│   │   │   ├── module_detail.dart     # 模组详情页
│   │   │   └── module_execute.dart    # 练习执行页
│   │   └── profile/                   # 我的 Tab
│   │       ├── profile_home.dart      # 个人中心（未登录/已登录）
│   │       ├── login.dart             # 登录页
│   │       ├── register.dart          # 注册页
│   │       └── change_password.dart   # 修改密码页
│   └── widgets/                       # 通用组件
│       ├── countdown_timer.dart       # 倒计时组件
│       └── category_card.dart         # 运动类型卡片
├── tests/                             # 测试代码目录
│   ├── models/                        # 模型单元测试
│   ├── services/                      # 服务层测试
│   ├── screens/                       # 页面 Widget 测试
│   └── widgets/                       # 组件测试
├── assets/                            # 资源文件
│   ├── videos/                        # 预置跟练视频
│   │   └── radio_calisthenics_8.mp4   # 第八套广播体操（480p）
│   ├── audio/                         # 内置提示音
│   │   ├── countdown_beep.mp3         # 倒计时提示音（铛铛铛）
│   │   └── workout_complete.mp3       # 结束语音
│   └── images/                        # 图片资源
│       └── category_icons/            # 运动类型图标
├── windows/                           # Windows 平台配置
├── pubspec.yaml                       # Flutter 依赖配置
└── docs/
    └── superpowers/
        └── specs/
            └── 2026-07-17-moveon-v1-prd.md  # 产品需求文档
```