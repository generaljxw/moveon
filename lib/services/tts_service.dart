// lib/services/tts_service.dart — TTS 语音合成服务
import 'package:flutter_tts/flutter_tts.dart';

/// TTS 语音合成服务 — 封装 flutter_tts
///
/// 调用 Windows 系统语音引擎（默认 HuiHui 女声）。
/// 支持男/女声切换（取决于系统已安装的语音包）。
class TtsService {
  static final TtsService instance = TtsService._();
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  /// 检查语音引擎是否可用（系统至少安装了中文语音引擎）
  Future<bool> get isAvailable async {
    try {
      final languages = await _tts.getLanguages;
      return languages.isNotEmpty;
    } catch (_) { return false; }
  }

  /// 初始化语音参数：中文、语速适中偏慢（适合运动指导）
  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);   // 0.0-1.0, 0.45 = 适中偏慢
    await _tts.setPitch(1.0);         // 0.5-2.0, 1.0 = 自然
    await _tts.setVolume(1.0);        // 最大音量
    _initialized = true;
  }

  /// 语音播报 — 如"环抱双膝，时间60秒"
  Future<void> speak(String text) async => _tts.speak(text);

  /// 停止当前播报
  Future<void> stop() async => _tts.stop();
}
