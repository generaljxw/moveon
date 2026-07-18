---
name: start-moveon
description: 启动 MoveOn（动起来）Flutter 桌面应用，用于开发调试和功能验证。当用户说"启动应用"、"运行 MoveOn"、"打开应用验证"、"start moveon"、"launch app"、"跑起来"时触发。自动配置 Flutter 环境并通过 flutter run -d windows 构建运行 Windows 桌面版。
---

# Start MoveOn App

启动 MoveOn（动起来）Flutter 桌面应用，用于功能验证和开发调试。

## 触发条件

当用户有以下意图时触发：
- "启动应用" / "运行 MoveOn" / "打开应用"
- "跑起来" / "启动一下" / "验证功能"
- "start moveon" / "launch app" / "run app"
- 任何想要看到应用运行效果的请求

## 前置检查

在启动前，先确认以下条件满足：

1. **Flutter 环境**：确认 `/c/flutter/bin/flutter` 可执行
2. **Windows 桌面设备**：`flutter devices` 输出中包含 `windows` 设备
3. **项目可编译**：`flutter analyze` 无 error（info/warning 不影响启动）

## 启动流程

### Step 1: 配置 Flutter 环境变量

```bash
export PATH="/c/flutter/bin:$PATH"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
```

- `FLUTTER_STORAGE_BASE_URL` 和 `PUB_HOSTED_URL` 使用国内镜像，加速依赖下载

### Step 2: 启动桌面应用

```bash
cd "c:/ClaudeCode/02.MoveOn APP"
flutter run -d windows --debug
```

- `-d windows`：指定 Windows 桌面为目标平台
- `--debug`：以 Debug 模式运行，支持热重载（Hot Reload）
- 首次构建需要 1-3 分钟，后续增量编译仅需几十秒
- 构建完成后 Windows 桌面自动弹出 MoveOn 应用窗口

### Step 3: 确认启动成功

终端显示以下信息表示成功：
```
Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).
```

同时桌面出现 MoveOn 应用窗口。

## 开发热重载

应用运行期间，修改 Dart 代码后：
- 按 `r` — 热重载（保留状态，秒级生效）
- 按 `R` — 热重启（重置状态，完全重载）
- 按 `q` — 退出应用

## 停止应用

- 在运行 `flutter run` 的终端中按 `q` 键
- 或直接关闭 MoveOn 应用窗口

## 故障排查

| 问题 | 解决方案 |
|------|----------|
| `flutter: command not found` | 确认 Flutter 安装在 `C:\flutter\`，或调整 PATH |
| `No windows desktop device found` | 运行 `flutter doctor` 检查 Windows 开发环境 |
| 构建失败（CMake/MSBuild 错误） | 确认 Visual Studio 2022 + C++ 桌面开发工作负载已安装 |
| 找不到视频/音频资源 | 确认 `assets/` 目录下的资源文件存在 |
| `sqflite_common_ffi` 相关错误 | 确认已运行 `flutter pub get` |
| 应用启动后闪退 | 检查 `flutter run` 终端输出的错误日志 |

## 环境要求

- **Flutter SDK** 3.x+（当前使用 3.44.6）
- **Visual Studio 2022** + "使用 C++ 的桌面开发"工作负载
- **Windows 10/11** + 开发者模式已启用
- 项目依赖已安装（`flutter pub get`）
