class AuditLog {
  final int? id;
  final String actionType; // 'create', 'update', 'delete', 'verify', 'scan', 'mims_access', etc.
  final String entityType; // 'medication', 'stock_item', 'verification', etc.
  final int? entityId;
  final String? userId;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AuditLog({
    this.id,
    required this.actionType,
    required this.entityType,
    this.entityId,
    this.userId,
    this.description,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action_type': actionType,
      'entity_type': entityType,
      'entity_id': entityId,
      'user_id': userId,
      'description': description,
      'metadata': metadata != null ? metadata.toString() : null,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'],
      actionType: map['action_type'],
      entityType: map['entity_type'],
      entityId: map['entity_id'],
      userId: map['user_id'],
      description: map['description'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

