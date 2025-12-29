import 'package:medlistapp/models/report.dart';
import 'package:medlistapp/services/database_service.dart';
import 'package:medlistapp/services/expiry_service.dart';
import 'package:medlistapp/services/stock_service.dart';
import 'package:medlistapp/services/verification_service.dart';
import 'package:medlistapp/services/audit_service.dart';
import 'package:medlistapp/services/mims_service.dart';
import 'package:intl/intl.dart';

class ReportService {
  final DatabaseService _dbService = DatabaseService();
  final ExpiryService _expiryService = ExpiryService();
  final StockService _stockService = StockService();
  final VerificationService _verificationService = VerificationService();
  final AuditService _auditService = AuditService();
  final MimsService _mimsService = MimsService();

  // Generate expiry report
  Future<Report> generateExpiryReport(DateTime startDate, DateTime endDate) async {
    final expiringItems = await _expiryService.getExpiringIn30Days();
    final expiredItems = await _expiryService.getExpiredMedications();

    final data = {
      'expiring_count': expiringItems.length,
      'expired_count': expiredItems.length,
      'expiring_items': expiringItems.map((item) => {
        'id': item.id,
        'medication_id': item.medicationId,
        'quantity': item.quantity,
        'expiry_date': item.expiryDate.toIso8601String(),
      }).toList(),
      'expired_items': expiredItems.map((item) => {
        'id': item.id,
        'medication_id': item.medicationId,
        'quantity': item.quantity,
        'expiry_date': item.expiryDate.toIso8601String(),
      }).toList(),
    };

    final report = Report(
      type: ReportType.expiry,
      title: 'Expiry Report - ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
      data: data,
      startDate: startDate,
      endDate: endDate,
    );

    await _dbService.insertReport(report);
    return report;
  }

  // Generate stock report
  Future<Report> generateStockReport(DateTime startDate, DateTime endDate) async {
    final stockItems = await _stockService.getAllStockItems();
    final lowStockItems = await _stockService.getLowStockItems(10);

    final data = {
      'total_stock_items': stockItems.length,
      'total_quantity': stockItems.fold<int>(0, (sum, item) => sum + item.quantity),
      'low_stock_count': lowStockItems.length,
      'low_stock_items': lowStockItems.map((item) => {
        'id': item.id,
        'medication_id': item.medicationId,
        'quantity': item.quantity,
      }).toList(),
    };

    final report = Report(
      type: ReportType.stock,
      title: 'Stock Report - ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
      data: data,
      startDate: startDate,
      endDate: endDate,
    );

    await _dbService.insertReport(report);
    return report;
  }

  // Generate verification history report
  Future<Report> generateVerificationReport(DateTime startDate, DateTime endDate) async {
    final history = await _verificationService.getVerificationHistory();

    final filteredHistory = history.where((h) =>
      h.verifiedAt.isAfter(startDate) && h.verifiedAt.isBefore(endDate)
    ).toList();

    final data = {
      'total_verifications': filteredHistory.length,
      'verified_count': filteredHistory.where((h) => h.identityVerified).length,
      'contraindication_found_count': filteredHistory.where((h) => h.contraindicationFound == true).length,
      'interaction_found_count': filteredHistory.where((h) => h.interactionFound == true).length,
      'verifications': filteredHistory.map((h) => {
        'medication_name': h.medicationName,
        'identity_verified': h.identityVerified,
        'contraindication_found': h.contraindicationFound,
        'interaction_found': h.interactionFound,
        'verified_at': h.verifiedAt.toIso8601String(),
      }).toList(),
    };

    final report = Report(
      type: ReportType.verification,
      title: 'Verification Report - ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
      data: data,
      startDate: startDate,
      endDate: endDate,
    );

    await _dbService.insertReport(report);
    return report;
  }

  // Generate MIMS access log report
  Future<Report> generateMimsAccessReport(DateTime startDate, DateTime endDate) async {
    final logs = await _auditService.getAuditLogs(
      startDate: startDate,
      endDate: endDate,
      actionType: 'mims_access',
    );

    final data = {
      'total_accesses': logs.length,
      'successful_accesses': logs.where((log) => 
        log.metadata?['success'] == true
      ).length,
      'failed_accesses': logs.where((log) => 
        log.metadata?['success'] == false
      ).length,
      'accesses': logs.map((log) => {
        'drug_name': log.metadata?['drug_name'],
        'success': log.metadata?['success'],
        'timestamp': log.timestamp.toIso8601String(),
      }).toList(),
    };

    final report = Report(
      type: ReportType.mimsAccess,
      title: 'MIMS Access Report - ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
      data: data,
      startDate: startDate,
      endDate: endDate,
    );

    await _dbService.insertReport(report);
    return report;
  }

  // Generate audit log report
  Future<Report> generateAuditReport(DateTime startDate, DateTime endDate) async {
    final logs = await _auditService.getAuditLogs(
      startDate: startDate,
      endDate: endDate,
    );

    final data = {
      'total_actions': logs.length,
      'actions_by_type': _groupByActionType(logs),
      'actions': logs.map((log) => {
        'action_type': log.actionType,
        'entity_type': log.entityType,
        'description': log.description,
        'timestamp': log.timestamp.toIso8601String(),
      }).toList(),
    };

    final report = Report(
      type: ReportType.audit,
      title: 'Audit Report - ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
      data: data,
      startDate: startDate,
      endDate: endDate,
    );

    await _dbService.insertReport(report);
    return report;
  }

  Map<String, int> _groupByActionType(List logs) {
    final Map<String, int> grouped = {};
    for (final log in logs) {
      final actionType = log.actionType;
      grouped[actionType] = (grouped[actionType] ?? 0) + 1;
    }
    return grouped;
  }

  // Export report to CSV format
  String exportToCSV(Report report) {
    final buffer = StringBuffer();
    buffer.writeln(report.title);
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(report.generatedAt)}');
    buffer.writeln('');

    // Export data based on report type
    switch (report.type) {
      case ReportType.expiry:
        buffer.writeln('Expiring Items,${report.data['expiring_count']}');
        buffer.writeln('Expired Items,${report.data['expired_count']}');
        break;
      case ReportType.stock:
        buffer.writeln('Total Stock Items,${report.data['total_stock_items']}');
        buffer.writeln('Total Quantity,${report.data['total_quantity']}');
        buffer.writeln('Low Stock Items,${report.data['low_stock_count']}');
        break;
      default:
        buffer.writeln('Data: ${report.data}');
    }

    return buffer.toString();
  }

  // Get all reports
  Future<List<Report>> getAllReports({ReportType? type}) async {
    return await _dbService.getReports(type: type);
  }
}

