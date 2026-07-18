import 'package:flutter/material.dart';

void main() {
  runApp(const MoveOnApp());
}

/// MoveOn（动起来）应用入口
///
/// V1.0: Windows 桌面健身应用，包含跟练、DIY 模组和用户中心。
class MoveOnApp extends StatelessWidget {
  const MoveOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '动起来',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('MoveOn (动起来)'),
        ),
      ),
    );
  }
}
