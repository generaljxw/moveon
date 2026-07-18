# 在线视频链接功能 — 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为跟练模块新增在线视频链接功能——用户在各分类下添加视频名称+URL，保存后可在应用内播放直链或用浏览器打开平台链接。

**Architecture:** 新增 OnlineVideo 模型 + VideoLinkService 服务层，在 SQLite 中新增 online_videos 表。VideoListScreen 混合展示内置视频和在线视频，通过标签区分。VideoPlayerScreen 根据 video_type 分发到网络播放器或系统浏览器。

**Tech Stack:** Flutter/Dart, sqflite_common_ffi, video_player_win, url_launcher, provider

## Global Constraints

- 所有源代码在 `/lib/`，测试在 `/test/`
- Dart SDK >=3.2.0，Flutter 3.44.6
- Windows 桌面目标平台
- TDD：先写失败测试 → 实现 → 通过 → 提交
- 代码注释比例 ≥20%
- 提交信息中英文皆可，描述"做了什么"和"为什么"
- 数据库统一由 DatabaseService 管理
- 使用 Provider 做状态管理
- 在线视频数量不限（与 DIY 模组 10 个限制不同）
- 游客模式仅展示内置视频，不显示在线视频

---

### Task 1: 添加 url_launcher 依赖

**Files:**
- Modify: `pubspec.yaml:45`

**Interfaces:**
- Consumes: 无
- Produces: url_launcher 包可用，后续 Task 7 使用 `launchUrl()` 函数

- [ ] **Step 1: 在 pubspec.yaml 添加 url_launcher 依赖**

```yaml
  # Google Fonts — Noto Sans SC 中文字体
  google_fonts: ^6.1.0
  # URL 启动器 — 调用系统浏览器打开外部链接
  url_launcher: ^6.2.2
```

- [ ] **Step 2: 安装依赖**

Run: `cd "c:/ClaudeCode/02.MoveOn APP" && flutter pub get`
Expected: 无错误，`url_launcher` 添加到 `.dart_tool/package_config.json`

- [ ] **Step 3: 验证项目仍可分析**

Run: `flutter analyze`
Expected: `No issues found!` (info/warning 不影响)

- [ ] **Step 4: 提交**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add url_launcher dependency for opening external video links"
```

---

### Task 2: 创建 OnlineVideo 数据模型

**Files:**
- Create: `lib/models/online_video.dart`
- Create: `test/models/online_video_test.dart`

**Interfaces:**
- Consumes: 无
- Produces:
  ```dart
  class OnlineVideo {
    final int? id;
    final int userId;
    final String category;
    final String title;
    final String url;
    final String videoType;  // 'direct' | 'link'
    final DateTime createdAt;

    const OnlineVideo({this.id, required this.userId, required this.category,
      required this.title, required this.url, required this.videoType,
      required this.createdAt});

    factory OnlineVideo.fromMap(Map<String, dynamic> map);
    Map<String, dynamic> toMap();
    OnlineVideo copyWith({int? id, int? userId, String? category, String? title,
      String? url, String? videoType, DateTime? createdAt});
  }
  ```

- [ ] **Step 1: 编写 OnlineVideo model 测试（先失败）**

创建 `test/models/online_video_test.dart`：

```dart
// test/models/online_video_test.dart — 在线视频模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/models/online_video.dart';

