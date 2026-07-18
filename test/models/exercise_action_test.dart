// test/models/exercise_action_test.dart — 练习动作模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/models/exercise_action.dart';

void main() {
  group('ExerciseAction model', () {
    // ---- isRest: SQLite 整数 1 映射为 true ----
    test('fromMap maps is_rest=1 to isRest=true', () {
      final a = ExerciseAction.fromMap({
        'id': 10, 'module_id': 1, 'name': '休息',
        'duration_seconds': 10, 'is_rest': 1, 'sort_order': 3,
      });
      expect(a.isRest, true);
    });

    // ---- isRest: 整数 0 映射为 false ----
    test('fromMap maps is_rest=0 to isRest=false', () {
      final a = ExerciseAction.fromMap({
        'id': 11, 'module_id': 1, 'name': '环抱双膝',
        'duration_seconds': 60, 'is_rest': 0, 'sort_order': 0,
      });
      expect(a.isRest, false);
    });

    // ---- toMap: Dart bool → SQLite int ----
    test('toMap converts isRest=true → is_rest=1', () {
      final a = ExerciseAction(
        moduleId: 1, name: '休息', durationSeconds: 10,
        isRest: true, sortOrder: 1,
      );
      expect(a.toMap()['is_rest'], 1);
    });

    test('toMap converts isRest=false → is_rest=0', () {
      final a = ExerciseAction(
        moduleId: 1, name: '动作', durationSeconds: 30,
        isRest: false, sortOrder: 0,
      );
      expect(a.toMap()['is_rest'], 0);
    });

    // ---- 动作时长边界值：规格允许 5-600 秒 ----
    test('durationSeconds accepts boundary values (5 and 600)', () {
      // 校验在 Service 层，Model 纯数据容器不校验
      final min = ExerciseAction(moduleId:1, name:'min', durationSeconds:5, isRest:false, sortOrder:0);
      expect(min.durationSeconds, 5);
      final max = ExerciseAction(moduleId:1, name:'max', durationSeconds:600, isRest:false, sortOrder:0);
      expect(max.durationSeconds, 600);
    });

    // ---- fromMap 不传 id 时 id 为 null（INSERT 用） ----
    test('fromMap handles optional id', () {
      final a = ExerciseAction.fromMap({
        'module_id': 1, 'name': '无 ID', 'duration_seconds': 20,
        'is_rest': 0, 'sort_order': 0,
      });
      expect(a.id, isNull);
    });
  });
}
