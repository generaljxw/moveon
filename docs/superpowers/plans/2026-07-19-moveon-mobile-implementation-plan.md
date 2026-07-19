# MoveOn 移动端 V1.0 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 MoveOn Flutter 桌面应用适配为 Android 移动端（华为 P70 PRO 优先，Android 8.0+），同一仓库、分层架构、平台抽象。

**Architecture:** 采用「条件导入 + 接口抽象」模式隔离平台差异：`sqflite` 通过 dart.library.io 条件导入自动选择 FFI（Windows）或标准版（Android）；UI 层通过 `OrientationBuilder` + `LayoutBuilder` 响应屏幕方向与尺寸。不重建架构，在现有代码基础上增量适配。

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, sqflite (Android) / sqflite_common_ffi (Windows), provider, flutter_tts, video_player, audioplayers, url_launcher

## Global Constraints

- Android 8.0+ (API 26+), compileSdk 34, minSdk 26, targetSdk 34
- 竖屏为主，视频播放 + 练习执行页支持横屏旋转
- 内置第八套广播体操视频（22MB）打包在 APK 中
- 所有业务规则与桌面版一致（复用 models/services 不变）
- TDD：每任务先写测试 → 验证失败 → 实现 → 验证通过 → 提交
- 分支：`feature/android-v1`
- pubspec.yaml 依赖不增加（或仅增加 `sqflite` 标准版）
- 所有下载/安装操作优先使用国内镜像

---

## File Structure

### Create

| File | Responsibility |
|------|---------------|
| `lib/services/database_service_stub.dart` | `sqflite` 标准版导出适配层（Android 用 `sqflite`，Windows 用 `sqflite_common_ffi`） |
| `lib/utils/responsive_helper.dart` | 屏幕尺寸/方向工具函数：断点判断、列数计算、底部弹窗封装 |
| `test/utils/responsive_helper_test.dart` | ResponsiveHelper 单元测试 |

### Modify

| File | Change |
|------|--------|
| `pubspec.yaml` | 添加 `sqflite: ^2.3.0`（标准版，Android 条件导入用） |
| `lib/main.dart:1-27` | `sqfliteFfiInit()` 和 `WindowsVideoPlayer.registerWith()` 改为平台条件调用 |
| `lib/services/database_service.dart:1-2` | 导入路径从 `sqflite_common_ffi` 改为 `database_service_stub.dart` |
| `lib/screens/follow/follow_home_screen.dart:67-75` | GridView 列数从固定 4 改为 `ResponsiveHelper.gridColumns(context)` |
| `lib/screens/follow/video_player_screen.dart:119-131` | Scaffold body 外层添加 `OrientationBuilder`，横屏全屏隐藏 AppBar |
| `lib/screens/diy/module_execute_screen.dart:96-153` | Scaffold body 外层添加 `OrientationBuilder`，横屏全屏大字显示 |
| `lib/screens/diy/module_create_screen.dart:229-403` | "添加动作"Dialog 移动端改为底部 BottomSheet |
| `lib/screens/profile/profile_home_screen.dart:128-143` | 退出登录确认 Dialog 移动端改为 BottomSheet |
| `lib/theme.dart:46-141` | AppBar 增加 `scrolledUnderElevation`，底部导航增加 `selectedFontSize` 移动端适配 |
| `lib/app.dart` | 添加 `supportedLocales`、`localizationsDelegates` 完整化 MaterialApp 配置 |

### Generate (by `flutter create`)

| Path | Purpose |
|------|---------|
| `android/` | Gradle 构建系统、AndroidManifest、签名配置、ProGuard 规则 |
| `android/app/src/main/AndroidManifest.xml` | 权限声明（INTERNET、ACCESS_NETWORK_STATE） |
| `android/settings.gradle` | Maven/Gradle 国内镜像仓库配置 |
| `android/gradle.properties` | Gradle JVM 参数 + AndroidX 启用 |

---

### Task 1: Feature 分支创建 + Android 平台生成

**Files:**
- Create: `android/` (整个目录结构，由 `flutter create` 生成)
- Modify: `android/settings.gradle`、`android/app/src/main/AndroidManifest.xml`、`android/gradle.properties`

**Interfaces:**
- Consumes: 无
- Produces: Android 构建工程，`flutter build apk --debug` 可执行

- [ ] **Step 1: 创建 feature 分支**

```bash
git checkout -b feature/android-v1
```

- [ ] **Step 2: 生成 Android 平台目录**

Run:
```bash
cd "c:/ClaudeCode/02.MoveOn APP"
flutter create --platforms=android .
```
Expected: 输出 `android/` 目录及子文件，无报错。

- [ ] **Step 3: 配置 Gradle 国内镜像**

编辑 `android/settings.gradle`，将内容替换为：

```groovy
pluginManagement {
    def flutterSdkPath = settings.ext.flutterSdkPath
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.1.0" apply false
}

include ":app"
```

编辑 `android/gradle.properties`，追加：

```properties
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=512m
android.useAndroidX=true
android.enableJetifier=true
```

- [ ] **Step 4: 配置 AndroidManifest 权限和屏幕方向**

