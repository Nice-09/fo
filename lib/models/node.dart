class Node {
  String? id;
  String text;
  double x;
  double y;
  double width;
  double height;
  bool isRoot;
  String? parentId;
  String? color;
  int level;
  bool isExpanded;
  bool isCollapsed;

  Node({
    this.id,
    required this.text,
    this.x = 0,
    this.y = 0,
    this.width = 160,
    this.height = 60,
    this.isRoot = false,
    this.parentId,
    this.color,
    this.level = 0,
    this.isExpanded = true,
    this.isCollapsed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'isRoot': isRoot,
      'parentId': parentId,
      'color': color,
      'level': level,
      'isExpanded': isExpanded,
      'isCollapsed': isCollapsed,
    };
  }

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id']?.toString(),
      text: json['text'] ?? '新节点',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 160).toDouble(),
      height: (json['height'] ?? 60).toDouble(),
      isRoot: json['isRoot'] ?? false,
      parentId: json['parentId']?.toString(),
      color: json['color']?.toString(),
      level: json['level'] ?? 0,
      isExpanded: json['isExpanded'] ?? true,
      isCollapsed: json['isCollapsed'] ?? false,
    );
  }

  Node copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? width,
    double? height,
    bool? isRoot,
    String? parentId,
    String? color,
    int? level,
    bool? isExpanded,
    bool? isCollapsed,
  }) {
    return Node(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      isRoot: isRoot ?? this.isRoot,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      level: level ?? this.level,
      isExpanded: isExpanded ?? this.isExpanded,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }
}