void main() {
  group('OnlineVideo model', () {
    // ---- fromMap: 从数据库行构造 ----
    test('fromMap creates OnlineVideo with direct video_type', () {
      final map = {
        'id': 1,
        'user_id': 42,
        'category': '瑜伽',
        'title': '晨间瑜伽30分钟',
        'url': 'https://example.com/yoga.mp4',
        'video_type': 'direct',
        'created_at': '2026-07-18T08:00:00.000',
      };
      final video = OnlineVideo.fromMap(map);
      expect(video.id, 1);
      expect(video.userId, 42);
      expect(video.category, '瑜伽');
      expect(video.title, '晨间瑜伽30分钟');
      expect(video.url, 'https://example.com/yoga.mp4');
      expect(video.videoType, 'direct');
      expect(video.createdAt, DateTime(2026, 7, 18, 8, 0, 0));
    });

    // ---- fromMap: link 类型 ----
    test('fromMap creates OnlineVideo with link video_type', () {
      final map = {
        'id': 2,
        'user_id': 7,
        'category': '有氧操',
        'title': 'B站有氧操',
        'url': 'https://www.bilibili.com/video/BV1xx411c7mD',
        'video_type': 'link',
        'created_at': '2026-07-18T09:00:00.000',
      };
      final video = OnlineVideo.fromMap(map);
      expect(video.videoType, 'link');
    });

    // ---- fromMap: id 为 null（未写入数据库前） ----
    test('fromMap handles null id (pre-insert)', () {
      final map = {
        'user_id': 1,
        'category': '拉伸',
        'title': '拉伸',
        'url': 'https://example.com/stretch.mkv',
        'video_type': 'direct',
        'created_at': '2026-07-18T10:00:00.000',
      };
      final video = OnlineVideo.fromMap(map);
      expect(video.id, isNull);
    });

    // ---- toMap: 序列化不含 id（insert 时） ----
    test('toMap excludes id when null (for insert)', () {
      final video = OnlineVideo(
        userId: 1,
        category: '普拉提',
        title: '普拉提基础',
        url: 'https://example.com/pilates.mp4',
        videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 11, 0, 0),
      );
      final map = video.toMap();
      expect(map.containsKey('id'), false);
      expect(map['user_id'], 1);
      expect(map['category'], '普拉提');
      expect(map['title'], '普拉提基础');
      expect(map['url'], 'https://example.com/pilates.mp4');
      expect(map['video_type'], 'direct');
      expect(map['created_at'], '2026-07-18T11:00:00.000');
    });

    // ---- toMap: 含 id（update 时） ----
    test('toMap includes id when not null (for update)', () {
      final video = OnlineVideo(
        id: 5, userId: 1, category: '冥想',
        title: '冥想引导', url: 'https://bilibili.com/video/123',
        videoType: 'link', createdAt: DateTime(2026, 7, 18, 12, 0, 0),
      );
      final map = video.toMap();
      expect(map['id'], 5);
    });

    // ---- copyWith: 部分字段更新 ----
    test('copyWith creates updated copy preserving other fields', () {
      final original = OnlineVideo(
        id: 1, userId: 42, category: '瑜伽',
        title: '旧标题', url: 'https://example.com/old.mp4',
        videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0),
      );
      final updated = original.copyWith(title: '新标题', url: 'https://example.com/new.mp4');
      expect(updated.id, 1);
      expect(updated.userId, 42);
      expect(updated.category, '瑜伽');
      expect(updated.title, '新标题');
      expect(updated.url, 'https://example.com/new.mp4');
      expect(updated.videoType, 'direct');
      expect(updated.createdAt, original.createdAt);
    });

    // ---- video_type 仅接受 direct 或 link ----
    test('videoType accepts direct value', () {
      final video = OnlineVideo(
        userId: 1, category: '体操', title: 'T',
        url: 'https://x.com/v.mp4', videoType: 'direct',
        createdAt: DateTime.now(),
      );
      expect(video.videoType, 'direct');
    });

    test('videoType accepts link value', () {
      final video = OnlineVideo(
        userId: 1, category: '体操', title: 'T',
        url: 'https://x.com/v', videoType: 'link',
        createdAt: DateTime.now(),
      );
      expect(video.videoType, 'link');
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd "c:/ClaudeCode/02.MoveOn APP" && flutter test test/models/online_video_test.dart`
Expected: 编译失败 — `online_video.dart` 文件不存在

- [ ] **Step 3: 实现 OnlineVideo 模型**

创建 `lib/models/online_video.dart`：

```dart
// lib/models/online_video.dart — 用户添加的在线视频链接
/// 在线视频链接模型 — 用户在运动分类下收藏的在线视频
///
/// 支持两种视频类型：
/// - [videoType] = 'direct'：直链视频（.mp4/.webm 等），应用内原生播放
/// - [videoType] = 'link'：平台链接（B站等），通过系统浏览器打开
///
/// 在线视频是用户私有的（[userId] 外键），删除用户时级联删除。
class OnlineVideo {
  /// 自增主键（null 表示尚未写入数据库）
  final int? id;

  /// 所属用户 ID（外键 → users）
  final int userId;

  /// 运动分类名（8 种之一）
  final String category;

  /// 视频名称（用户自定义，最长 50 字符）
  final String title;

  /// 视频链接 URL（必填，http:// 或 https:// 开头）
  final String url;

  /// 视频类型：'direct'（直链原生播放）或 'link'（浏览器打开）
  final String videoType;

  /// 添加时间
  final DateTime createdAt;

  const OnlineVideo({
    this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.url,
    required this.videoType,
    required this.createdAt,
  });

  /// 从数据库行构造 OnlineVideo 实例
  ///
  /// [map] 的键使用 snake_case（如 user_id），与 SQLite 列名一致。
  factory OnlineVideo.fromMap(Map<String, dynamic> map) {
    return OnlineVideo(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      category: (map['category'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      url: (map['url'] as String?) ?? '',
      videoType: (map['video_type'] as String?) ?? 'link',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 序列化为数据库行（snake_case 键名）
  ///
  /// 当 [id] 为 null 时不含 id 键，让 SQLite 自动分配主键。
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'category': category,
      'title': title,
      'url': url,
      'video_type': videoType,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  /// 创建修改了部分字段的副本
  ///
  /// 用于编辑视频信息时生成更新后的对象。
  OnlineVideo copyWith({
    int? id,
    int? userId,
    String? category,
    String? title,
    String? url,
    String? videoType,
    DateTime? createdAt,
  }) {
    return OnlineVideo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      title: title ?? this.title,
      url: url ?? this.url,
      videoType: videoType ?? this.videoType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/models/online_video_test.dart`
Expected: 全部 8 个测试通过

- [ ] **Step 5: 提交**

```bash
git add lib/models/online_video.dart test/models/online_video_test.dart
git commit -m "feat: add OnlineVideo model with serialization and copyWith"
```

---

### Task 3: 数据库新增 online_videos 表

**Files:**
- Modify: `lib/services/database_service.dart:46-101`
- Modify: `test/services/database_service_test.dart`

**Interfaces:**
- Consumes: 无（独立于 Task 2）
- Produces:
  ```dart
  // database_service.dart 变更：
  // - _onCreate 新增 CREATE TABLE online_videos
  // - 新增 _onUpgrade 处理 v1→v2 迁移
  // - version: 1 → 2
  ```

- [ ] **Step 1: 更新数据库服务测试**

修改 `test/services/database_service_test.dart`，在 `main()` 函数末尾的 group 内追加新测试：

在最后一个 `test()` 函数（`'initialize is idempotent'`）的 `});` 之后，`});`（group 结尾）之前添加：

```dart
    // ---- online_videos 表创建 ----
    test('initialize creates online_videos table', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      final tables = (await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
      )).map((r) => r['name'] as String).toList();

      // 现在应该有 4 张表（含 online_videos）
      expect(tables, contains('online_videos'));
    });

    // ---- online_videos 表 Schema ----
    test('online_videos table has correct columns', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      final cols = (await db.rawQuery("PRAGMA table_info('online_videos')"))
          .map((c) => c['name'] as String).toList();

      expect(cols, containsAll([
        'id', 'user_id', 'category', 'title',
        'url', 'video_type', 'created_at',
      ]));
    });

    // ---- online_videos 外键 ON DELETE CASCADE ----
    test('online_videos cascades delete when user is removed', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      // 插入用户
      await db.insert('users', {
        'username': 'cascade_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });
      // 插入在线视频
      await db.insert('online_videos', {
        'user_id': 1, 'category': '瑜伽', 'title': '测试视频',
        'url': 'https://example.com/v.mp4', 'video_type': 'direct',
        'created_at': '2026-07-18T00:00:00.000',
      });
      expect((await db.query('online_videos')).length, 1);

      // 删除用户 → 级联删除在线视频
      await db.delete('users', where: 'id = ?', whereArgs: [1]);
      final remaining = await db.query('online_videos');
      expect(remaining.length, 0);
    });

    // ---- online_videos 创建时间默认值 ----
    test('online_videos can insert with explicit created_at', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      await db.insert('users', {
        'username': 'time_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });
      final id = await db.insert('online_videos', {
        'user_id': 1, 'category': '冥想', 'title': '冥想',
        'url': 'https://x.com/v', 'video_type': 'link',
        'created_at': '2026-07-18T14:30:00.000',
      });
      final row = await db.query('online_videos', where: 'id = ?', whereArgs: [id]);
      expect(row.first['created_at'], '2026-07-18T14:30:00.000');
    });

    // ---- 同一分类下 URL 可重复（不同用户） ----
    test('online_videos allows same URL for different users', () async {
      final svc = DatabaseService();
      await svc.initialize(inMemory: true);
      final db = await svc.database;

      // 两个用户
      await db.insert('users', {
        'username': 'user_a', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });
      await db.insert('users', {
        'username': 'user_b', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      await db.insert('online_videos', {
        'user_id': 1, 'category': '瑜伽', 'title': 'A视频',
        'url': 'https://same-url.com/v.mp4', 'video_type': 'direct',
        'created_at': '2026-07-18T00:00:00.000',
      });
      // 不同用户同一 URL 应成功
      await db.insert('online_videos', {
        'user_id': 2, 'category': '瑜伽', 'title': 'B视频',
        'url': 'https://same-url.com/v.mp4', 'video_type': 'direct',
        'created_at': '2026-07-18T00:00:00.000',
      });
      final all = await db.query('online_videos');
      expect(all.length, 2);
    });
```

还需要把 `'initialize creates all 3 tables'` 测试更新为 4 张表：

```dart
    test('initialize creates all 4 tables', () async {
      // ... 同上，但 expect 改为：
      expect(tables, containsAll(['users', 'exercise_modules', 'exercise_actions', 'online_videos']));
    });
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/services/database_service_test.dart`
Expected: 3 个新测试全部 FAIL — `online_videos` 表尚不存在

- [ ] **Step 3: 实现数据库迁移**

修改 `lib/services/database_service.dart`：

将 `_onCreate` 的 OpenDatabaseOptions 中 `version: 1` 改为 `version: 2`，并在 `_onCreate` 末尾（`exercise_actions` 建表语句之后 `});`）添加 `online_videos` 建表语句。

同时修改 `initialize` 方法中两个路径（内存和文件）的 `OpenDatabaseOptions`：

内存路径（约第 37-40 行）：
```dart
      _db = await databaseFactoryFfi.openDatabase(
        testPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
```

文件路径（约第 46-49 行）：
```dart
      _db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
```

在 `_onCreate` 方法末尾（`exercise_actions` 建表的 `await db.execute(...)` 之后，`}` 之前）添加：

```dart
    // ---- online_videos: 在线视频链接表 ----
    // video_type: 'direct'=直链原生播放 / 'link'=浏览器打开
    // 同一用户同一分类下 URL 不重复（由 Service 层校验）
    await db.execute('''
      CREATE TABLE online_videos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        video_type TEXT NOT NULL DEFAULT 'link',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');
```

在 `_onCreate` 方法之后、`DatabaseService` 类的 closing `}` 之前，添加 `_onUpgrade` 方法：

```dart
  /// 数据库升级回调 — v1 → v2：新增 online_videos 表
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS online_videos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          category TEXT NOT NULL,
          title TEXT NOT NULL,
          url TEXT NOT NULL,
          video_type TEXT NOT NULL DEFAULT 'link',
          created_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
    }
  }
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/services/database_service_test.dart`
Expected: 全部 8 个测试（原有 5 + 新增 3）通过

- [ ] **Step 5: 确认所有已有测试不受影响**

Run: `flutter test`
Expected: 全部已有测试（原 39 个 + 新增）通过

- [ ] **Step 6: 提交**

```bash
git add lib/services/database_service.dart test/services/database_service_test.dart
git commit -m "feat: add online_videos table with user FK and cascade delete"
```

---

### Task 4: 创建 VideoLinkService 服务层

**Files:**
- Create: `lib/services/video_link_service.dart`
- Create: `test/services/video_link_service_test.dart`

**Interfaces:**
- Consumes:
  - `DatabaseService.instance.database` (Task 3)
  - `OnlineVideo.fromMap/toMap/copyWith` (Task 2)
- Produces:
  ```dart
  class VideoLinkService {
    /// 根据 URL 后缀判断视频类型
    static String detectVideoType(String url);
    /// 校验 URL 格式
    static String? validateUrl(String url);
    /// 校验视频名称
    static String? validateTitle(String title);
    /// 获取某用户在某分类下的所有在线视频（按添加时间倒序）
    Future<List<OnlineVideo>> getVideosForCategory(int userId, String category);
    /// 检查同一用户同分类下 URL 是否重复
    Future<bool> isDuplicateUrl(int userId, String category, String url, {int? excludeId});
    /// 添加在线视频，返回新记录的 id
    Future<int> addVideo(OnlineVideo video);
    /// 更新在线视频（名称/URL/类型）
    Future<void> updateVideo(OnlineVideo video);
    /// 删除在线视频
    Future<void> deleteVideo(int videoId);
  }
  ```

- [ ] **Step 1: 编写 VideoLinkService 测试**

创建 `test/services/video_link_service_test.dart`：

```dart
// test/services/video_link_service_test.dart — 在线视频服务层测试
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:moveon/services/database_service.dart';
import 'package:moveon/services/video_link_service.dart';
import 'package:moveon/models/online_video.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // 每个测试使用独立的数据库实例
  Future<VideoLinkService> _createService() async {
    final dbSvc = DatabaseService();
    await dbSvc.initialize(inMemory: true);
    return VideoLinkService();
  }

  group('VideoLinkService - detectVideoType', () {
    test('detects .mp4 as direct', () {
      expect(
        VideoLinkService.detectVideoType('https://example.com/video.mp4'),
        'direct',
      );
    });

    test('detects .webm as direct', () {
      expect(
        VideoLinkService.detectVideoType('https://cdn.com/v.webm'),
        'direct',
      );
    });

    test('detects .mkv as direct', () {
      expect(
        VideoLinkService.detectVideoType('https://host.com/movie.mkv'),
        'direct',
      );
    });

    test('detects .mov as direct', () {
      expect(
        VideoLinkService.detectVideoType('https://site.com/clip.mov'),
        'direct',
      );
    });

    test('detects bilibili URL as link', () {
      expect(
        VideoLinkService.detectVideoType('https://www.bilibili.com/video/BV1xx411c7mD'),
        'link',
      );
    });

    test('detects general URL without video extension as link', () {
      expect(
        VideoLinkService.detectVideoType('https://youtube.com/watch?v=abc'),
        'link',
      );
    });
  });

  group('VideoLinkService - validateUrl', () {
    test('accepts valid https URL', () {
      expect(VideoLinkService.validateUrl('https://example.com/v.mp4'), isNull);
    });

    test('accepts valid http URL', () {
      expect(VideoLinkService.validateUrl('http://cdn.com/video.webm'), isNull);
    });

    test('rejects empty URL', () {
      expect(VideoLinkService.validateUrl(''), isNotNull);
    });

    test('rejects non-http URL', () {
      expect(VideoLinkService.validateUrl('ftp://files.com/v.mp4'), isNotNull);
    });

    test('rejects string without protocol', () {
      expect(VideoLinkService.validateUrl('example.com/v.mp4'), isNotNull);
    });
  });

  group('VideoLinkService - validateTitle', () {
    test('accepts valid title', () {
      expect(VideoLinkService.validateTitle('晨间瑜伽'), isNull);
    });

    test('rejects empty title', () {
      expect(VideoLinkService.validateTitle(''), isNotNull);
    });

    test('rejects whitespace-only title', () {
      expect(VideoLinkService.validateTitle('   '), isNotNull);
    });

    test('rejects title over 50 chars', () {
      expect(VideoLinkService.validateTitle('一' * 51), isNotNull);
    });

    test('accepts title at exactly 50 chars', () {
      expect(VideoLinkService.validateTitle('一' * 50), isNull);
    });
  });

  group('VideoLinkService - CRUD', () {
    test('addVideo returns id and can be retrieved', () async {
      final svc = await _createService();
      // 需要先创建用户（外键约束）
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'vlink_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final id = await svc.addVideo(OnlineVideo(
        userId: 1, category: '瑜伽',
        title: '晨间瑜伽', url: 'https://example.com/yoga.mp4',
        videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0),
      ));
      expect(id, greaterThan(0));

      final videos = await svc.getVideosForCategory(1, '瑜伽');
      expect(videos.length, 1);
      expect(videos.first.title, '晨间瑜伽');
      expect(videos.first.videoType, 'direct');
    });

    test('getVideosForCategory returns only videos for that category', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'cat_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      await svc.addVideo(OnlineVideo(
        userId: 1, category: '瑜伽', title: '瑜伽A',
        url: 'https://x.com/a.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 0),
      ));
      await svc.addVideo(OnlineVideo(
        userId: 1, category: '有氧操', title: '有氧A',
        url: 'https://x.com/b.mp4', videoType: 'direct',
        createdAt: DateTime(2026, 7, 18, 8, 1),
      ));

      final yogaVideos = await svc.getVideosForCategory(1, '瑜伽');
      expect(yogaVideos.length, 1);
      expect(yogaVideos.first.category, '瑜伽');

      final aeroVideos = await svc.getVideosForCategory(1, '有氧操');
      expect(aeroVideos.length, 1);
      expect(aeroVideos.first.category, '有氧操');
    });

    test('getVideosForCategory returns empty for no videos', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'empty_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final videos = await svc.getVideosForCategory(1, '冥想');
      expect(videos, isEmpty);
    });

    test('getVideosForCategory returns videos for correct user only', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'user_1', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });
      await db.insert('users', {
        'username': 'user_2', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      await svc.addVideo(OnlineVideo(userId: 1, category: '拉伸', title: 'U1视频',
        url: 'https://x.com/u1.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0)));
      await svc.addVideo(OnlineVideo(userId: 2, category: '拉伸', title: 'U2视频',
        url: 'https://x.com/u2.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 1)));

      final u1videos = await svc.getVideosForCategory(1, '拉伸');
      expect(u1videos.length, 1);
      expect(u1videos.first.title, 'U1视频');

      final u2videos = await svc.getVideosForCategory(2, '拉伸');
      expect(u2videos.length, 1);
      expect(u2videos.first.title, 'U2视频');
    });

    test('isDuplicateUrl returns true for same user+category+URL', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'dup_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: 'A',
        url: 'https://same-url.com/v.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0)));

      final dup = await svc.isDuplicateUrl(1, '瑜伽', 'https://same-url.com/v.mp4');
      expect(dup, true);
    });

    test('isDuplicateUrl returns false for different category same URL', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'diff_cat', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: 'A',
        url: 'https://url.com/v.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0)));

      final dup = await svc.isDuplicateUrl(1, '有氧操', 'https://url.com/v.mp4');
      expect(dup, false);
    });

    test('isDuplicateUrl with excludeId ignores matching record', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'excl_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final id = await svc.addVideo(OnlineVideo(userId: 1, category: '体操', title: 'T',
        url: 'https://x.com/v.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0)));

      // 排除自身，不应判重复（编辑时 URL 不变）
      final dup = await svc.isDuplicateUrl(1, '体操', 'https://x.com/v.mp4', excludeId: id);
      expect(dup, false);
    });

    test('updateVideo modifies title and url', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'update_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final id = await svc.addVideo(OnlineVideo(userId: 1, category: '塑形', title: '旧名',
        url: 'https://x.com/old.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0)));

      await svc.updateVideo(OnlineVideo(
        id: id, userId: 1, category: '塑形', title: '新名',
        url: 'https://x.com/new.webm', videoType: 'link', createdAt: DateTime(2026, 7, 18, 8, 0),
      ));

      final videos = await svc.getVideosForCategory(1, '塑形');
      expect(videos.first.title, '新名');
      expect(videos.first.url, 'https://x.com/new.webm');
      expect(videos.first.videoType, 'link');
    });

    test('deleteVideo removes video', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'delete_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      final id = await svc.addVideo(OnlineVideo(userId: 1, category: '冥想', title: '删除我',
        url: 'https://x.com/del.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0)));

      await svc.deleteVideo(id);
      final videos = await svc.getVideosForCategory(1, '冥想');
      expect(videos, isEmpty);
    });

    test('videos returned in reverse chronological order', () async {
      final svc = await _createService();
      final db = await DatabaseService.instance.database;
      await db.insert('users', {
        'username': 'order_test', 'password_hash': 'h',
        'created_at': '2026-07-18T00:00:00.000', 'failed_attempts': 0,
      });

      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: '最早',
        url: 'https://x.com/1.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0)));
      await svc.addVideo(OnlineVideo(userId: 1, category: '瑜伽', title: '最晚',
        url: 'https://x.com/2.mp4', videoType: 'direct', createdAt: DateTime(2026, 7, 18, 9, 0)));

      final videos = await svc.getVideosForCategory(1, '瑜伽');
      expect(videos.length, 2);
      // 最晚添加的排在前面
      expect(videos.first.title, '最晚');
      expect(videos.last.title, '最早');
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/services/video_link_service_test.dart`
Expected: 编译失败 — `video_link_service.dart` 不存在

- [ ] **Step 3: 实现 VideoLinkService**

创建 `lib/services/video_link_service.dart`：

```dart
// lib/services/video_link_service.dart — 在线视频链接服务
import 'database_service.dart';
import '../models/online_video.dart';

/// 在线视频链接服务 — 管理用户收藏的在线视频
///
/// 提供用户维度下的增删改查、URL 校验和类型检测。
/// 同一用户同一分类下 URL 不可重复。
class VideoLinkService {
  /// 根据 URL 文件扩展名判断视频类型
  ///
  /// 支持常见视频直链格式：mp4、webm、mkv、mov。
  /// 不满足时默认返回 'link'（平台链接，通过浏览器打开）。
  static String detectVideoType(String url) {
    final lower = url.toLowerCase();
    // 常见直链视频扩展名
    const directExtensions = ['.mp4', '.webm', '.mkv', '.mov'];
    for (final ext in directExtensions) {
      if (lower.endsWith(ext)) return 'direct';
    }
    return 'link';
  }

  /// 校验 URL 格式合法性
  ///
  /// 返回 null 表示通过，返回字符串则为错误提示信息。
  static String? validateUrl(String url) {
    if (url.trim().isEmpty) return '请输入视频链接';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return '链接必须以 http:// 或 https:// 开头';
    }
    return null; // 格式合法
  }

  /// 校验视频名称合法性
  ///
  /// 返回 null 表示通过，返回字符串则为错误提示信息。
  static String? validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '请输入视频名称';
    if (trimmed.length > 50) return '视频名称不能超过 50 个字符';
    return null; // 合法
  }

  /// 获取某用户在某分类下的所有在线视频（按添加时间倒序）
  ///
  /// 最新添加的视频排列在最前。
  Future<List<OnlineVideo>> getVideosForCategory(int userId, String category) async {
    final db = await DatabaseService.instance.database;
    final rows = await db.query(
      'online_videos',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => OnlineVideo.fromMap(r)).toList();
  }

  /// 检查同一用户在同一分类下是否已存在相同 URL 的视频
  ///
  /// [excludeId]：编辑时排除自身的 id，避免将自身判为重复。
  Future<bool> isDuplicateUrl(int userId, String category, String url, {int? excludeId}) async {
    final db = await DatabaseService.instance.database;
    String where = 'user_id = ? AND category = ? AND url = ?';
    final whereArgs = <dynamic>[userId, category, url];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final rows = await db.query('online_videos', where: where, whereArgs: whereArgs, limit: 1);
    return rows.isNotEmpty;
  }

  /// 添加在线视频，返回新记录的主键 id
  ///
  /// 调用前应用层应已校验名称/URL 合法性及重复性。
  Future<int> addVideo(OnlineVideo video) async {
    final db = await DatabaseService.instance.database;
    final id = await db.insert('online_videos', video.toMap());
    return id;
  }

  /// 更新在线视频信息（名称、URL、类型）
  ///
  /// [video] 必须带有效的 [id]，根据 id 定位记录更新。
  Future<void> updateVideo(OnlineVideo video) async {
    final db = await DatabaseService.instance.database;
    await db.update(
      'online_videos',
      video.toMap(),
      where: 'id = ?',
      whereArgs: [video.id],
    );
  }

  /// 删除在线视频（永久删除，不可恢复）
  Future<void> deleteVideo(int videoId) async {
    final db = await DatabaseService.instance.database;
    await db.delete('online_videos', where: 'id = ?', whereArgs: [videoId]);
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/services/video_link_service_test.dart`
Expected: 全部测试通过

- [ ] **Step 5: 提交**

```bash
git add lib/services/video_link_service.dart test/services/video_link_service_test.dart
git commit -m "feat: add VideoLinkService with CRUD, URL validation, and type detection"
```

---

### Task 5: 创建 AddVideoDialog 弹窗组件

**Files:**
- Create: `lib/screens/follow/add_video_dialog.dart`
- Create: `test/screens/follow/add_video_dialog_test.dart`

**Interfaces:**
- Consumes:
  - `VideoLinkService.detectVideoType/validateUrl/validateTitle` (Task 4)
  - `OnlineVideo` model (Task 2)
- Produces:
  ```dart
  /// 在线视频添加/编辑弹窗
  ///
  /// [existingVideo] 非 null 时为编辑模式（修改名称/URL），
  /// 为 null 时为添加模式。返回 null 表示取消。
  Future<OnlineVideo?> showAddVideoDialog(BuildContext context, {
    String category,        // 预填分类（添加模式必传）
    OnlineVideo? existingVideo, // 编辑模式传入
  })
  ```

- [ ] **Step 1: 编写 Widget 测试**

创建 `test/screens/follow/add_video_dialog_test.dart`：

```dart
// test/screens/follow/add_video_dialog_test.dart — 视频添加弹窗测试
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/models/online_video.dart';
import 'package:moveon/screens/follow/add_video_dialog.dart';

void main() {
  group('AddVideoDialog', () {
    // ---- 添加模式：标题和输入框正确渲染 ----
    testWidgets('shows "添加在线视频" title in add mode', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context, category: '瑜伽'),
              child: const Text('open'),
            );
          }),
        ),
      ));

      // 点击触发弹窗
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('添加在线视频'), findsOneWidget);
      expect(find.widgetWithText(TextField, ''), findsNWidgets(2)); // 名称+URL
    });

    // ---- 编辑模式：预填已有数据 ----
    testWidgets('pre-fills fields in edit mode', (tester) async {
      // 用 OnlineVideo.fromMap 构造编辑对象（Task 2 已完成）
      final existing = OnlineVideo(
        id: 1, userId: 42, category: '瑜伽',
        title: '晨间瑜伽', url: 'https://example.com/yoga.mp4',
        videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context,
                  category: '瑜伽', existingVideo: existing),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 弹窗标题改为"编辑在线视频"
      expect(find.text('编辑在线视频'), findsOneWidget);
      // TextField 预填了名称和 URL
      expect(find.text('晨间瑜伽'), findsOneWidget);
      expect(find.text('https://example.com/yoga.mp4'), findsOneWidget);
      // ChoiceChip 选中 '直链视频'
      final directChip = tester.widget<ChoiceChip>(find.text('直链视频'));
      expect(directChip.selected, true);
    });

    // ---- 空名称保存 → 显示校验错误 ----
    testWidgets('shows validation error for empty title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context, category: '体操'),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 不输入名称，直接点保存
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 应显示校验错误
      expect(find.text('请输入视频名称'), findsOneWidget);
      // 弹窗仍在（未关闭）
      expect(find.text('添加在线视频'), findsOneWidget);
    });

    // ---- 空 URL 保存 → 显示校验错误 ----
    testWidgets('shows validation error for empty URL', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context, category: '体操'),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 输入名称但不输入 URL
      await tester.enterText(find.byType(TextField).first, '我的视频');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('请输入视频链接'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 确认测试框架就绪（先标记 skip 测试通过）**

Run: `flutter test test/screens/follow/add_video_dialog_test.dart`
Expected: 已 skip 的测试被跳过，其他编译通过

- [ ] **Step 3: 实现 AddVideoDialog**

创建 `lib/screens/follow/add_video_dialog.dart`：

```dart
// lib/screens/follow/add_video_dialog.dart — 添加/编辑在线视频弹窗
import 'package:flutter/material.dart';
import '../../models/online_video.dart';
import '../../services/video_link_service.dart';
import '../../theme.dart';

/// 显示添加或编辑在线视频的弹窗
///
/// 返回 [OnlineVideo] 表示用户点击了保存（包含未分配 id 的视频数据），
/// 返回 null 表示用户取消。
///
/// [category]：所属分类名，添加模式必传。
/// [existingVideo]：编辑模式传入已有视频数据用于预填。
Future<OnlineVideo?> showAddVideoDialog(
  BuildContext context, {
  required String category,
  OnlineVideo? existingVideo,
}) {
  return showDialog<OnlineVideo>(
    context: context,
    builder: (ctx) => _AddVideoDialog(
      category: category,
      existingVideo: existingVideo,
    ),
  );
}

/// 添加/编辑弹窗的内部 StatefulWidget
///
/// 管理表单输入状态和校验逻辑。
class _AddVideoDialog extends StatefulWidget {
  final String category;
  final OnlineVideo? existingVideo;
  const _AddVideoDialog({required this.category, this.existingVideo});

  @override State<_AddVideoDialog> createState() => _AddVideoDialogState();
}

class _AddVideoDialogState extends State<_AddVideoDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  // 视频类型：根据 URL 自动判定，用户可手动切换
  late String _videoType;
  // 表单校验错误信息
  String? _nameError;
  String? _urlError;

  /// 是否为编辑模式
  bool get _isEditing => widget.existingVideo != null;

  @override void initState() {
    super.initState();
    // 编辑模式：预填已有数据
    _nameCtrl = TextEditingController(text: widget.existingVideo?.title ?? '');
    _urlCtrl = TextEditingController(text: widget.existingVideo?.url ?? '');
    _videoType = widget.existingVideo?.videoType ??
        VideoLinkService.detectVideoType(_urlCtrl.text);
  }

  @override void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  /// 执行表单校验，全部通过返回 true
  bool _validate() {
    setState(() {
      _nameError = VideoLinkService.validateTitle(_nameCtrl.text);
      _urlError = VideoLinkService.validateUrl(_urlCtrl.text);
    });
    return _nameError == null && _urlError == null;
  }

  /// 构建表单数据为 OnlineVideo（无 id/userId/createdAt）
  OnlineVideo _buildVideo() {
    return OnlineVideo(
      // id 由调用方处理（添加为 null，编辑传 existingVideo.id）
      id: widget.existingVideo?.id,
      // userId 由调用方在保存时填入
      userId: widget.existingVideo?.userId ?? 0,
      category: widget.category,
      title: _nameCtrl.text.trim(),
      url: _urlCtrl.text.trim(),
      videoType: _videoType,
      createdAt: widget.existingVideo?.createdAt ?? DateTime.now(),
    );
  }

  @override Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? '编辑在线视频' : '添加在线视频'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 视频名称输入
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: '视频名称',
                hintText: '给视频起个名字',
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
              maxLength: 50,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            // 视频链接输入
            TextField(
              controller: _urlCtrl,
              decoration: InputDecoration(
                labelText: '视频链接',
                hintText: 'https://...',
                errorText: _urlError,
                border: const OutlineInputBorder(),
              ),
              // URL 变化时自动重新检测类型
              onChanged: (value) {
                setState(() {
                  _videoType = VideoLinkService.detectVideoType(value);
                });
              },
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 12),
            // 视频类型切换（手动覆盖自动检测）
            Row(
              children: [
                const Text('类型：', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('在线链接'),
                  selected: _videoType == 'link',
                  onSelected: (v) => setState(() => _videoType = 'link'),
                  selectedColor: MoveOnTheme.colorPrimaryLight.withAlpha(80),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('直链视频'),
                  selected: _videoType == 'direct',
                  onSelected: (v) => setState(() => _videoType = 'direct'),
                  selectedColor: MoveOnTheme.colorPrimaryLight.withAlpha(80),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (!_validate()) return;
            Navigator.of(context).pop(_buildVideo());
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 运行测试（非 skip 部分）确认通过**

Run: `flutter test test/screens/follow/add_video_dialog_test.dart`
Expected: 0 个失败（skip 的不计）

- [ ] **Step 5: 提交**

```bash
git add lib/screens/follow/add_video_dialog.dart test/screens/follow/add_video_dialog_test.dart
git commit -m "feat: add AddVideoDialog for online video add/edit form"
```

---

### Task 6: 重构 VideoListScreen 混合展示内置与在线视频

**Files:**
- Modify: `lib/screens/follow/video_list_screen.dart`（从 StatelessWidget → StatefulWidget）
- (Widget 测试附在 Step 1-2 中)

**Interfaces:**
- Consumes:
  - `VideoLinkService.getVideosForCategory/deleteVideo` (Task 4)
  - `OnlineVideo` model (Task 2)
  - `showAddVideoDialog` (Task 5)
  - `AuthProvider.currentUser` (已有)
- Produces: 混合列表 UI（内置视频 + 在线视频）、AppBar + 号、标签区分

- [ ] **Step 1: 运行现有 Widget 测试确认基线**

Run: `flutter test test/widget_test.dart`
Expected: 通过

- [ ] **Step 2: 重写 VideoListScreen**

完整重写 `lib/screens/follow/video_list_screen.dart`：

```dart
// lib/screens/follow/video_list_screen.dart — 分类下的视频列表（内置+在线混合）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_category.dart';
import '../../models/online_video.dart';
import '../../services/category_service.dart';
import '../../services/video_link_service.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import 'video_player_screen.dart';
import 'add_video_dialog.dart';

/// 视频列表页 — 展示某运动类型下的内置视频和用户添加的在线视频
///
/// 内置视频和在线视频混合展示，通过标签区分来源。
/// 登录用户可通过 AppBar 右侧 + 号添加在线视频。
class VideoListScreen extends StatefulWidget {
  final WorkoutCategory category;
  const VideoListScreen({super.key, required this.category});

  @override State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  final _categoryService = CategoryService();
  final _videoLinkService = VideoLinkService();
  List<OnlineVideo> _onlineVideos = [];

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOnlineVideos();
  }

  /// 加载当前用户在此分类下的在线视频
  Future<void> _loadOnlineVideos() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    final videos = await _videoLinkService.getVideosForCategory(
      auth.currentUser!.id, widget.category.name);
    if (mounted) setState(() => _onlineVideos = videos);
  }

  /// 打开添加弹窗 → 保存 → 刷新列表
  Future<void> _addVideo() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;

    final result = await showAddVideoDialog(context, category: widget.category.name);
    if (result != null && mounted) {
      // 填入 userId 并写入数据库
      final toSave = result.copyWith(userId: auth.currentUser!.id);
      await _videoLinkService.addVideo(toSave);
      _loadOnlineVideos();
    }
  }

  /// 打开编辑弹窗 → 保存 → 刷新
  Future<void> _editVideo(OnlineVideo video) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;

    final result = await showAddVideoDialog(
      context,
      category: widget.category.name,
      existingVideo: video,
    );
    if (result != null && mounted) {
      await _videoLinkService.updateVideo(result);
      _loadOnlineVideos();
    }
  }

  /// 确认后删除
  Future<void> _deleteVideo(OnlineVideo video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除在线视频「${video.title}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _videoLinkService.deleteVideo(video.id!);
      _loadOnlineVideos();
    }
  }

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final builtInVideos = _categoryService.getVideosForCategory(widget.category.name);

    // 所有视频项：内置在前 + 在线在后
    final hasAnyVideos = builtInVideos.isNotEmpty || _onlineVideos.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        // 仅登录用户可见 + 号
        actions: auth.isLoggedIn
            ? [IconButton(icon: const Icon(Icons.add), onPressed: _addVideo,
                tooltip: '添加在线视频')]
            : null,
      ),
      body: !hasAnyVideos
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: builtInVideos.length + _onlineVideos.length,
              itemBuilder: (context, index) {
                if (index < builtInVideos.length) {
                  // 内置视频
                  return _BuiltInVideoTile(video: builtInVideos[index]);
                } else {
                  // 在线视频
                  final onlineVideo = _onlineVideos[index - builtInVideos.length];
                  return _OnlineVideoTile(
                    video: onlineVideo,
                    onTap: () => _playOnlineVideo(onlineVideo),
                    onEdit: () => _editVideo(onlineVideo),
                    onDelete: () => _deleteVideo(onlineVideo),
                  );
                }
              },
            ),
    );
  }

  /// 播放在线视频 → 直链用原生播放器 / 链接用浏览器
  void _playOnlineVideo(OnlineVideo video) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(
        video: null, // 内置 VideoInfo 为 null，播放器按在线模式处理
        onlineVideo: video,
      )),
    );
  }

  /// 空状态
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无视频，敬请期待',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

/// 内置视频列表项 — 保持现有样式，添加 "本地" 标签
class _BuiltInVideoTile extends StatelessWidget {
  final dynamic video; // VideoInfo 类型
  const _BuiltInVideoTile({required this.video});

  @override Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: MoveOnTheme.colorPrimaryLight.withAlpha(60),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_circle_fill,
              color: MoveOnTheme.colorPrimary, size: 26),
        ),
        title: Text(video.title),
        subtitle: Row(
          children: [
            Text('${video.durationSeconds ~/ 60} 分钟'),
            const SizedBox(width: 8),
            // "本地" 标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: MoveOnTheme.colorPrimaryLight.withAlpha(80),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('本地', style: TextStyle(
                  fontSize: 10, color: MoveOnTheme.colorPrimaryDark)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(
            video: video, onlineVideo: null))),
      ),
    );
  }
}

/// 在线视频列表项 — 地球图标 + "在线" 标签 + 右滑删除
class _OnlineVideoTile extends StatelessWidget {
  final OnlineVideo video;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _OnlineVideoTile({
    required this.video, required this.onTap,
    required this.onEdit, required this.onDelete,
  });

  @override Widget build(BuildContext context) {
    // 根据类型选择图标和标签色
    final isDirect = video.videoType == 'direct';
    final labelColor = isDirect ? Colors.blue : Colors.orange;
    final labelBg = isDirect ? Colors.blue.shade50 : Colors.orange.shade50;

    return Dismissible(
      key: Key('online_${video.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async { onDelete(); return false; },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: labelBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDirect ? Icons.language : Icons.open_in_browser,
              color: labelColor, size: 24,
            ),
          ),
          title: Text(video.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Row(
            children: [
              // "在线" 标签
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: labelBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('在线', style: TextStyle(fontSize: 10, color: labelColor)),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
          // 长按编辑（平台链接先确认再打开）
          onLongPress: onEdit,
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 运行测试确认编译通过（添加模式还有校验逻辑）**

Run: `flutter analyze lib/screens/follow/video_list_screen.dart`
Expected: 无 error

- [ ] **Step 4: 提交**

```bash
git add lib/screens/follow/video_list_screen.dart
git commit -m "feat: mixed video list with builtin/online tags and category-scoped add"
```

---

### Task 7: 修改 VideoPlayerScreen 支持网络流和浏览器跳转

**Files:**
- Modify: `lib/screens/follow/video_player_screen.dart`

**Interfaces:**
- Consumes:
  - `OnlineVideo.videoType` / `OnlineVideo.url` (Task 2)
  - `url_launcher` (Task 1)
- Produces:
  ```dart
  class VideoPlayerScreen extends StatefulWidget {
    // 二选一：内置视频传 video，在线视频传 onlineVideo
    final VideoInfo? video;
    final OnlineVideo? onlineVideo;
  }
  ```

- [ ] **Step 1: 验证现有播放器编译无害**

Run: `flutter analyze lib/screens/follow/video_player_screen.dart`
Expected: 无 error

- [ ] **Step 2: 重写 VideoPlayerScreen**

重写 `lib/screens/follow/video_player_screen.dart`：

```dart
// lib/screens/follow/video_player_screen.dart — 视频播放器（内置+在线）
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/category_service.dart';
import '../../models/online_video.dart';

/// 全屏视频播放器 — 支持内置本地文件和在线视频
///
/// 内置视频（[video] 非 null）：通过 file:// 加载本地文件播放。
/// 在线直链（[onlineVideo].videoType = 'direct'）：通过 VideoPlayerController.network 播放。
/// 在线链接（[onlineVideo].videoType = 'link'）：通过系统浏览器打开。
///
/// [video] 和 [onlineVideo] 必须二选一传入（恰好一个非 null）。
class VideoPlayerScreen extends StatefulWidget {
  /// 内置视频信息（本地文件播放）
  final VideoInfo? video;

  /// 在线视频信息（网络流或浏览器打开）
  final OnlineVideo? onlineVideo;

  const VideoPlayerScreen({
    super.key,
    this.video,
    this.onlineVideo,
  });

  @override State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _openingBrowser = false; // 正在打开浏览器

  @override void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // 平台链接 → 浏览器打开（无需初始化播放器）
    if (widget.onlineVideo != null && widget.onlineVideo!.videoType == 'link') {
      _openInBrowser();
      return;
    }

    try {
      if (widget.onlineVideo != null) {
        // 在线直链 → 网络流播放
        _controller = VideoPlayerController.network(widget.onlineVideo!.url);
      } else if (widget.video != null) {
        // 内置视频 → 本地文件播放
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final filePath = '$exeDir/data/flutter_assets/${widget.video!.assetPath}';
        _controller = VideoPlayerController.file(File(filePath));
      } else {
        setState(() => _hasError = true);
        return;
      }

      await _controller!.initialize();
      await _controller!.play();
      setState(() => _initialized = true);
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  /// 用系统浏览器打开平台链接
  Future<void> _openInBrowser() async {
    setState(() => _openingBrowser = true);
    try {
      final uri = Uri.parse(widget.onlineVideo!.url);
      // 先确认用户意图再打开
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('打开外部链接'),
          content: const Text('将使用系统浏览器打开此视频链接，是否继续？'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('打开')),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开此链接')));
      }
    } finally {
      if (mounted) Navigator.of(context).pop(); // 返回上一页
    }
  }

  @override void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// 获取页面标题
  String get _title {
    if (widget.onlineVideo != null) return widget.onlineVideo!.title;
    if (widget.video != null) return widget.video!.title;
    return '视频播放';
  }

  @override Widget build(BuildContext context) {
    // 正在打开浏览器 → 返回列表页（由 _openInBrowser 处理 pop）
    if (_openingBrowser) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const Center(child: Text('正在打开浏览器...')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
          colors: const VideoProgressColors(playedColor: Colors.teal)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                  });
                },
              ),
              const Spacer(),
              if (_controller!.value.position >= _controller!.value.duration)
                TextButton.icon(
                  icon: const Icon(Icons.replay), label: const Text('重新播放'),
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
}
```

- [ ] **Step 3: 运行分析确认无错误**

Run: `flutter analyze lib/screens/follow/video_player_screen.dart`
Expected: 无 error

- [ ] **Step 4: 运行全部测试**

Run: `flutter test`
Expected: 全部已有测试通过

- [ ] **Step 5: 提交**

```bash
git add lib/screens/follow/video_player_screen.dart
git commit -m "feat: support network streaming and browser launch in VideoPlayerScreen"
```

---

### Task 8: 端到端集成测试与最终验证

**Files:**
- 无新增文件，验证已完成的全部模块

**Interfaces:**
- Consumes: 所有 Task 1-7 的产物
- Produces: 集成验证通过的完整功能

- [ ] **Step 1: 运行全部测试套件**

Run: `flutter test`
Expected: 全部测试通过（无 FAIL）

- [ ] **Step 2: 运行静态分析**

Run: `flutter analyze`
Expected: 无 error（info/warning 可忽略）

- [ ] **Step 3: 构建验证**

Run: `flutter build windows --debug`
Expected: `√ Built build\windows\x64\runner\Debug\moveon.exe`

- [ ] **Step 4: 最终提交（如无额外变更则跳过）**

如果前序步骤无遗漏变更，则不需要额外提交。

---
