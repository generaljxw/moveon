// lib/screens/diy/module_execute_screen.dart — 练习执行页面
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../models/exercise_module.dart';
import '../../models/exercise_action.dart';
import '../../services/tts_service.dart';
import '../../widgets/countdown_timer.dart';

/// 练习执行页面 — 按顺序执行每个动作
///
/// 流程：TTS 播报 → 倒计时（含铛铛铛提示音）→ 切换下一动作 → 全部完成播放结束语。
class ModuleExecuteScreen extends StatefulWidget {
  final ExerciseModule module;
  final List<ExerciseAction> actions;

  const ModuleExecuteScreen({super.key, required this.module, required this.actions});

  @override State<ModuleExecuteScreen> createState() => _ModuleExecuteScreenState();
}

class _ModuleExecuteScreenState extends State<ModuleExecuteScreen> {
  int _currentIndex = 0;
  bool _finished = false;
  final GlobalKey<CountdownTimerState> _timerKey = GlobalKey();
  final TtsService _tts = TtsService.instance;

  // 音频播放器 — 播放内置提示音和结束语音
  final AudioPlayer _audioPlayer = AudioPlayer();

  ExerciseAction get _currentAction => widget.actions[_currentIndex];

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentAction());
  }

  @override void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// 播报当前动作名称和时长（TTS）
  Future<void> _speakCurrentAction() async {
    try {
      await _tts.init();
      await _tts.speak('${_currentAction.name}，时间${_currentAction.durationSeconds}秒');
    } catch (_) {
      // TTS 不可用 → 静默继续
    }
  }

  /// 倒计时最后 5 秒每秒响一次：5,4,3,2 → 柔和音；1 → 洪亮音
  void _playCountdownBeep(int remainingSeconds) {
    if (remainingSeconds == 1) {
      // 最后一秒：洪亮"铛"声，提示即将结束
      _audioPlayer.play(AssetSource('audio/countdown_beep.wav'));
    } else {
      // 前四秒：柔和短音
      _audioPlayer.play(AssetSource('audio/countdown_soft.wav'));
    }
  }

  /// 当前动作完成 → 切换到下一动作
  void _onActionComplete() {
    if (_currentIndex >= widget.actions.length - 1) {
      // 全部完成（SR3 step 7）：播放结束语音 + 内置音频
      setState(() => _finished = true);
      _audioPlayer.play(AssetSource('audio/workout_complete.wav'));
      _tts.speak('锻炼结束，好好休息吧');
    } else {
      setState(() => _currentIndex++);
      WidgetsBinding.instance.addPostFrameCallback((_) => _speakCurrentAction());
    }
  }

  /// 中途结束确认（SR3 4b）
  Future<void> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('结束练习'),
        content: const Text('确定要结束当前练习吗？当前进度将不会保存。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('确定')),
        ],
      ),
    );
    if (confirmed == true) {
      _tts.stop();
      _audioPlayer.stop();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override Widget build(BuildContext context) {
    if (_finished) {
      return _buildCompleteScreen();
    }

    final progress = (_currentIndex + 1) / widget.actions.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.name),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _confirmEnd),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 24),
          Text(_currentAction.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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

  Widget _buildCompleteScreen() {
    final totalSec = ExerciseModule.totalDuration(widget.actions);
    return Scaffold(
      appBar: AppBar(title: const Text('练习完成')),
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
}