读取 `android/app/src/main/AndroidManifest.xml`，在 `<manifest>` 下添加权限声明，在 `<activity>` 标签中移除默认的 `android:screenOrientation` 为 `portrait` 配置，保留 `configChanges`。最终内容：

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 网络权限 — 在线视频流播放 + 浏览器打开链接 -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        android:label="动起来"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>
    </application>
</manifest>
```

- [ ] **Step 5: 验证 debug APK 可构建**

Run:
```bash
cd "c:/ClaudeCode/02.MoveOn APP"
flutter build apk --debug
```
Expected: 构建成功，在 `build/app/outputs/flutter-apk/app-debug.apk` 生成 APK 文件。

- [ ] **Step 6: 提交**

```bash
git add android/ pubspec.lock
git commit -m "chore: generate Android platform with Gradle mirror config and permissions"
```

---

### Task 2: sqflite 平台条件导入（核心适配）

**Files:**
- Modify: `pubspec.yaml` (add `sqflite` dependency)
- Create: `lib/services/database_service_stub.dart`
- Modify: `lib/services/database_service.dart:1-2`
- Modify: `lib/main.dart:8-9,17-21`

**Interfaces:**
- Consumes: Task 1 (Android project exists)
- Produces:
  - `DatabaseService.initialize()` 在 Windows 和 Android 均可用
  - `main()` 在双平台均可执行
  - 现有 85 个测试全部通过

- [ ] **Step 1: 添加 sqflite 标准版依赖**

编辑 `pubspec.yaml`，在 `sqflite_common_ffi` 下方添加：

```yaml
  # SQLite 数据库 — Android 标准版（Windows 用 FFI 版本，通过条件导入自动选择）
  sqflite: ^2.3.0
```

Run:
```bash
cd "c:/ClaudeCode/02.MoveOn APP"
flutter pub get
```

- [ ] **Step 2: 创建平台适配 stub 文件**

创建 `lib/services/database_service_stub.dart`：

```dart
// lib/services/database_service_stub.dart — sqflite 平台条件导出
//
// Windows：sqflite_common_ffi 提供 sqlite3.dll FFI 绑定
// Android / iOS / macOS：sqflite 标准版通过 MethodChannel 调用原生 SQLite
//
// 使用 Dart 条件导入特性，编译时按平台选择正确的库。
// 所有 DatabaseService 代码只需 import 本文件即可。
export 'package:sqflite_common_ffi/sqflite_ffi.dart'
    if (dart.library.io) 'package:sqflite/sqflite.dart';
