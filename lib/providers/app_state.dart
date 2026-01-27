import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'node.dart';
import 'connection.dart';

class AppState extends ChangeNotifier {
  List<Node> nodes = [];
  List<Connection> connections = [];
  Node? selectedNode;
  double scale = 1.0;
  double panX = 0.0;
  double panY = 0.0;
  int nodeIdCounter = 0;

  // 撤销历史
  List<Map<String, dynamic>> _history = [];
  static const int _maxHistory = 50;

  AppState() {
    _loadFromStorage();
  }

  // 添加节点
  Node addNode(Node node) {
    node.id = nodeIdCounter++.toString();
    nodes.add(node);
    notifyListeners();
    return node;
  }

  // 删除节点
  void removeNode(String nodeId) {
    nodes.removeWhere((node) => node.id == nodeId);
    connections.removeWhere((conn) => conn.sourceId == nodeId || conn.targetId == nodeId);
    notifyListeners();
  }

  // 获取节点
  Node? getNode(String nodeId) {
    try {
      return nodes.firstWhere((node) => node.id == nodeId);
    } catch (e) {
      return null;
    }
  }

  // 添加连接
  void addConnection(Connection connection) {
    connections.add(connection);
    notifyListeners();
  }

  // 获取子节点
  List<Node> getChildren(String parentId) {
    return nodes.where((node) => node.parentId == parentId).toList();
  }

  // 保存状态到历史记录
  void saveState() {
    final state = {
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'connections': connections.map((conn) => conn.toJson()).toList(),
      'nodeIdCounter': nodeIdCounter,
    };

    _history.add(state);

    // 限制历史记录数量
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
  }

  // 撤销到上一个状态
  bool undo() {
    if (_history.isEmpty) {
      return false;
    }

    final prevState = _history.removeLast();

    // 恢复状态
    nodes = (prevState['nodes'] as List)
        .map((json) => Node.fromJson(json))
        .toList();
    connections = (prevState['connections'] as List)
        .map((json) => Connection.fromJson(json))
        .toList();
    nodeIdCounter = prevState['nodeIdCounter'] as int;

    notifyListeners();
    return true;
  }

  // 检查是否可以撤销
  bool canUndo() {
    return _history.isNotEmpty;
  }

  // 清空所有数据
  void clear() {
    nodes.clear();
    connections.clear();
    selectedNode = null;
    nodeIdCounter = 0;
    _history.clear();
    notifyListeners();
  }

  // 保存到本地存储
  Future<void> saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'connections': connections.map((conn) => conn.toJson()).toList(),
      'nodeIdCounter': nodeIdCounter,
    };
    await prefs.setString('mindmap_data', jsonEncode(data));
  }

  // 从本地存储加载
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('mindmap_data');

    if (dataString != null && dataString.isNotEmpty) {
      try {
        final data = jsonDecode(dataString) as Map<String, dynamic>;
        nodes = (data['nodes'] as List)
            .map((json) => Node.fromJson(json))
            .toList();
        connections = (data['connections'] as List)
            .map((json) => Connection.fromJson(json))
            .toList();
        nodeIdCounter = data['nodeIdCounter'] as int ?? 0;
      } catch (e) {
        print('加载数据失败: $e');
        _createRootNode();
      }
    } else {
      _createRootNode();
    }
  }

  // 创建根节点
  void _createRootNode() {
    final rootNode = Node(
      text: '中心主题',
      isRoot: true,
    );
    addNode(rootNode);
  }
}