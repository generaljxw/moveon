// test/models/exercise_module_test.dart — 练习模组模型测试
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/models/exercise_module.dart';
import 'package:moveon/models/exercise_action.dart';

void main() {
  group('ExerciseModule model', () {
    // ---- fromMap 测试 ----
    test('fromMap creates module correctly', () {
      final map = {
        'id': 1, 'user_id': 42, 'name': '盆骨回正',
        'category': '塑形', 'created_at': '2026-07-17T08:00:00.000',
      };
      final module = ExerciseModule.fromMap(map);
      expect(module.id, 1);
      expect(module.userId, 42);
      expect(module.name, '盆骨回正');
      expect(module.category, '塑形');
      expect(module.createdAt, DateTime(2026, 7, 17, 8, 0, 0));
    });

    // ---- 模组名称最长 30 字符（规格：模组名称最多 30 个字符） ----
    test('module name accepts 30-character name', () {
      final name30 = '一二三四五六七八九十一二三四五六七八九十一二三四五六七八九十';
      expect(name30.length, 30);
      final module = ExerciseModule(
        userId: 1, name: name30, category: '瑜伽',
        createdAt: DateTime.now(),
      );
      expect(module.name.length, 30);
    });

    // ---- totalDuration: 计算所有动作时长之和 ----
    test('totalDuration calculates sum of all action durations', () {
      final actions = [
        ExerciseAction(moduleId: 1, name: 'A', durationSeconds: 60, isRest: false, sortOrder: 0),
        ExerciseAction(moduleId: 1, name: '休息', durationSeconds: 10, isRest: true, sortOrder: 1),
        ExerciseAction(moduleId: 1, name: 'B', durationSeconds: 45, isRest: false, sortOrder: 2),
      ];
      final total = ExerciseModule.totalDuration(actions);
      expect(total, 115); // 60 + 10 + 45 = 115 秒
    });

    // ---- totalDuration: 空列表返回 0 ----
    test('totalDuration returns 0 for empty action list', () {
      expect(ExerciseModule.totalDuration([]), 0);
    });
  });
}
