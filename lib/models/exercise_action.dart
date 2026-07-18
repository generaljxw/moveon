// lib/models/exercise_action.dart — 练习模组中的单个动作
/// 练习模组中的单个动作（或休息间隔）
///
/// 属于一个 [ExerciseModule]，按 [sortOrder] 排序执行。
/// [isRest] 标识休息间隔：休息时倒计时最后 5 秒不播放提示音。
class ExerciseAction {
  /// 自增主键（新建为 null）
  final int? id;

  /// 所属模组 ID（外键 → exercise_modules）
  final int moduleId;

  /// 动作名称，如"环抱双膝"；休息时写入可见文本如"休息"
  final String name;

  /// 时长（秒），合法范围 5-600，由 Service 层校验
  final int durationSeconds;

  /// 是否为休息间隔（执行时跳过倒计时提示音）
  final bool isRest;

  /// 在模组中的排序序号（从 0 开始）
  final int sortOrder;

  const ExerciseAction({
    this.id,
    required this.moduleId,
    required this.name,
    required this.durationSeconds,
    required this.isRest,
    required this.sortOrder,
  });

  /// 从 SQLite 行构造 — is_rest 为整数 0/1
  factory ExerciseAction.fromMap(Map<String, dynamic> map) {
    return ExerciseAction(
      id: map['id'] as int?,
      moduleId: (map['module_id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
      durationSeconds: (map['duration_seconds'] as int?) ?? 0,
      // SQLite 无 bool，用 INTEGER 0/1 存储
      isRest: (map['is_rest'] as int?) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  /// 序列化为数据库行 — Dart bool → SQLite INTEGER
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'module_id': moduleId,
      'name': name,
      'duration_seconds': durationSeconds,
      'is_rest': isRest ? 1 : 0,
      'sort_order': sortOrder,
    };
    if (id != null) map['id'] = id;
    return map;
  }
}
