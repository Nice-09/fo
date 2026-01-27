import '../models/node.dart';

class LayoutService {
  static const double nodeWidth = 140.0;
  static const double nodeHeight = 50.0;
  static const double horizontalGap = 30.0;
  static const double verticalGap = 15.0;

  // 执行自动布局
  static void performLayout(List<Node> nodes) {
    final root = nodes.firstWhere((n) => n.isRoot);

    // 重新计算所有节点的level
    _calculateLevels(root, nodes, 0);

    // 获取可见节点
    final visibleNodes = _getVisibleNodes(root, nodes);

    // 递归布局
    _layoutNode(root, visibleNodes, 0, 0);
  }

  // 计算节点层级
  static void _calculateLevels(Node node, List<Node> nodes, int level) {
    node.level = level;
    final children = _getChildren(node, nodes);
    for (final child in children) {
      _calculateLevels(child, nodes, level + 1);
    }
  }

  // 获取可见节点（未被折叠的）
  static List<Node> _getVisibleNodes(Node root, List<Node> nodes) {
    final visible = <Node>[];
    _collectVisible(root, nodes, visible);
    return visible;
  }

  static void _collectVisible(Node node, List<Node> nodes, List<Node> visible) {
    visible.add(node);
    if (!node.isCollapsed) {
      final children = _getChildren(node, nodes);
      for (final child in children) {
        _collectVisible(child, nodes, visible);
      }
    }
  }

  // 递归布局单个节点及其子节点
  static void _layoutNode(Node node, List<Node> visibleNodes, double x, double y) {
    // 设置当前节点位置
    node.x = x;
    node.y = y;
    node.width = nodeWidth;
    node.height = nodeHeight;

    // 获取可见的子节点
    final children = _getVisibleChildren(node, visibleNodes);

    if (children.isEmpty) {
      return;
    }

    // 计算子树高度
    double totalHeight = 0;
    for (final child in children) {
      final childHeight = _calculateSubtreeHeight(child, visibleNodes);
      totalHeight += childHeight;
    }

    // 计算起始Y坐标，使子节点居中
    double startY = y - totalHeight / 2;

    // 递归布局子节点
    double currentY = startY;
    for (final child in children) {
      final childHeight = _calculateSubtreeHeight(child, visibleNodes);
      final childY = currentY + childHeight / 2;
      _layoutNode(child, visibleNodes, x + nodeWidth + horizontalGap, childY);
      currentY += childHeight + verticalGap;
    }
  }

  // 获取可见的子节点
  static List<Node> _getVisibleChildren(Node node, List<Node> visibleNodes) {
    return visibleNodes.where((n) => n.parentId == node.id).toList();
  }

  // 计算子树的总高度
  static double _calculateSubtreeHeight(Node node, List<Node> visibleNodes) {
    final children = _getVisibleChildren(node, visibleNodes);

    if (children.isEmpty) {
      return nodeHeight;
    }

    double totalHeight = 0;
    for (final child in children) {
      totalHeight += _calculateSubtreeHeight(child, visibleNodes);
    }

    // 加上子节点之间的间距
    return totalHeight + (children.length - 1) * verticalGap;
  }

  // 获取节点的所有子节点
  static List<Node> _getChildren(Node node, List<Node> nodes) {
    return nodes.where((n) => n.parentId == node.id).toList();
  }

  // 重新布局（在节点添加/删除后调用）
  static void relayout(List<Node> nodes) {
    if (nodes.isEmpty) return;
    performLayout(nodes);
  }

  // 居中显示思维导图
  static void centerMap(List<Node> nodes, double screenWidth, double screenHeight) {
    if (nodes.isEmpty) return;

    // 计算边界
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

    final mapWidth = maxX - minX;
    final mapHeight = maxY - minY;

    // 计算偏移量
    final offsetX = (screenWidth - mapWidth) / 2 - minX;
    final offsetY = (screenHeight - mapHeight) / 2 - minY;

    // 应用偏移量
    for (final node in nodes) {
      node.x += offsetX;
      node.y += offsetY;
    }
  }
}