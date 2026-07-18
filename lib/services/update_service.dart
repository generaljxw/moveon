// lib/services/update_service.dart — 应用更新检测服务（V1.0 框架）
///
/// 启动时检测远端版本，提示用户更新。
/// V1.0 版本检测为框架代码，远端端点就绪后启用。
class UpdateService {
  /// 当前应用版本（与 pubspec.yaml 一致）
  static const String currentVersion = '1.0.0';

  /// 检查是否有新版本可更新
  ///
  /// 比较逻辑（SR2 2a/2b）：
  /// - current < latest → 返回 latest（提示更新）
  /// - current >= latest → 返回 null（已最新）
  ///
  /// V1.0 默认返回 null（无可用更新），远端服务就绪后在此接入 HTTP 检测。
  Future<String?> checkForUpdate() async {
    // TODO: 接入远端版本检测 HTTP endpoint
    // GET https://api.moveon.app/v1/version → {"latest_version": "x.y.z"}
    // 使用 _compareVersions() 比较版本号
    return null; // V1.0: 暂无更新
  }

  /// 语义化版本比较（x.y.z 格式）
  int _compareVersions(String a, String b) {
    final aParts = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final bParts = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (int i = 0; i < 3; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av > bv) return 1;
      if (av < bv) return -1;
    }
    return 0;
  }
}
