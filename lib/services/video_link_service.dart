// lib/services/video_link_service.dart — 在线视频链接业务逻辑
import 'database_service.dart';
import '../models/online_video.dart';

/// 在线视频链接服务 — 管理用户收藏的在线视频
///
/// 提供用户维度下的增删改查、URL 校验和视频类型自动检测。
/// 同一用户在同一分类下不可添加重复 URL（编辑时排除自身）。
///
/// [dbService] 默认为 [DatabaseService.instance]，测试时可注入独立实例。
class VideoLinkService {
  final DatabaseService _dbService;

  VideoLinkService({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  /// 根据 URL 扩展名自动判断视频播放方式
  ///
  /// 常见视频直链格式（mp4/webm/mkv/mov）返回 'direct'，可应用内原生播放；
  /// 其余统一返回 'link'，通过系统浏览器打开。
  static String detectVideoType(String url) {
    final lower = url.toLowerCase();
    // 直链视频的常见扩展名列表
    const directExtensions = ['.mp4', '.webm', '.mkv', '.mov'];
    for (final ext in directExtensions) {
      if (lower.endsWith(ext)) return 'direct';
    }
    return 'link';
  }

  /// 校验 URL 格式合法性
  ///
  /// 返回 null 表示校验通过；返回字符串为面向用户的错误提示。
  static String? validateUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '请输入视频链接';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return '链接必须以 http:// 或 https:// 开头';
    }
    return null;
  }

  /// 校验视频名称合法性
  ///
  /// 返回 null 表示校验通过；返回字符串为面向用户的错误提示。
  static String? validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return '请输入视频名称';
    if (trimmed.length > 50) return '视频名称不能超过 50 个字符';
    return null;
  }

  /// 获取某用户在某分类下的所有在线视频（按添加时间倒序）
  ///
  /// 最新添加的视频排在最前，方便用户快速找到最近收藏。
  Future<List<OnlineVideo>> getVideosForCategory(int userId, String category) async {
    final db = await _dbService.database;
    final rows = await db.query(
      'online_videos',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => OnlineVideo.fromMap(r)).toList();
  }

  /// 检查同一用户在同一分类下是否已存在相同 URL
  ///
  /// [excludeId] 用于编辑场景：排除当前记录自身，
  /// 仅在其他记录中存在相同 URL 时才判为重复。
  Future<bool> isDuplicateUrl(int userId, String category, String url, {int? excludeId}) async {
    final db = await _dbService.database;
    String where = 'user_id = ? AND category = ? AND url = ?';
    final whereArgs = <dynamic>[userId, category, url];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final rows = await db.query('online_videos',
        where: where, whereArgs: whereArgs, limit: 1);
    return rows.isNotEmpty;
  }

  /// 添加在线视频，返回 SQLite 自动分配的记录 id
  ///
  /// 调用前应由应用层完成名称/URL 校验和重复性检查。
  Future<int> addVideo(OnlineVideo video) async {
    final db = await _dbService.database;
    final id = await db.insert('online_videos', video.toMap());
    return id;
  }

  /// 更新在线视频信息（名称、URL、视频类型）
  ///
  /// [video] 必须包含有效的 [id] 以定位目标记录。
  Future<void> updateVideo(OnlineVideo video) async {
    final db = await _dbService.database;
    await db.update(
      'online_videos',
      video.toMap(),
      where: 'id = ?',
      whereArgs: [video.id],
    );
  }

  /// 删除在线视频（永久删除，不可恢复）
  ///
  /// 删除前建议用户确认（由 UI 层实现确认弹窗）。
  Future<void> deleteVideo(int videoId) async {
    final db = await _dbService.database;
    await db.delete('online_videos', where: 'id = ?', whereArgs: [videoId]);
  }
}
