import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'models/node.dart';
import 'models/connection.dart';
import 'widgets/mind_map_painter.dart';
import 'services/layout_service.dart';
import 'services/pdf_service.dart';
import 'package:open_file/open_file.dart';

class MindMapScreen extends StatefulWidget {
  const MindMapScreen({super.key});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  double _scale = 1.0;
  double _panX = 0.0;
  double _panY = 0.0;
  Node? _selectedNode;
  Node? _draggingNode;
  Offset _dragStartOffset = Offset.zero;
  Offset _panStartOffset = Offset.zero;
  double _scaleStart = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLayout();
    });
  }

  void _initializeLayout() {
    final appState = context.read<AppState>();
    if (appState.nodes.isNotEmpty) {
      LayoutService.relayout(appState.nodes);
      final size = MediaQuery.of(context).size;
      LayoutService.centerMap(appState.nodes, size.width, size.height);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('思维导图'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addChildNode,
            tooltip: '添加子节点',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteNode,
            tooltip: '删除节点',
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: '保存',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPDF,
            tooltip: '导出PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeLayout,
            tooltip: '重新布局',
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final visibleNodes = _getVisibleNodes(appState.nodes);

          return GestureDetector(
            // 处理缩放
            onScaleStart: (details) {
              _scaleStart = _scale;
              _panStartOffset = details.localFocalPoint;
            },
            onScaleUpdate: (details) {
              setState(() {
                _scale = _scaleStart * details.scale;
                _panX += details.focalPointDelta.dx;
                _panY += details.focalPointDelta.dy;
              });
            },
            onScaleEnd: (details) {
              appState.scale = _scale;
              appState.panX = _panX;
              appState.panY = _panY;
            },
            // 处理拖拽平移
            onPanStart: (details) {
              final hitNode = _hitTestNode(details.localPosition, visibleNodes);
              if (hitNode != null) {
                // 检查是否点击了折叠/展开按钮
                if (_isCollapseButtonHit(details.localPosition, hitNode)) {
                  _toggleCollapse(hitNode);
                } else {
                  _draggingNode = hitNode;
                  _dragStartOffset = details.localPosition;
                }
              } else {
                _panStartOffset = details.localPosition;
              }
            },
            onPanUpdate: (details) {
              if (_draggingNode != null) {
                // 拖拽节点
                final deltaX = details.localPosition.dx - _dragStartOffset.dx;
                final deltaY = details.localPosition.dy - _dragStartOffset.dy;
                setState(() {
                  _draggingNode!.x += deltaX / _scale;
                  _draggingNode!.y += deltaY / _scale;
                  _dragStartOffset = details.localPosition;
                });
              } else {
                // 拖拽画布
                setState(() {
                  _panX += details.localPosition.dx - _panStartOffset.dx;
                  _panY += details.localPosition.dy - _panStartOffset.dy;
                  _panStartOffset = details.localPosition;
                });
              }
            },
            onPanEnd: (details) {
              if (_draggingNode != null) {
                appState.notifyListeners();
              }
              _draggingNode = null;
              appState.panX = _panX;
              appState.panY = _panY;
            },
            // 处理点击选择
            onTapUp: (details) {
              final hitNode = _hitTestNode(details.localPosition, visibleNodes);
              setState(() {
                // 取消之前选中的节点
                if (_selectedNode != null) {
                  _selectedNode!.isSelected = false;
                }
                // 选中新节点
                if (hitNode != null) {
                  hitNode.isSelected = true;
                  _selectedNode = hitNode;
                } else {
                  _selectedNode = null;
                }
              });
              appState.notifyListeners();
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: MindMapPainter(
                nodes: appState.nodes,
                connections: appState.connections,
                visibleNodes: visibleNodes,
                scale: _scale,
                panX: _panX,
                panY: _panY,
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetView,
        tooltip: '重置视图',
        child: const Icon(Icons.center_focus_strong),
      ),
    );
  }

  List<Node> _getVisibleNodes(List<Node> nodes) {
    final visible = <Node>[];
    final root = nodes.firstWhere((n) => n.isRoot);
    _collectVisible(root, nodes, visible);
    return visible;
  }

  void _collectVisible(Node node, List<Node> nodes, List<Node> visible) {
    visible.add(node);
    if (!node.isCollapsed) {
      final children = nodes.where((n) => n.parentId == node.id).toList();
      for (final child in children) {
        _collectVisible(child, nodes, visible);
      }
    }
  }

  bool _isCollapseButtonHit(Offset position, Node node) {
    final buttonSize = 20.0 * _scale;
    final buttonX = node.x * _scale + _panX - buttonSize - 8;
    final buttonY = node.y * _scale + _panY + (node.height * _scale - buttonSize) / 2;
    final buttonRect = Rect.fromLTWH(buttonX, buttonY, buttonSize, buttonSize);
    return buttonRect.contains(position);
  }

  void _toggleCollapse(Node node) {
    if (node.isRoot) return;

    final appState = context.read<AppState>();
    appState.saveState();

    // 切换折叠状态
    node.isCollapsed = !node.isCollapsed;
    node.isExpanded = !node.isCollapsed;

    // 重新布局
    LayoutService.relayout(appState.nodes);
    setState(() {});
    appState.notifyListeners();
  }

  Node? _hitTestNode(Offset position, List<Node> visibleNodes) {
    for (final node in visibleNodes.reversed) {
      final rect = Rect.fromLTWH(
        node.x * _scale + _panX,
        node.y * _scale + _panY,
        node.width * _scale,
        node.height * _scale,
      );
      if (rect.contains(position)) {
        return node;
      }
    }
    return null;
  }

  void _addChildNode() {
    if (_selectedNode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个节点')),
      );
      return;
    }

    final appState = context.read<AppState>();
    appState.saveState();

    final newNode = Node(
      text: '新节点',
      isRoot: false,
      parentId: _selectedNode!.id,
      level: _selectedNode!.level + 1,
      isExpanded: true,
      isCollapsed: false,
    );

    appState.addNode(newNode);
    appState.addConnection(Connection(
      sourceId: _selectedNode!.id!,
      targetId: newNode.id!,
    ));

    // 重新布局
    LayoutService.relayout(appState.nodes);
    setState(() {});
  }

  void _deleteNode() {
    if (_selectedNode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个节点')),
      );
      return;
    }

    if (_selectedNode!.isRoot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('不能删除根节点')),
      );
      return;
    }

    final appState = context.read<AppState>();
    appState.saveState();

    appState.removeNode(_selectedNode!.id!);

    // 重新布局
    LayoutService.relayout(appState.nodes);
    setState(() {});

    _selectedNode = null;
  }

  void _undo() {
    final appState = context.read<AppState>();
    if (appState.undo()) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已撤销')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可撤销的操作')),
      );
    }
  }

  void _save() async {
    final appState = context.read<AppState>();
    await appState.saveToStorage();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已保存')),
    );
  }

  void _exportPDF() async {
    final appState = context.read<AppState>();

    try {
      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 导出PDF
      final path = await PDFService.exportToPDF(
        appState.nodes,
        appState.connections,
      );

      // 关闭加载指示器
      Navigator.pop(context);

      // 打开PDF文件
      final result = await OpenFile.open(path);

      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF导出成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF导出失败: ${result.message}')),
        );
      }
    } catch (e) {
      // 关闭加载指示器
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF导出错误: $e')),
      );
    }
  }

  void _resetView() {
    setState(() {
      _scale = 1.0;
      _panX = 0.0;
      _panY = 0.0;
    });
    _initializeLayout();
  }
}