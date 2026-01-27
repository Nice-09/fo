import 'package:mindmap_flutter/screens/mindmap_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MindMapApp());
}

class MindMapApp extends StatelessWidget {
  const MindMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '思维导图',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0x3B82F6)),
        useMaterial3: true,
      ),
      home: const MindMapScreen(),
    );
  }
}