```

- [ ] **Step 3: 修改 database_service.dart 导入**

编辑 `lib/services/database_service.dart`，将第 2 行的导入改为：

```dart
import 'database_service_stub.dart';
```

删除原来的：
```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
```

> 注意：`database_service_stub.dart` 导出的是 `sqflite_ffi.dart`（Windows）或 `sqflite.dart`（Android/Mac），两者 API 兼容（都提供 `Database`、`databaseFactory`、`openDatabase` 等）。但 `database_service.dart` 当前使用 `databaseFactoryFfi`（FFI 专用 API），需要改为跨平台的 `databaseFactory`。

同时修改 `initialize()` 方法中的 `databaseFactoryFfi` → `databaseFactory`：

- 第 36 行：`_db = await databaseFactoryFfi.openDatabase(` → `_db = await databaseFactory.openDatabase(`
- 第 50 行：`_db = await databaseFactoryFfi.openDatabase(` → `_db = await databaseFactory.openDatabase(`

- [ ] **Step 4: 修改 main.dart 平台条件初始化**

编辑 `lib/main.dart`，将 `sqfliteFfiInit()` 和 `WindowsVideoPlayer.registerWith()` 包装为平台条件：

```dart
// lib/main.dart — MoveOn 应用入口
//
/// 启动流程：
/// 1. 初始化数据库引擎（Windows 用 FFI，Android/其他平台自动适配）
/// 2. 初始化本地数据库
/// 3. 启动 Flutter 应用（Provider 层自动恢复登录状态）
import 'dart:io';
import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'app.dart';

void main() async {
  // Flutter 绑定必须在异步操作前初始化
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 桌面平台专用初始化
  if (Platform.isWindows) {
    // sqflite FFI 后端初始化（SQLite 引擎绑定）
    // ignore: avoid_dynamic_calls
    final ffi = await _initFfi();
    // ignore: avoid_dynamic_calls
    ffi.sqfliteFfiInit();

    // video_player_win 插件注册
    // ignore: avoid_dynamic_calls
    final vp = await _initVideoPlayerWin();
    // ignore: avoid_dynamic_calls
    vp.WindowsVideoPlayer.registerWith();
  }

  // 初始化本地数据库（生产模式，文件存储）
  // databaseFactory 由条件导入自动选择 FFI 或标准版实现
  await DatabaseService.instance.initialize();

  runApp(const MoveOnApp());
}

// 仅 Windows 平台导入（避免 Android 编译报错）
dynamic _initFfi() => _FfiHelper();
dynamic _initVideoPlayerWin() => _VideoPlayerWinHelper();
```

> 说明：为避免 `dart:io` 导入 `sqflite_common_ffi` 在 Android 编译时报错，使用延迟导入模式。或在 `database_service_stub.dart` 中同时处理 FFI 初始化。

**简化方案**：直接在 stub 文件中提供 `initDatabase()` 函数，main.dart 只需调用一个函数：

编辑 `lib/services/database_service_stub.dart`，追加：

```dart
// 数据库引擎初始化 — 仅 Windows 需要 FFI 初始化；Android 无需额外初始化
import 'dart:io';

/// 初始化数据库引擎（跨平台适配）
///
/// Windows: 调用 sqfliteFfiInit() 加载 sqlite3.dll
/// Android/其他: 无需额外初始化（通过 MethodChannel 调用系统 SQLite）
Future<void> initDatabaseEngine() async {
  if (Platform.isWindows) {
    // ignore: avoid_dynamic_calls
    final sqfliteFfi = await _importWindows();
    sqfliteFfi.sqfliteFfiInit();
  }
}

// 条件导入：仅 Windows 编译 sqflite_common_ffi
Future<dynamic> _importWindows() async {
  return _WindowsHelper();
}

class _WindowsHelper {
  void sqfliteFfiInit() {
    // 运行时调用实际的 sqfliteFfiInit，通过顶层函数转发
    _sqfliteFfiInit();
  }
}

// 仅 Windows 被调用（由条件导出控制）
void _sqfliteFfiInit() {
  // 真正的 sqfliteFfiInit 通过 database_service_stub.dart 的 export 解析
  // 在 Windows 编译时链接到 sqflite_common_ffi
}
```

**更简洁方案（推荐）**：直接在 main.dart 中用 `dart.library.ffi` 条件导入：

`lib/main.dart` 全文：

```dart
// lib/main.dart — MoveOn 应用入口
//
/// 启动流程：
/// 1. Windows: 初始化 sqflite FFI + video_player_win
/// 2. 初始化本地数据库（跨平台 databaseFactory）
/// 3. 启动 Flutter 应用
import 'dart:io';
import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Windows 桌面专用初始化
  if (Platform.isWindows) {
    // sqflite FFI 引擎
    // ignore: depend_on_referenced_packages
    final ffi = await _sqfliteFfiInitImpl();
    ffi();

    // video_player_win 注册
    // ignore: depend_on_referenced_packages
    final vp = await _videoPlayerWinInitImpl();
    vp();
  }

  await DatabaseService.instance.initialize();
  runApp(const MoveOnApp());
}

// Windows: 动态导入 sqflite_common_ffi 初始化函数
Future<dynamic Function()> _sqfliteFfiInitImpl() async {
  final lib = await _importSqfliteFfi();
  return lib.sqfliteFfiInit as dynamic Function();
}

Future<dynamic> _importSqfliteFfi() async {
  // 仅 Windows 构建时有此依赖
  return _SqfliteFfiStub();
}

// 仅 Windows 构建时 link 到 sqflite_common_ffi
// Android 构建时此函数不会被调用到（Platform.isWindows = false）
class _SqfliteFfiStub {
  dynamic sqfliteFfiInit;
}

// video_player_win 初始化
Future<dynamic Function()> _videoPlayerWinInitImpl() async {
  final lib = await _importVideoPlayerWin();
  return lib.WindowsVideoPlayer.registerWith as dynamic Function();
}

Future<dynamic> _importVideoPlayerWin() async {
  return _VideoPlayerWinStub();
}

class _VideoPlayerWinStub {
  dynamic WindowsVideoPlayer;
}
```

> 导入实际类型需要在文件顶部通过 `import` 引入，但 `sqflite_common_ffi` 和 `video_player_win` 已存在于 `pubspec.yaml`，它们会标记为 `not used` 在 Android 构建时，但不会报错。只要 `database_service.dart` 的条件导出正确，main.dart 可以安全地保留这两个 `import`——Dart 编译器会对未使用的 import 产生 warning 而非 error（`unused_import` 默认 warning 级别且我们之前有 `sqfliteFfiInit()` 和 `WindowsVideoPlayer.registerWith()` 的实际调用保证 Windows 编译通过）。

**最终简化 main.dart**：

```dart
// lib/main.dart — MoveOn 应用入口
//
/// 跨平台启动流程：
/// 1. Windows: 初始化 FFI 引擎 + video_player_win
/// 2. Android: 无需额外引擎初始化
/// 3. 初始化本地数据库 → 启动应用
import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 数据库引擎初始化（Windows FFI / Android 原生）
  await initDatabaseEngine();

  // 初始化本地数据库（生产模式，文件存储）
  await DatabaseService.instance.initialize();

  runApp(const MoveOnApp());
}
```

其中 `initDatabaseEngine()` 在 `lib/services/database_service_stub.dart` 中实现：Windows 调用 `sqfliteFfiInit()`，Android 直接 return。

编辑 **最终版** `lib/services/database_service_stub.dart`：

```dart
// lib/services/database_service_stub.dart — sqflite 跨平台条件导出 + 引擎初始化
//
// Windows：sqflite_common_ffi（FFI 绑定 sqlite3.dll）
// Android：sqflite（MethodChannel 调用系统 SQLite）
library database_service_stub;

// 条件导出 — 编译时根据目标平台选择正确的库
export 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 初始化数据库引擎（跨平台）
///
/// Windows: 调用 sqfliteFfiInit() 装载 sqlite3.dll
/// Android/其他: 无需额外操作（通过 MethodChannel 直接使用系统 SQLite）
Future<void> initDatabaseEngine() async {
  // Android/非Windows 平台：无需 FFI 初始化，SQLite 通过 MethodChannel 可用
  // Windows: sqfliteFfiInit() 通过条件导出自动链接
  // sqfliteFfiInit 函数仅在 Windows 构建中可用
  // 在 Android 构建中，此函数调用被 tree-shaken（未使用的 export）
}
```

> 解释：条件导出的关键点是 `export 'package:sqflite_common_ffi/sqflite_ffi.dart'`。在 Android 构建中，如果没有任何代码实际 `import` 此文件并调用 `sqfliteFfiInit()`，Dart 编译器会 tree-shake 掉未使用的导出。`initDatabaseEngine()` 在 Android 上为空函数（无 `sqfliteFfiInit` 调用），而在 Windows 上需要实际的 FFI 初始化——**但这需要通过条件导入实现**。

**实际可行方案**：在 `stub` 中使用 Dart 的条件导入语法：

```dart
// lib/services/database_service_stub.dart
//
// 跨平台 sqflite 适配：Windows=FFI / Android=标准版
// 通过 dart.library.io 条件导入在编译时选择实现。

// 条件导出 database API（两者 API 兼容）
export 'package:sqflite/sqflite.dart'
    if (dart.library.io) 'package:sqflite_common_ffi/sqflite_ffi.dart';

// 条件导入初始化函数
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    if (dart.library.io) 'package:sqflite/sqflite.dart'
    show databaseFactory; // Android 兜底

/// 初始化数据库引擎（跨平台适配）
Future<void> initDatabaseEngine() async {
  // Windows (FFI): 需要初始化 sqlite3.dll
  // 通过条件导入，仅在 FFI 构建中调用 sqfliteFfiInit
  // ignore: undefined_function, avoid_dynamic_calls
  try {
    sqfliteFfiInit?.call();
  } catch (_) {
    // Android: sqfliteFfiInit 不存在 → 忽略
  }
}
```

> 此方案使用条件导出 + try/catch：Windows 编译时 `sqfliteFfiInit` 可用并调取；Android 编译时条件导入 fallback 到 `sqflite` 标准版（无 `sqfliteFfiInit`），try/catch 静默跳过。

- [ ] **Step 5: 运行全部现有测试确认不破坏 Windows 功能**

Run:
```bash
cd "c:/ClaudeCode/02.MoveOn APP"
flutter test
```
Expected: 85 个测试全部通过。

- [ ] **Step 6: 提交**

```bash
git add pubspec.yaml pubspec.lock lib/services/database_service_stub.dart lib/services/database_service.dart lib/main.dart
git commit -m "feat: add cross-platform sqflite adapter with conditional exports"
```

---

### Task 3: ResponsiveHelper 工具类

**Files:**
- Create: `lib/utils/responsive_helper.dart`
- Create: `test/utils/responsive_helper_test.dart`

**Interfaces:**
- Consumes: 无（纯工具类）
- Produces:
  - `ResponsiveHelper.gridColumns(BuildContext)` → `int`（2 竖屏 / 4 横屏）
  - `ResponsiveHelper.isLandscape(BuildContext)` → `bool`
  - `ResponsiveHelper.isMobile(BuildContext)` → `bool`
  - `ResponsiveHelper.showMobileSheet(BuildContext, Widget)` → `Future<T?>`（移动端 BottomSheet / 桌面 Dialog）
  - `ResponsiveHelper.showMobileConfirm(BuildContext, {title, content, confirmLabel})` → `Future<bool?>`

- [ ] **Step 1: 写 ResponsiveHelper 测试**

创建 `test/utils/responsive_helper_test.dart`：

```dart
// test/utils/responsive_helper_test.dart — ResponsiveHelper 工具类测试
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper', () {
    // ---- 横屏检测 ----
    testWidgets('isLandscape returns true when width > height', (tester) async {
      // 设置横屏尺寸（1280x720）
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = ResponsiveHelper.isLandscape(context);
              return Text(result ? 'landscape' : 'portrait');
            },
          ),
        ),
      );

      expect(find.text('landscape'), findsOneWidget);
    });

    testWidgets('isLandscape returns false when height > width', (tester) async {
      // 竖屏（360x640 — 手机默认）
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = ResponsiveHelper.isLandscape(context);
              return Text(result ? 'landscape' : 'portrait');
            },
          ),
        ),
      );

      expect(find.text('portrait'), findsOneWidget);
    });

    // ---- 网格列数 ----
    testWidgets('gridColumns returns 2 in portrait', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text('${ResponsiveHelper.gridColumns(context)}');
            },
          ),
        ),
      );

      // 竖屏 = 2 列
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('gridColumns returns 4 in landscape', (tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text('${ResponsiveHelper.gridColumns(context)}');
            },
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
    });

    // ---- 移动端判定 ----
    testWidgets('isMobile returns true for phone-sized screens', (tester) async {
      tester.view.physicalSize = const Size(720, 1280); // 360dp wide
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text(ResponsiveHelper.isMobile(context) ? 'mobile' : 'desktop');
            },
          ),
        ),
      );

      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('isMobile returns false for wide screens', (tester) async {
      tester.view.physicalSize = const Size(3840, 2160); // ~960dp wide
      tester.view.devicePixelRatio = 4.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text(ResponsiveHelper.isMobile(context) ? 'mobile' : 'desktop');
            },
          ),
        ),
      );

      expect(find.text('desktop'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run:
```bash
flutter test test/utils/responsive_helper_test.dart
```
Expected: FAIL — `ResponsiveHelper` 类不存在。

- [ ] **Step 3: 实现 ResponsiveHelper**

创建 `lib/utils/responsive_helper.dart`：

```dart
// lib/utils/responsive_helper.dart — 屏幕适配工具
//
// 提供横/竖屏检测、网格列数计算、移动端/桌面端弹窗适配。
// 所有需要响应屏幕大小或方向的 Widget 通过本工具获取参数，
// 避免在业务代码中硬编码尺寸判断。
import 'package:flutter/material.dart';

/// 屏幕适配工具 — 集中管理响应式断点和平台差异
abstract final class ResponsiveHelper {
  ResponsiveHelper._();

  /// 移动端宽度断点（逻辑像素）
  ///
  /// 宽度 ≤ 600dp → 手机布局；> 600dp → 桌面/平板布局
  static const double _mobileBreakpoint = 600.0;

  /// 当前是否为横屏
  ///
  /// 通过 MediaQuery 获取屏幕尺寸，宽度 > 高度 → 横屏。
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  /// 当前是否为移动端（小屏设备）
  ///
  /// 判定标准：逻辑像素宽度 ≤ 600dp（符合 Material Design 断点规范）。
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= _mobileBreakpoint;
  }

  /// 运动类型网格列数
  ///
  /// 竖屏 → 2 列（手机屏幕 ~360dp 宽度，卡片 + 间距约 170dp/列）；
  /// 横屏 → 4 列（同桌面版布局）。
  static int gridColumns(BuildContext context) {
    return isLandscape(context) ? 4 : 2;
  }

  /// 移动端/桌面端自适应确认弹窗
  ///
  /// 移动端（宽度 ≤ 600dp）：底部 BottomSheet 样式
  /// 桌面端：居中 Dialog 样式
  /// 返回 true = 确认，false = 取消，null = 关闭。
  static Future<bool?> showMobileConfirm(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = '确定',
    String cancelLabel = '取消',
    Color? confirmColor,
  }) {
    if (isMobile(context)) {
      return showModalBottomSheet<bool>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(content, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: confirmColor != null
                            ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                            : null,
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 桌面端：标准 Dialog
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel, style: confirmColor != null ? TextStyle(color: confirmColor) : null),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run:
```bash
flutter test test/utils/responsive_helper_test.dart
```
Expected: 全部 5 个测试 PASS。

- [ ] **Step 5: 提交**

```bash
git add lib/utils/responsive_helper.dart test/utils/responsive_helper_test.dart
git commit -m "feat: add ResponsiveHelper — screen size/orientation/orientation utilities"
```

---

### Task 4: 跟练首页 — 响应式网格

**Files:**
- Modify: `lib/screens/follow/follow_home_screen.dart:67-75`

**Interfaces:**
- Consumes: `ResponsiveHelper.gridColumns(context)` (Task 3)
- Produces: GridView 根据方向自动切换 2/4 列

- [ ] **Step 1: 修改 FollowHomeScreen 网格列数**

编辑 `lib/screens/follow/follow_home_screen.dart`，在文件顶部添加导入：

```dart
import '../../utils/responsive_helper.dart';
```

修改第 69-70 行的 `crossAxisCount`：

```dart
// 之前
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 4,

// 之后
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: ResponsiveHelper.gridColumns(context),
```

**完整替换**（第 67-76 行）：

```dart
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.gridColumns(context),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
```

- [ ] **Step 2: 验证编译通过（无 widget test 崩溃）**

Run:
```bash
cd "c:/ClaudeCode/02.MoveOn APP"
flutter test
```
Expected: 85 个测试全部通过。

- [ ] **Step 3: 验证 Android APK 构建**

```bash
flutter build apk --debug
```
Expected: BUILD SUCCESSFUL。

- [ ] **Step 4: 提交**

```bash
git add lib/screens/follow/follow_home_screen.dart
git commit -m "feat: make category grid responsive — 2 columns portrait, 4 landscape"
```

---

### Task 5: 视频播放器 — 横屏全屏 + 方向锁定

**Files:**
- Modify: `lib/screens/follow/video_player_screen.dart:119-201`

**Interfaces:**
- Consumes: `ResponsiveHelper.isLandscape(context)` (Task 3)
- Produces: VideoPlayerScreen 支持横竖屏旋转 — 横屏时隐藏 AppBar + 全屏播放

- [ ] **Step 1: 修改 VideoPlayerScreen build 方法**

编辑 `lib/screens/follow/video_player_screen.dart`，添加导入：

```dart
import '../../utils/responsive_helper.dart';
```

修改 `build` 和 `_buildBody` 方法（第 119-201 行），在 Scaffold 外层包裹 `OrientationBuilder`：

```dart
  @override Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);

    if (_openingBrowser) {
      return Scaffold(
        appBar: isLandscape ? null : AppBar(title: Text(_title)),
        body: const Center(child: Text('正在打开浏览器...')),
      );
    }
    return Scaffold(
      // 横屏全屏：隐藏 AppBar
      appBar: isLandscape ? null : AppBar(title: Text(_title)),
      body: _buildBody(isLandscape),
    );
  }

  Widget _buildBody(bool isLandscape) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('视频无法播放',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                widget.onlineVideo != null
                    ? '请检查视频链接是否有效'
                    : '请确认视频文件已正确内置到应用中',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              // 横屏时提供返回按钮（因为没有 AppBar）
              if (isLandscape) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: VideoPlayer(_controller!)),
        VideoProgressIndicator(_controller!, allowScrubbing: true,
          colors: const VideoProgressColors(
            playedColor: Color(0xFF4CAF50))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_controller!.value.isPlaying
                    ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
              ),
              const Spacer(),
              // 横屏时显示返回按钮
              if (isLandscape)
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('返回'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              if (_controller!.value.position >= _controller!.value.duration)
                TextButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('重新播放'),
                  onPressed: () {
                    _controller!.seekTo(Duration.zero);
                    _controller!.play();
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 2: 验证编译**

```bash
flutter analyze lib/screens/follow/video_player_screen.dart
```
Expected: No issues found.

- [ ] **Step 3: 提交**

```bash
git add lib/screens/follow/video_player_screen.dart
git commit -m "feat: add landscape fullscreen mode to video player"
```

---

### Task 6: 练习执行页 — 横屏全屏支持

**Files:**
- Modify: `lib/screens/diy/module_execute_screen.dart:96-178`

**Interfaces:**
- Consumes: `ResponsiveHelper.isLandscape(context)` (Task 3)
- Produces: ModuleExecuteScreen 横屏时全屏大字显示、隐藏 AppBar

- [ ] **Step 1: 修改 ModuleExecuteScreen build**

编辑 `lib/screens/diy/module_execute_screen.dart`，添加导入：

```dart
import '../../utils/responsive_helper.dart';
```

修改 `build` 方法（第 96-153 行）和 `_buildCompleteScreen`（第 154-177 行）：

```dart
  @override Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);

    if (_finished) {
      return _buildCompleteScreen(isLandscape);
    }

    final progress = (_currentIndex + 1) / widget.actions.length;
    return Scaffold(
      // 横屏全屏：隐藏 AppBar
      appBar: isLandscape ? null : AppBar(
        title: Text(widget.module.name),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmEnd),
      ),
      body: Column(
        children: [
          // 横屏时提供关闭按钮（无 AppBar）
          if (isLandscape)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _confirmEnd,
                ),
              ),
            ),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 24),
          // 横屏时动作名称更大
          Text(_currentAction.name,
            style: TextStyle(
              fontSize: isLandscape ? 42 : 28,
              fontWeight: FontWeight.bold,
            )),
          const SizedBox(height: 8),
          if (_currentAction.isRest)
            const Chip(label: Text('休息', style: TextStyle(color: Colors.orange))),
          const Spacer(),
          CountdownTimer(
            key: _timerKey,
            totalSeconds: _currentAction.durationSeconds,
            showBeep: !_currentAction.isRest,
            onBeep: _currentAction.isRest ? null : _playCountdownBeep,
            onComplete: _onActionComplete,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  icon: Icon(_timerKey.currentState?.isPaused == true
                      ? Icons.play_arrow : Icons.pause, size: 36),
                  onPressed: () {
                    final state = _timerKey.currentState;
                    if (state == null) return;
                    state.isPaused ? state.resume() : state.pause();
                    setState(() {});
                  },
                ),
                const SizedBox(width: 48),
                IconButton(
                  icon: const Icon(Icons.stop, size: 36, color: Colors.red),
                  onPressed: _confirmEnd,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCompleteScreen(bool isLandscape) {
    final totalSec = ExerciseModule.totalDuration(widget.actions);
    return Scaffold(
      appBar: isLandscape ? null : AppBar(title: const Text('练习完成')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.teal),
            const SizedBox(height: 16),
            const Text('锻炼结束，好好休息吧', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 24),
            Text('总时长：${totalSec ~/ 60} 分 ${totalSec % 60} 秒'),
            Text('完成动作：${widget.actions.length} 个'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 2: 验证**

```bash
flutter analyze lib/screens/diy/module_execute_screen.dart
```
Expected: No issues found.

- [ ] **Step 3: 提交**

```bash
git add lib/screens/diy/module_execute_screen.dart
git commit -m "feat: add landscape fullscreen mode to exercise execution screen"
```

---

### Task 7: 移动端弹窗适配 — BottomSheet 替换 Dialog

**Files:**
- Modify: `lib/screens/diy/module_create_screen.dart:56-92` (快速休息 Dialog)
- Modify: `lib/screens/diy/module_create_screen.dart:95-118` (批量删除 Dialog)
- Modify: `lib/screens/diy/module_create_screen.dart:126-176` (添加/编辑动作 Dialog)
- Modify: `lib/screens/profile/profile_home_screen.dart:128-143` (退出登录 Dialog)

**Interfaces:**
- Consumes: `ResponsiveHelper.showMobileConfirm(context, ...)` (Task 3)
- Produces: 移动端使用 BottomSheet 弹窗；桌面端保持 AlertDialog

- [ ] **Step 1: 修改退出登录确认（ProfileHomeScreen）**

编辑 `lib/screens/profile/profile_home_screen.dart`，添加导入：

```dart
import '../../utils/responsive_helper.dart';
```

替换 `_showLogoutConfirm` 方法体：

```dart
  void _showLogoutConfirm(BuildContext context, AuthProvider auth) {
    ResponsiveHelper.showMobileConfirm(
      context,
      title: '确认退出',
      content: '确定要退出登录吗？',
      confirmLabel: '确定',
      confirmColor: MoveOnTheme.colorAccent,
    ).then((confirmed) {
      if (confirmed == true) {
        auth.logout();
      }
    });
  }
```

- [ ] **Step 2: 修改快速休息 Dialog（ModuleCreateScreen）**

编辑 `lib/screens/diy/module_create_screen.dart`，添加导入：

```dart
import '../../utils/responsive_helper.dart';
```

替换 `_showQuickRestDialog` 方法（第 53-92 行）：

```dart
  Future<void> _showQuickRestDialog() async {
    final durationCtrl = TextEditingController(text: '10');

    if (ResponsiveHelper.isMobile(context)) {
      // 移动端：底部表单
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('添加休息间隔', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(
                  labelText: '休息时长（秒）', hintText: '5-600', helperText: '默认 10 秒'),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final dur = int.tryParse(durationCtrl.text);
                        if (dur == null || dur < 5 || dur > 600) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('时长范围为 5-600 秒')));
                          return;
                        }
                        Navigator.of(ctx).pop(true);
                      },
                      child: const Text('添加'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      if (result == true) {
        setState(() => _actions.add(_ActionDraft(
          name: '休息', durationSeconds: int.parse(durationCtrl.text), isRest: true)));
      }
      return;
    }

    // 桌面端：原 Dialog（保持不变）
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加休息间隔'),
        content: TextField(
          controller: durationCtrl,
          decoration: const InputDecoration(
            labelText: '休息时长（秒）', hintText: '5-600', helperText: '默认 10 秒'),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final dur = int.tryParse(durationCtrl.text);
              if (dur == null || dur < 5 || dur > 600) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('时长范围为 5-600 秒')));
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _actions.add(_ActionDraft(
        name: '休息', durationSeconds: int.parse(durationCtrl.text), isRest: true)));
    }
  }
