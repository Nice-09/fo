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
    1: PdfColor.fromInt(0xFF5B8FF9), // 浅蓝色
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
          return pw.Column(
            children: visibleNodes.map((node) {
              final x = node.x + 50 - bounds.left;
              final y = node.y + 50 - bounds.top;

              return pw.Positioned(
                left: x,
                top: y,
                child: pw.Container(
                  width: node.width,
                  height: node.height,
                  decoration: pw.BoxDecoration(
                    color: node.isRoot
                        ? levelColors[0]
                        : PdfColors.white,
                    border: pw.Border.all(
                      color: node.isRoot
                          ? PdfColors.transparent
                          : PdfColors.grey300,
                      width: 1.0,
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      node.text,
                      style: pw.TextStyle(
                        color: node.isRoot ? PdfColors.white : PdfColors.black,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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