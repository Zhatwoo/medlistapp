import 'dart:convert';

enum NotificationType {
  expiry,
  lowStock,
  system,
}

class AppNotification {
  final int? id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;

  AppNotification({
    this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.scheduledAt,
    this.sentAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data != null ? _mapToJson(data!) : null,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Create from Map (database)
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      title: map['title'] as String,
      body: map['body'] as String,
      data: map['data'] != null ? _jsonToMap(map['data'] as String) : null,
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'] as String)
          : null,
      sentAt: map['sent_at'] != null
          ? DateTime.parse(map['sent_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() => toMap();

  // Create from JSON
  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification.fromMap(json);

  // Create a copy with updated fields
  AppNotification copyWith({
    int? id,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? scheduledAt,
    DateTime? sentAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods for JSON conversion
  static String _mapToJson(Map<String, dynamic> map) {
    if (map.isEmpty) return '{}';
    return jsonEncode(map);
  }

  static Map<String, dynamic> _jsonToMap(String? json) {
    if (json == null || json.isEmpty || json == '{}') return {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}