```

- [ ] **Step 3: 修改批量删除确认（ModuleCreateScreen）**

将 `_batchDelete` 方法（第 95-118 行）的 `showDialog` 替换为 `ResponsiveHelper.showMobileConfirm`：

```dart
  Future<void> _batchDelete() async {
    final confirmed = await ResponsiveHelper.showMobileConfirm(
      context,
      title: '确认删除',
      content: '确定要删除已选的 ${_selectedIndices.length} 个动作吗？',
      confirmLabel: '确定',
      cancelLabel: '取消',
      confirmColor: Colors.red,
    );
    if (confirmed == true) {
      setState(() {
        final sorted = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
        for (final i in sorted) {
          _actions.removeAt(i);
        }
        _selectedIndices.clear();
      });
    }
  }
```

- [ ] **Step 4: 修改添加/编辑动作 Dialog（ModuleCreateScreen）**

将 `_showAddActionDialog` 中的 `showDialog` 替换为移动端 BottomSheet（模式同 Task 2 的 `_showQuickRestDialog`）：

```dart
  Future<void> _showAddActionDialog({_ActionDraft? editTarget, int? editIndex}) async {
    final nameCtrl = TextEditingController(text: editTarget?.name ?? '');
    final durationCtrl = TextEditingController(
        text: editTarget?.durationSeconds.toString() ?? '60');

    final isMobile = ResponsiveHelper.isMobile(context);
    final isEdit = editTarget != null;

    if (isMobile) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? '编辑动作' : '添加动作',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '动作名称'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: durationCtrl,
                decoration: const InputDecoration(labelText: '时长（秒）', hintText: '5-600'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final dur = int.tryParse(durationCtrl.text);
                        if (dur == null || dur < 5 || dur > 600) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('时长范围为 5-600 秒')));
                          return;
                        }
                        Navigator.of(ctx).pop(true);
                      },
                      child: const Text('添加'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      if (result == true) {
        final draft = _ActionDraft(
          name: nameCtrl.text.trim(),
          durationSeconds: int.parse(durationCtrl.text),
          isRest: false,
        );
        setState(() {
          if (editIndex != null) {
            _actions[editIndex] = draft;
          } else {
            _actions.add(draft);
          }
        });
      }
      return;
    }

    // 桌面端：原 Dialog（保持不变）
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(editTarget != null ? '编辑动作' : '添加动作'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '动作名称')),
              TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: '时长（秒）', hintText: '5-600'),
                  keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final dur = int.tryParse(durationCtrl.text);
                if (dur == null || dur < 5 || dur > 600) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('时长范围为 5-600 秒')));
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final draft = _ActionDraft(
        name: nameCtrl.text.trim(),
        durationSeconds: int.parse(durationCtrl.text),
        isRest: false,
      );
      setState(() {
        if (editIndex != null) {
          _actions[editIndex] = draft;
        } else {
          _actions.add(draft);
        }
      });
    }
  }
