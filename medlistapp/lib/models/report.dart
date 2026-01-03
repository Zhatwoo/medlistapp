enum ReportType {
  expiry,
  stock,
  stockMovement,
  verification,
  mimsAccess,
  audit,
  interaction,
}

class Report {
  final int? id;
  final ReportType type;
  final String title;
  final Map<String, dynamic> data;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;
  final String? filePath; // For exported reports

  Report({
    this.id,
    required this.type,
    required this.title,
    required this.data,
    required this.startDate,
    required this.endDate,
    DateTime? generatedAt,
    this.filePath,
  }) : generatedAt = generatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'data': data.toString(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'generated_at': generatedAt.toIso8601String(),
      'file_path': filePath,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'],
      type: ReportType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReportType.expiry,
      ),
      title: map['title'],
      data: Map<String, dynamic>.from(map['data']),
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      generatedAt: DateTime.parse(map['generated_at']),
      filePath: map['file_path'],
    );
  }
}

