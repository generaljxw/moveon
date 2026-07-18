// lib/models/exercise_module.dart — 用户创建的 DIY 练习模组
import 'exercise_action.dart';

/// 用户创建的 DIY 练习模组
///
/// 属于一个用户([userId])，包含多个 [ExerciseAction]。
/// V1.0 每个用户最多 10 个模组（由 Service 层校验）。
class ExerciseModule {
  /// 自增主键
  final int? id;

  /// 所属用户 ID（外键 → users）
  final int userId;

  /// 模组名称（最多 30 字符）
  final String name;

  /// 运动类型分类（8 种之一：瑜伽、有氧操、跳绳、塑形、体操、普拉提、拉伸、冥想）
  final String category;

  /// 创建时间
  final DateTime createdAt;

  const ExerciseModule({
    this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.createdAt,
  });

  /// 从数据库行构造 ExerciseModule
  factory ExerciseModule.fromMap(Map<String, dynamic> map) {
    return ExerciseModule(
      id: map['id'] as int?,
      userId: (map['user_id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
      category: (map['category'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 序列化为数据库行
  /// id 为 null 时不含该键，让 SQLite 自动分配
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  /// 计算模组内所有动作的总时长（秒）
  ///
  /// 用于模组列表展示和练习执行时预估总耗时。
  static int totalDuration(List<ExerciseAction> actions) {
    return actions.fold(0, (sum, a) => sum + a.durationSeconds);
  }
}