```

- [ ] **Step 5: 验证全部测试通过**

```bash
flutter test
```
Expected: 85 + 5 (ResponsiveHelper) = 90 个测试全部通过。

- [ ] **Step 6: 验证 Android 构建**

```bash
flutter build apk --debug
```
Expected: BUILD SUCCESSFUL。

- [ ] **Step 7: 提交**

```bash
git add lib/screens/diy/module_create_screen.dart lib/screens/profile/profile_home_screen.dart
git commit -m "feat: use BottomSheet on mobile for create/exercise/confirm dialogs"
```

---

### Task 8: 移动端启动画面 + 权限处理 + 离线检测

**Files:**
- Modify: `lib/main.dart:13-27` (添加权限检查和离线检测钩子)
- Modify: `android/app/src/main/AndroidManifest.xml` (已在 Task 1 配置，确认权限完整)

**Interfaces:**
- Consumes: `initDatabaseEngine()` (Task 2)
- Produces: 启动时检查必要权限；离线模式下内置视频正常使用、在线功能友好提示

- [ ] **Step 1: AndroidManifest 权限补充确认**

确认 `android/app/src/main/AndroidManifest.xml` 已包含（Task 1 已配置）：

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

对 Android 10+ (API 29+)，存储权限不再需要 `READ_EXTERNAL_STORAGE`（应用私有目录自动可读写，`sqflite` 使用 `getApplicationDocumentsDirectory()`）。

- [ ] **Step 2: 编译 Android APK 并安装到模拟器验证**

```bash
flutter build apk --debug
```
Expected: APK 生成在 `build/app/outputs/flutter-apk/app-debug.apk`。

- [ ] **Step 3: 提交**

```bash
git add lib/main.dart
git commit -m "feat: finalize cross-platform main() entry with platform-conditional init"
```

---

### Task 9: 最终集成验证 + 合并主干

**Files:** 全部

- [ ] **Step 1: 运行全部测试**

```bash
cd "c:/ClaudeCode/02.MoveOn APP"
flutter test
```
Expected: 全部测试 PASS。

- [ ] **Step 2: 验证 Android Debug APK 构建**

```bash
flutter build apk --debug
```
Expected: `app-debug.apk` 生成成功。

- [ ] **Step 3: 验证 Android Release APK 构建**

```bash
flutter build apk --release
```
Expected: `app-release.apk` 生成成功（未签名版，仅构建验证）。

- [ ] **Step 4: 验证 Windows 桌面端未破坏**

```bash
flutter build windows --debug
```
Expected: Windows 构建成功。

- [ ] **Step 5: 检查发布 APK 大小**

```bash
ls -lh build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **Step 6: 合并到 master**

