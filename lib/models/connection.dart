class Connection {
  String sourceId;
  String targetId;
  String get id => '$sourceId-$targetId';

  Connection({
    required this.sourceId,
    required this.targetId,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'targetId': targetId,
    };
  }

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      sourceId: json['sourceId'].toString(),
      targetId: json['targetId'].toString(),
    );
  }
}