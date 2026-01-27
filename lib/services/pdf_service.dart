import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/node.dart';
import '../models/connection.dart';

class PDFService {
  static const double nodeWidth = 140.0;
  static const double nodeHeight = 50.0;
  static const double horizontalGap = 30.0;
  static const double verticalGap = 15.0;
  static const double fontSize = 14.0;

  // 颜色映射
  static const Map<int, PdfColor> levelColors = {
    0: PdfColor.fromInt(0xFF3B82F6), // 蓝色
    1: PdfColor.fromInt(0xFF5B8FF9), // 蓝绿色
    2: PdfColor.fromInt(0xFF5AD8A6), // 绿色
    3: PdfColor.fromInt(0xFFF6BD16), // 黄色
    4: PdfColor.fromInt(0xFFE86452), // 红色
    5: PdfColor.fromInt(0xFF945FB9), // 紫色
  };

  // 导出为PDF
  static Future<String> exportToPDF(
    List<Node> nodes,
    List<Connection> connections,
  ) async {
    final pdf = pw.Document();

    // 获取所有可见节点
    final visibleNodes = _getVisibleNodes(nodes);

    // 计算画布边界
    final bounds = _calculateBounds(visibleNodes);
    final width = bounds.right - bounds.left + 100;
    final height = bounds.bottom - bounds.top + 100;

    // 创建PDF页面
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height),
        build: (pw.Context context) {
          return pw.CustomPaint(
            size: PdfPoint(width, height),
            painter: _MindMapPDFPainter(
              nodes: visibleNodes,
              connections: connections,
              offsetX: -bounds.left + 50,
              offsetY: -bounds.top + 50,
            ),
          );
        },
      ),
    );

    // 保存PDF文件
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${directory.path}/mindmap_$timestamp.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    return path;
  }

  // 获取可见节点
  static List<Node> _getVisibleNodes(List<Node> nodes) {
    final root = nodes.firstWhere((n) => n.isRoot);
    final visible = <Node>[];
    _collectVisible(root, nodes, visible);
    return visible;
  }

  static void _collectVisible(Node node, List<Node> nodes, List<Node> visible) {
    visible.add(node);
    if (!node.isCollapsed) {
      final children = nodes.where((n) => n.parentId == node.id).toList();
      for (final child in children) {
        _collectVisible(child, nodes, visible);
      }
    }
  }

  // 计算边界
  static _Bounds _calculateBounds(List<Node> nodes) {
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      minX = minX < node.x ? minX : node.x;
      maxX = maxX > node.x + node.width ? maxX : node.x + node.width;
      minY = minY < node.y ? minY : node.y;
      maxY = maxY > node.y + node.height ? maxY : node.y + node.height;
    }

    return _Bounds(left: minX, top: minY, right: maxX, bottom: maxY);
  }
}

class _Bounds {
  final double left;
  final double top;
  final double right;
  final double bottom;

  _Bounds({required this.left, required this.top, required this.right, required this.bottom});
}

class _MindMapPDFPainter extends pw.CustomPainter {
  final List<Node> nodes;
  final List<Connection> connections;
  final double offsetX;
  final double offsetY;

  _MindMapPDFPainter({
    required this.nodes,
    required this.connections,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(pw.Canvas canvas) {
    // 绘制连接线
    _drawConnections(canvas);

    // 绘制节点
    _drawNodes(canvas);
  }

  void _drawConnections(pw.Canvas canvas) {
    final visibleNodeIds = nodes.map((n) => n.id!).toSet();

    for (final connection in connections) {
      final sourceNode = nodes.firstWhere((n) => n.id == connection.sourceId);
      final targetNode = nodes.firstWhere((n) => n.id == connection.targetId);

      if (!visibleNodeIds.contains(sourceNode.id!) ||
          !visibleNodeIds.contains(targetNode.id!)) {
        continue;
      }

      // 绘制连接线
      final startX = sourceNode.x + sourceNode.width + offsetX;
      final startY = sourceNode.y + sourceNode.height / 2 + offsetY;
      final endX = targetNode.x + offsetX;
      final endY = targetNode.y + targetNode.height / 2 + offsetY;

      final midX = startX + (endX - startX) / 2;

      canvas.drawLine(
        pw.Offset(startX, startY),
        pw.Offset(midX, startY),
        pw.Paint()
          ..color = PdfColors.grey600
          ..lineWidth = 1.5,
      );

      canvas.drawLine(
        pw.Offset(midX, startY),
        pw.Offset(midX, endY),
        pw.Paint()
          ..color = PdfColors.grey600
          ..lineWidth = 1.5,
      );

      canvas.drawLine(
        pw.Offset(midX, endY),
        pw.Offset(endX, endY),
        pw.Paint()
          ..color = PdfColors.grey600
          ..lineWidth = 1.5,
      );
    }
  }

  void _drawNodes(pw.Canvas canvas) {
    for (final node in nodes) {
      final x = node.x + offsetX;
      final y = node.y + offsetY;
      final width = node.width;
      final height = node.height;

      // 绘制节点背景
      canvas.drawRRect(
        pw.RRect.fromRectAndRadius(
          pw.Rect(x, y, width, height),
          pw.Radius.circular(4),
        ),
        pw.Paint()
          ..color = node.isRoot
              ? PDFService.levelColors[0]
              : PdfColors.white
          ..fill = true,
      );

      // 绘制节点边框
      canvas.drawRRect(
        pw.RRect.fromRectAndRadius(
          pw.Rect(x, y, width, height),
          pw.Radius.circular(4),
        ),
        pw.Paint()
          ..color = node.isRoot
              ? PdfColors.white
              : PdfColors.grey300
          ..lineWidth = 1.0,
      );

      // 绘制左边框颜色指示
      if (!node.isRoot && node.level > 0 && node.level <= 5) {
        final color = PDFService.levelColors[node.level] ?? PdfColors.grey;
        canvas.drawLine(
          pw.Offset(x, y),
          pw.Offset(x, y + height),
          pw.Paint()
            ..color = color
            ..lineWidth = 3.0,
        );
      }

      // 绘制文字
      final textStyle = pw.TextStyle(
        color: node.isRoot ? PdfColors.white : PdfColors.black,
        fontSize: PDFService.fontSize,
        fontWeight: pw.FontWeight.bold,
      );

      canvas.drawText(
        pw.Text(
          node.text,
          style: textStyle,
        ),
        x + 8,
        y + (height - PDFService.fontSize) / 2,
      );
    }
  }

  @override
  bool shouldRepaint(_MindMapPDFPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.connections != connections;
  }
}