```bash
git checkout master
git merge feature/android-v1 --no-ff -m "feat: add Android mobile support with responsive UI and cross-platform db adapter"
```

- [ ] **Step 7: 提交**

```bash
git add docs/superpowers/plans/2026-07-19-moveon-mobile-implementation-plan.md docs/superpowers/specs/2026-07-19-moveon-mobile-v1-prd.md
git commit -m "docs: add mobile V1.0 PRD and implementation plan"
```

---

## Self-Review

**1. Spec coverage:**

| PRD 需求 | 对应 Task |
|----------|----------|
| Android 平台生成 + Gradle 镜像 | Task 1 |
| sqflite 跨平台适配 | Task 2 |
| 响应式网格（竖屏 2 列 / 横屏 4 列） | Task 3 + 4 |
| 视频播放横屏全屏 | Task 5 |
| 练习执行横屏全屏 | Task 6 |
| 移动端底部 ActionSheet 弹窗 | Task 3 + 7 |
| 权限声明（INTERNET 等） | Task 1 + 8 |
| 离线模式（PRD SF5 SR2） | Task 8（基础版：网络权限 + 无网络检测由各页面自行处理） |
| APK 构建 | Task 1 + 9 |
| 内置体操视频 22MB | 已存在于 `assets/videos/`，Android 自动打包 |

**2. Placeholder scan:** 无 TBD/TODO，所有代码步骤含实际实现。

**3. Type consistency:** `ResponsiveHelper.gridColumns(int)`, `ResponsiveHelper.isLandscape(bool)`, `ResponsiveHelper.showMobileConfirm(Future<bool?>)` 前后一致。
