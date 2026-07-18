// lib/models/online_video.dart — 用户添加的在线视频链接

/// 在线视频链接模型 — 用户在运动分类下收藏的在线视频
///
/// 支持两种视频类型：
/// - [videoType] = 'direct'：直链视频（.mp4/.webm 等），应用内使用网络流原生播放
/// - [videoType] = 'link'：平台链接（B站等），通过系统浏览器打开
///
/// 在线视频是用户私有的（通过 [userId] 外键关联），删除用户时级联删除。
class OnlineVideo {
  /// 自增主键（null 表示尚未写入数据库，由 SQLite 自动分配）
  final int? id;

  /// 所属用户 ID（外键 → users 表）
  final int userId;

  /// 运动分类名（8 种分类之一：瑜伽、有氧操、跳绳、塑形、体操、普拉提、拉伸、冥想）
  final String category;

  /// 视频名称（用户自定义，最长 50 字符）
  final String title;

  /// 视频链接 URL（必填，以 http:// 或 https:// 开头）
  final String url;

  /// 视频类型：'direct'（直链视频，应用内原生播放）或 'link'（平台链接，浏览器打开）
  final String videoType;

  /// 添加时间（ISO 8601 格式存储）
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
  /// [map] 的键使用 snake_case（如 user_id, video_type），与 SQLite 列名保持一致。
  /// 允许 [id] 为 null，适用于从查询结果直接构造的场景。
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

  /// 序列化为数据库行（使用 snake_case 键名，与 SQLite 列名一致）
  ///
  /// 当 [id] 为 null 时 map 中不含 'id' 键，让 SQLite 自动分配主键
  /// （用于 INSERT 操作）；[id] 非 null 时含 'id' 键（用于 UPDATE 操作）。
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

  /// 创建修改了部分字段的副本（不可变模式）
  ///
  /// 未传入的参数保持原值。典型场景：编辑视频信息后生成更新对象。
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
