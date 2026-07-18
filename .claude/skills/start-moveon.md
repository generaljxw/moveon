---
name: start-moveon
description: 启动 MoveOn（动起来）桌面应用，用于开发验证。自动完成构建和启动，打开 Windows 窗口。
---

# Start MoveOn App

启动 MoveOn 桌面应用进行功能验证。

## 触发条件

用户说"启动应用"、"运行 MoveOn"、"打开应用验证"、"start MoveOn"等。

## 执行步骤

1. 设置 Flutter 环境变量和国内镜像：

```bash
export PATH="/c/flutter/bin:$PATH"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
```

2. 进入项目目录并启动 Windows 桌面应用：

```bash
cd "c:/ClaudeCode/02.MoveOn APP"
flutter run -d windows --debug
```

3. 应用启动后，终端显示 `Flutter run key commands` 提示，桌面出现 MoveOn 窗口。

## 停止应用

在终端中按 `q` 键退出应用。

## 注意事项

- 需要 Windows 开发者模式已开启
- 需要 Visual Studio 2022 + C++ 桌面开发工作负载
- 需要 NuGet（可在项目目录下找到 `nuget.exe`）
- 首次构建需要较长时间，后续启动会更快
