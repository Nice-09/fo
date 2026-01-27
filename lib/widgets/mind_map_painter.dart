import 'package:flutter/material.dart';
import '../models/node.dart';
import '../models/connection.dart';

class MindMapPainter extends CustomPainter {
  final List<Node> nodes;
  final List<Connection> connections;
  final List<Node> visibleNodes;
  final double scale;
  final double panX;
  final double panY;
  final Map<String, Color> nodeColorMap;

  MindMapPainter({
    required this.nodes,
    required this.connections,
    required this.visibleNodes,
    required this.scale,
    required this.panX,
    required this.panY,
  }) : nodeColorMap = {
      '0': const Color(0xFF3B82F6), // 蓝色
      '1': const Color(0xFF5B8FF9), // 蓝绿色
      '2': const Color(0xFF5AD8A6), // 绿色
      '3': const Color(0xFFF6BD16), // 黄色
      '4': const Color(0xFFE86452), // 红色
      '5': const Color(0xFF945FB9), // 紫色
    };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // 绘制背景网格
    _drawGrid(canvas, size);

    // 绘制连接线
    _drawConnections(canvas);

    // 绘制节点
    _drawNodes(canvas);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.5;

    const gridSize = 20.0;
    for (var x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (var y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawConnections(Canvas canvas) {
    final connectionPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final visibleNodeIds = visibleNodes.map((n) => n.id!).toSet();

    for (final connection in connections) {
      final sourceNode = nodes.firstWhere((n) => n.id == connection.sourceId);
      final targetNode = nodes.firstWhere((n) => n.id == connection.targetId);

      if (!visibleNodeIds.contains(sourceNode.id!) ||
          !visibleNodeIds.contains(targetNode.id!)) {
        continue;
      }

      // 绘制水平-垂直-水平折线
      final sourceWidth = 140.0;
      const targetWidth = 140.0;
      const nodeHeight = 50.0;

      final startX = sourceNode.x * scale + panX + sourceWidth;
      final startY = sourceNode.y * scale + panY + nodeHeight / 2;
      final endX = targetNode.x * scale + panX;
      final endY = targetNode.y * scale + panY + targetNode.height / 2;

      final midX = startX + (endX - startX) / 2;

      final path = Path()
        ..moveTo(startX, startY)
        ..lineTo(midX, startY)
        ..lineTo(midX, endY)
        ..lineTo(endX, endY);

      canvas.drawPath(path, connectionPaint);
    }
  }

  void _drawNodes(Canvas canvas) {
    final visibleNodeIds = visibleNodes.map((n) => n.id!).toSet();

    for (final node in visibleNodes) {
      final rect = Rect.fromLTWH(
        node.x * scale + panX,
        node.y * scale + panY,
        node.width * scale,
        node.height * scale,
      );

      // 节点背景
      final nodePaint = Paint()
        ..color = node.isRoot
            ? Color(0xFF3B82F6)
            : Colors.white
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        nodePaint,
      );

      // 节点边框
      final borderPaint = Paint()
        ..color = node.isRoot
            ? Colors.transparent
            : Colors.grey.shade300
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        borderPaint,
      );

      // 左边框颜色指示层级
      if (!node.isRoot && node.level > 0 && node.level <= 5) {
        final color = nodeColorMap[node.level.toString()] ?? Colors.grey;
        final sidePaint = Paint()
          ..color = color
          ..strokeWidth = 3.0;

        canvas.drawLine(
          rect.left,
          rect.top,
          rect.left,
          rect.bottom,
          sidePaint,
        );
      }

      // 节点文字
      final textPainter = TextPainter(
        text: TextSpan(
          text: node.text,
          style: TextStyle(
            color: node.isRoot ? Colors.white : Colors.black87,
            fontSize: 14.0 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      final textOffset = Offset(
        rect.left + 8 * scale,
        rect.top + 8 * scale,
      );

      textPainter.layout(
        minWidth: rect.width - 16 * scale,
        maxWidth: rect.width - 16 * scale,
      );

      textPainter.paint(canvas, textOffset);

      // 如果是展开状态，绘制折叠按钮
      if (node.isExpanded && node.level > 0) {
        _drawCollapseButton(canvas, node, rect);
      }

      // 如果被选中，绘制选中效果
      if (node.isSelected) {
        final selectedPaint = Paint()
          ..color = const Color(0x3379F7F)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          selectedPaint,
        );
      }
    }
  }

  void _drawCollapseButton(Canvas canvas, Node node, Rect rect) {
    final buttonSize = 20.0 * scale;
    final buttonX = rect.left - buttonSize - 8;
    final buttonY = rect.top + (rect.height - buttonSize) / 2;

    final buttonPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawCircle(
      Offset(buttonX + buttonSize / 2, buttonY + buttonSize / 2),
      buttonSize / 2,
      buttonPaint,
    );
  }

  @override
  bool shouldRepaint(MindMapPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.connections != connections ||
        oldDelegate.visibleNodes != visibleNodes ||
        oldDelegate.scale != scale ||
        oldDelegate.panX != panX ||
        oldDelegate.panY != panY;
  }
}