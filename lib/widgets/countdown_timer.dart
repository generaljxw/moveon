// lib/widgets/countdown_timer.dart — 倒计时组件
import 'dart:async';
import 'package:flutter/material.dart';

/// 倒计时组件 — 每秒递减显示大字秒数
///
/// 到达 0 时回调 [onComplete]。
/// 支持 [pause]/[resume]/[reset] 外部控制。
class CountdownTimer extends StatefulWidget {
  final int totalSeconds;       // 倒计时初始秒数
  final VoidCallback onComplete; // 倒计时结束回调
  final bool showBeep;          // 最后 5 秒是否显示高亮提示

  const CountdownTimer({
    super.key,
    required this.totalSeconds,
    required this.onComplete,
    this.showBeep = true,
  });

  @override State<CountdownTimer> createState() => CountdownTimerState();
}

class CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;    // 剩余秒数
  Timer? _timer;
  bool _paused = false;

  @override void initState() {
    super.initState();
    _remaining = widget.totalSeconds;
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      if (_remaining <= 0) {
        _timer?.cancel();
        widget.onComplete();
        return;
      }
      setState(() => _remaining--);
    });
  }

  /// 暂停倒计时（SR3 4a）
  void pause() {
    setState(() => _paused = true);
  }

  /// 继续倒计时（SR3 4a）
  void resume() {
    setState(() => _paused = false);
  }

  bool get isPaused => _paused;
  int get remaining => _remaining;

  @override void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    // 最后 5 秒高亮显示（红色 + 大号字体）
    final isWarning = widget.showBeep && _remaining <= 5 && _remaining > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 大字倒计时
        Text(
          '$_remaining',
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w300,
            color: isWarning ? Colors.red : Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text('秒', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
      ],
    );
  }
}
