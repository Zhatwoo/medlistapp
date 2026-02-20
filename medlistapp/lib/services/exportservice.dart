import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:medlistapp/models/report.dart';
import 'package:medlistapp/models/exportformat.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class ExportService {
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Export report to CSV string (for Share.share with text)
  Future<String> exportToCSV(Report report) async {
    final buffer = StringBuffer();
    buffer.writeln(report.title);
    buffer.writeln('Generated: ${_dateFormat.format(report.generatedAt)}');
    buffer.writeln('Period: ${DateFormat('MMM dd, yyyy').format(report.startDate)} - ${DateFormat('MMM dd, yyyy').format(report.endDate)}');
    buffer.writeln();

    switch (report.type) {
      case ReportType.expiry:
        buffer.writeln('Metric,Value');
        buffer.writeln('Expiring Items,${report.data['expiring_count'] ?? 0}');
        buffer.writeln('Expired Items,${report.data['expired_count'] ?? 0}');
        _addExpiryItemsToCsv(buffer, report.data);
        break;
      case ReportType.stock:
        buffer.writeln('Metric,Value');
        buffer.writeln('Total Stock Items,${report.data['total_stock_items'] ?? 0}');
        buffer.writeln('Total Quantity,${report.data['total_quantity'] ?? 0}');
        buffer.writeln('Low Stock Items,${report.data['low_stock_count'] ?? 0}');
        _addStockDetailsToCsv(buffer, report.data);
        _addStockItemsToCsv(buffer, report.data);
        break;
      case ReportType.stockMovement:
        buffer.writeln('Metric,Value');
        buffer.writeln('Total Adjustments,${report.data['total_adjustments'] ?? 0}');
        buffer.writeln('Total Increase,${report.data['total_increase'] ?? 0}');
        buffer.writeln('Total Decrease,${report.data['total_decrease'] ?? 0}');
        _addStockMovementToCsv(buffer, report.data);
        break;
      case ReportType.verification:
        buffer.writeln('Metric,Value');
        buffer.writeln('Total Verifications,${report.data['total_verifications'] ?? 0}');
        buffer.writeln('Verified,${report.data['verified_count'] ?? 0}');
        _addVerificationsToCsv(buffer, report.data);
        break;
      case ReportType.mimsAccess:
        buffer.writeln('Metric,Value');
        buffer.writeln('Total Accesses,${report.data['total_accesses'] ?? 0}');
        _addMimsAccessToCsv(buffer, report.data);
        break;
      case ReportType.audit:
        buffer.writeln('Metric,Value');
        buffer.writeln('Total Actions,${report.data['total_actions'] ?? 0}');
        _addAuditToCsv(buffer, report.data);
        break;
      default:
        buffer.writeln('Data,${report.data}');
    }

    return buffer.toString();
  }

  void _addExpiryItemsToCsv(StringBuffer buffer, Map<String, dynamic> data) {
    final items = data['expired_items'] as List? ?? [];
    if (items.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Expired Items Detail');
      buffer.writeln('ID,Medication ID,Quantity,Expiry Date');
      for (final item in items) {
        final m = item as Map;
        buffer.writeln('${m['id']},${m['medication_id']},${m['quantity']},${m['expiry_date']}');
      }
    }
  }

  void _addStockDetailsToCsv(StringBuffer buffer, Map<String, dynamic> data) {
    final items = data['stock_details'] as List? ?? [];
    if (items.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Stock Detail - Brand,Supplier,Generic,Quantity,Expiry,Batch');
      for (final item in items) {
        final m = item as Map;
        buffer.writeln('"${m['brand'] ?? ''}","${m['supplier'] ?? ''}","${m['generic'] ?? ''}",${m['quantity']},${m['expiry']},"${m['batch'] ?? ''}"');
      }
    }
  }

  void _addStockItemsToCsv(StringBuffer buffer, Map<String, dynamic> data) {
    final items = data['low_stock_items'] as List? ?? [];
    if (items.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Low Stock Detail');
      buffer.writeln('ID,Medication ID,Quantity');
      for (final item in items) {
        final m = item as Map;
        buffer.writeln('${m['id']},${m['medication_id']},${m['quantity']}');
      }
    }
  }

  void _addStockMovementToCsv(StringBuffer buffer, Map<String, dynamic> data) {
    final items = data['adjustments'] as List? ?? [];
    if (items.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Medication,Old Qty,New Qty,Difference,Reason,Date');
      for (final item in items) {
        final m = item as Map;
        buffer.writeln('"${m['medication_name'] ?? ''}",${m['old_quantity']},${m['new_quantity']},${m['quantity_difference']},${m['reason']},${m['adjusted_at']}');
      }
    }
  }

  void _addVerificationsToCsv(StringBuffer buffer, Map<String, dynamic> data) {
    final items = data['verifications'] as List? ?? [];
    if (items.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Medication,Verified,Contraindication,Interaction,Date');
      for (final item in items) {
        final m = item as Map;
        buffer.writeln('"${m['medication_name'] ?? ''}",${m['identity_verified']},${m['contraindication_found']},${m['interaction_found']},${m['verified_at']}');
      }
    }
  }

  void _addMimsAccessToCsv(StringBuffer buffer, Map<String, dynamic> data) {
    final items = data['accesses'] as List? ?? [];
    if (items.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Drug Name,Success,Timestamp');
      for (final item in items) {
        final m = item as Map;
        buffer.writeln('"${m['drug_name'] ?? ''}",${m['success']},${m['timestamp']}');
      }
    }
  }

  void _addAuditToCsv(StringBuffer buffer, Map<String, dynamic> data) {
    final items = data['actions'] as List? ?? [];
    if (items.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Action Type,Entity Type,Description,Timestamp');
      for (final item in items) {
        final m = item as Map;
        buffer.writeln('"${m['action_type'] ?? ''}","${m['entity_type'] ?? ''}","${m['description'] ?? ''}",${m['timestamp']}');
      }
    }
  }

  /// Export report to PDF bytes
  Future<Uint8List> exportToPDF(Report report) async {
    final pdf = pw.Document();
    final rows = <List<String>>[];

    switch (report.type) {
      case ReportType.expiry:
        rows.addAll([
          ['Metric', 'Value'],
          ['Expiring Items', '${report.data['expiring_count'] ?? 0}'],
          ['Expired Items', '${report.data['expired_count'] ?? 0}'],
        ]);
        _addExpiryRows(rows, report.data);
        break;
      case ReportType.stock:
        rows.addAll([
          ['Metric', 'Value'],
          ['Total Stock Items', '${report.data['total_stock_items'] ?? 0}'],
          ['Total Quantity', '${report.data['total_quantity'] ?? 0}'],
          ['Low Stock Items', '${report.data['low_stock_count'] ?? 0}'],
        ]);
        _addStockDetailsRows(rows, report.data);
        _addStockRows(rows, report.data);
        break;
      case ReportType.stockMovement:
        rows.addAll([
          ['Metric', 'Value'],
          ['Total Adjustments', '${report.data['total_adjustments'] ?? 0}'],
          ['Total Increase', '${report.data['total_increase'] ?? 0}'],
          ['Total Decrease', '${report.data['total_decrease'] ?? 0}'],
        ]);
        _addStockMovementRows(rows, report.data);
        break;
      case ReportType.verification:
        rows.addAll([
          ['Metric', 'Value'],
          ['Total Verifications', '${report.data['total_verifications'] ?? 0}'],
          ['Verified', '${report.data['verified_count'] ?? 0}'],
        ]);
        _addVerificationRows(rows, report.data);
        break;
      case ReportType.mimsAccess:
        rows.addAll([
          ['Total Accesses', '${report.data['total_accesses'] ?? 0}'],
        ]);
        _addMimsRows(rows, report.data);
        break;
      case ReportType.audit:
        rows.addAll([
          ['Total Actions', '${report.data['total_actions'] ?? 0}'],
        ]);
        _addAuditRows(rows, report.data);
        break;
      default:
        rows.add(['Report', report.title]);
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              report.title,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Generated: ${_dateFormat.format(report.generatedAt)}'),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: rows.map((row) => pw.TableRow(
              children: row.map((cell) => pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(cell, style: const pw.TextStyle(fontSize: 10)),
              )).toList(),
            )).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  void _addExpiryRows(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['expired_items'] as List? ?? [];
    if (items.isNotEmpty) {
      rows.add([]);
      rows.add(['ID', 'Medication ID', 'Quantity', 'Expiry Date']);
      for (final item in items) {
        final m = item as Map;
        rows.add(['${m['id']}', '${m['medication_id']}', '${m['quantity']}', '${m['expiry_date']}']);
      }
    }
  }

  void _addStockDetailsRows(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['stock_details'] as List? ?? [];
    if (items.isEmpty) return;
    rows.add([]);
    rows.add(['Brand', 'Supplier', 'Generic', 'Quantity', 'Expiry', 'Batch']);
    for (final item in items) {
      final m = item as Map;
      rows.add([
        '${m['brand'] ?? ''}',
        '${m['supplier'] ?? ''}',
        '${m['generic'] ?? ''}',
        '${m['quantity']}',
        '${m['expiry']}',
        '${m['batch'] ?? ''}',
      ]);
    }
  }

  void _addStockRows(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['low_stock_items'] as List? ?? [];
    if (items.isNotEmpty) {
      rows.add([]);
      rows.add(['ID', 'Medication ID', 'Quantity']);
      for (final item in items) {
        final m = item as Map;
        rows.add(['${m['id']}', '${m['medication_id']}', '${m['quantity']}']);
      }
    }
  }

  void _addStockMovementRows(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['adjustments'] as List? ?? [];
    if (items.isNotEmpty) {
      rows.add([]);
      rows.add(['Medication', 'Old', 'New', 'Diff', 'Reason', 'Date']);
      for (final item in items) {
        final m = item as Map;
        rows.add([
          '${m['medication_name'] ?? ''}',
          '${m['old_quantity']}',
          '${m['new_quantity']}',
          '${m['quantity_difference']}',
          '${m['reason']}',
          '${m['adjusted_at']}',
        ]);
      }
    }
  }

  void _addVerificationRows(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['verifications'] as List? ?? [];
    if (items.isNotEmpty) {
      rows.add([]);
      rows.add(['Medication', 'Verified', 'Contraindication', 'Interaction', 'Date']);
      for (final item in items) {
        final m = item as Map;
        rows.add([
          '${m['medication_name'] ?? ''}',
          '${m['identity_verified']}',
          '${m['contraindication_found']}',
          '${m['interaction_found']}',
          '${m['verified_at']}',
        ]);
      }
    }
  }

  void _addMimsRows(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['accesses'] as List? ?? [];
    if (items.isNotEmpty) {
      rows.add([]);
      rows.add(['Drug Name', 'Success', 'Timestamp']);
      for (final item in items) {
        final m = item as Map;
        rows.add(['${m['drug_name'] ?? ''}', '${m['success']}', '${m['timestamp']}']);
      }
    }
  }

  void _addAuditRows(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['actions'] as List? ?? [];
    if (items.isNotEmpty) {
      rows.add([]);
      rows.add(['Action', 'Entity', 'Description', 'Timestamp']);
      for (final item in items) {
        final m = item as Map;
        rows.add([
          '${m['action_type'] ?? ''}',
          '${m['entity_type'] ?? ''}',
          '${m['description'] ?? ''}',
          '${m['timestamp']}',
        ]);
      }
    }
  }

  /// Export report to Excel (XLSX) bytes
  Future<Uint8List> exportToExcel(Report report) async {
    final excel = Excel.createExcel();
    final sheetName = excel.tables.keys.isEmpty ? 'Sheet1' : excel.tables.keys.first;
    final sheet = excel[sheetName];

    int row = 0;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue(report.title);
    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Generated: ${_dateFormat.format(report.generatedAt)}');
    row += 2;

    switch (report.type) {
      case ReportType.expiry:
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Metric');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('Value');
        row++;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Expiring Items');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['expiring_count'] ?? 0}');
        row++;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Expired Items');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['expired_count'] ?? 0}');
        row++;
        _addExpiryToExcel(sheet, report.data, row);
        break;
      case ReportType.stock:
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Metric');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('Value');
        row++;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Total Stock Items');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['total_stock_items'] ?? 0}');
        row++;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Total Quantity');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['total_quantity'] ?? 0}');
        row++;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Low Stock Items');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['low_stock_count'] ?? 0}');
        row++;
        _addStockDetailsToExcel(sheet, report.data, row);
        _addStockToExcel(sheet, report.data, row);
        break;
      case ReportType.stockMovement:
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Total Adjustments');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['total_adjustments'] ?? 0}');
        row++;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Total Increase');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['total_increase'] ?? 0}');
        row++;
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Total Decrease');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['total_decrease'] ?? 0}');
        row++;
        _addStockMovementToExcel(sheet, report.data, row);
        break;
      case ReportType.verification:
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Total Verifications');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['total_verifications'] ?? 0}');
        row++;
        _addVerificationToExcel(sheet, report.data, row);
        break;
      case ReportType.mimsAccess:
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Total Accesses');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['total_accesses'] ?? 0}');
        row++;
        _addMimsToExcel(sheet, report.data, row);
        break;
      case ReportType.audit:
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Total Actions');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue('${report.data['total_actions'] ?? 0}');
        row++;
        _addAuditToExcel(sheet, report.data, row);
        break;
      default:
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue('Report: ${report.title}');
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }

  void _addExpiryToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final items = data['expired_items'] as List? ?? [];
    if (items.isEmpty) return;
    int r = startRow + 1;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('ID');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('Medication ID');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('Quantity');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = TextCellValue('Expiry Date');
    r++;
    for (final item in items) {
      final m = item as Map;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('${m['id']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('${m['medication_id']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('${m['quantity']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = TextCellValue('${m['expiry_date']}');
      r++;
    }
  }

  void _addStockDetailsToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final items = data['stock_details'] as List? ?? [];
    if (items.isEmpty) return;
    int r = startRow + 1;
    final headers = ['Brand', 'Supplier', 'Generic', 'Quantity', 'Expiry', 'Batch'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).value = TextCellValue(headers[c]);
    }
    r++;
    for (final item in items) {
      final m = item as Map;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('${m['brand'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('${m['supplier'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('${m['generic'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = TextCellValue('${m['quantity']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r)).value = TextCellValue('${m['expiry']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r)).value = TextCellValue('${m['batch'] ?? ''}');
      r++;
    }
  }

  void _addStockToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final items = data['low_stock_items'] as List? ?? [];
    if (items.isEmpty) return;
    int r = startRow + 1;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('ID');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('Medication ID');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('Quantity');
    r++;
    for (final item in items) {
      final m = item as Map;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('${m['id']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('${m['medication_id']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('${m['quantity']}');
      r++;
    }
  }

  void _addStockMovementToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final items = data['adjustments'] as List? ?? [];
    if (items.isEmpty) return;
    int r = startRow + 1;
    final headers = ['Medication', 'Old', 'New', 'Diff', 'Reason', 'Date'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).value = TextCellValue(headers[c]);
    }
    r++;
    for (final item in items) {
      final m = item as Map;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('${m['medication_name'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('${m['old_quantity'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('${m['new_quantity'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = TextCellValue('${m['quantity_difference'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r)).value = TextCellValue('${m['reason'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r)).value = TextCellValue('${m['adjusted_at'] ?? ''}');
      r++;
    }
  }

  void _addVerificationToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final items = data['verifications'] as List? ?? [];
    if (items.isEmpty) return;
    int r = startRow + 1;
    final headers = ['Medication', 'Verified', 'Contraindication', 'Interaction', 'Date'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).value = TextCellValue(headers[c]);
    }
    r++;
    for (final item in items) {
      final m = item as Map;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('${m['medication_name'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('${m['identity_verified']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('${m['contraindication_found']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = TextCellValue('${m['interaction_found']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r)).value = TextCellValue('${m['verified_at']}');
      r++;
    }
  }

  void _addMimsToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final items = data['accesses'] as List? ?? [];
    if (items.isEmpty) return;
    int r = startRow + 1;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('Drug Name');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('Success');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('Timestamp');
    r++;
    for (final item in items) {
      final m = item as Map;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('${m['drug_name'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('${m['success']}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('${m['timestamp']}');
      r++;
    }
  }

  void _addAuditToExcel(Sheet sheet, Map<String, dynamic> data, int startRow) {
    final items = data['actions'] as List? ?? [];
    if (items.isEmpty) return;
    int r = startRow + 1;
    final headers = ['Action', 'Entity', 'Description', 'Timestamp'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).value = TextCellValue(headers[c]);
    }
    r++;
    for (final item in items) {
      final m = item as Map;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value = TextCellValue('${m['action_type'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value = TextCellValue('${m['entity_type'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r)).value = TextCellValue('${m['description'] ?? ''}');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r)).value = TextCellValue('${m['timestamp']}');
      r++;
    }
  }

  /// Export report to Word (HTML-based .doc, opens in Word)
  Future<Uint8List> exportToWord(Report report) async {
    final buffer = StringBuffer();
    buffer.writeln('<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word">');
    buffer.writeln('<head><meta charset="utf-8"><title>${report.title}</title></head><body>');
    buffer.writeln('<h1>${report.title}</h1>');
    buffer.writeln('<p>Generated: ${_dateFormat.format(report.generatedAt)}</p>');
    buffer.writeln('<p>Period: ${DateFormat('MMM dd, yyyy').format(report.startDate)} - ${DateFormat('MMM dd, yyyy').format(report.endDate)}</p>');
    buffer.writeln('<table border="1" cellpadding="4" cellspacing="0">');

    final rows = <List<String>>[];
    switch (report.type) {
      case ReportType.expiry:
        rows.addAll([['Metric', 'Value'], ['Expiring Items', '${report.data['expiring_count'] ?? 0}'], ['Expired Items', '${report.data['expired_count'] ?? 0}']]);
        _addExpiryRowsToWord(rows, report.data);
        break;
      case ReportType.stock:
        rows.addAll([['Metric', 'Value'], ['Total Stock Items', '${report.data['total_stock_items'] ?? 0}'], ['Total Quantity', '${report.data['total_quantity'] ?? 0}'], ['Low Stock Items', '${report.data['low_stock_count'] ?? 0}']]);
        _addStockDetailsRowsToWord(rows, report.data);
        _addStockRowsToWord(rows, report.data);
        break;
      case ReportType.stockMovement:
        rows.addAll([['Metric', 'Value'], ['Total Adjustments', '${report.data['total_adjustments'] ?? 0}'], ['Total Increase', '${report.data['total_increase'] ?? 0}'], ['Total Decrease', '${report.data['total_decrease'] ?? 0}']]);
        _addStockMovementRowsToWord(rows, report.data);
        break;
      case ReportType.verification:
        rows.addAll([['Total Verifications', '${report.data['total_verifications'] ?? 0}'], ['Verified', '${report.data['verified_count'] ?? 0}']]);
        _addVerificationRowsToWord(rows, report.data);
        break;
      case ReportType.mimsAccess:
        rows.add(['Total Accesses', '${report.data['total_accesses'] ?? 0}']);
        _addMimsRowsToWord(rows, report.data);
        break;
      case ReportType.audit:
        rows.add(['Total Actions', '${report.data['total_actions'] ?? 0}']);
        _addAuditRowsToWord(rows, report.data);
        break;
      default:
        rows.add(['Report', report.title]);
    }

    for (final row in rows) {
      buffer.writeln('<tr>');
      for (final cell in row) {
        buffer.writeln('<td>${_escapeHtml(cell)}</td>');
      }
      buffer.writeln('</tr>');
    }
    buffer.writeln('</table></body></html>');
    return Uint8List.fromList(buffer.toString().codeUnits);
  }

  String _escapeHtml(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

  void _addExpiryRowsToWord(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['expired_items'] as List? ?? [];
    if (items.isEmpty) return;
    rows.add([]);
    rows.add(['ID', 'Medication ID', 'Quantity', 'Expiry Date']);
    for (final item in items) {
      final m = item as Map;
      rows.add(['${m['id']}', '${m['medication_id']}', '${m['quantity']}', '${m['expiry_date']}']);
    }
  }

  void _addStockDetailsRowsToWord(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['stock_details'] as List? ?? [];
    if (items.isEmpty) return;
    rows.add([]);
    rows.add(['Brand', 'Supplier', 'Generic', 'Quantity', 'Expiry', 'Batch']);
    for (final item in items) {
      final m = item as Map;
      rows.add(['${m['brand'] ?? ''}', '${m['supplier'] ?? ''}', '${m['generic'] ?? ''}', '${m['quantity']}', '${m['expiry']}', '${m['batch'] ?? ''}']);
    }
  }

  void _addStockRowsToWord(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['low_stock_items'] as List? ?? [];
    if (items.isEmpty) return;
    rows.add([]);
    rows.add(['ID', 'Medication ID', 'Quantity']);
    for (final item in items) {
      final m = item as Map;
      rows.add(['${m['id']}', '${m['medication_id']}', '${m['quantity']}']);
    }
  }

  void _addStockMovementRowsToWord(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['adjustments'] as List? ?? [];
    if (items.isEmpty) return;
    rows.add([]);
    rows.add(['Medication', 'Old', 'New', 'Diff', 'Reason', 'Date']);
    for (final item in items) {
      final m = item as Map;
      rows.add(['${m['medication_name'] ?? ''}', '${m['old_quantity']}', '${m['new_quantity']}', '${m['quantity_difference']}', '${m['reason']}', '${m['adjusted_at']}']);
    }
  }

  void _addVerificationRowsToWord(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['verifications'] as List? ?? [];
    if (items.isEmpty) return;
    rows.add([]);
    rows.add(['Medication', 'Verified', 'Contraindication', 'Interaction', 'Date']);
    for (final item in items) {
      final m = item as Map;
      rows.add(['${m['medication_name'] ?? ''}', '${m['identity_verified']}', '${m['contraindication_found']}', '${m['interaction_found']}', '${m['verified_at']}']);
    }
  }

  void _addMimsRowsToWord(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['accesses'] as List? ?? [];
    if (items.isEmpty) return;
    rows.add([]);
    rows.add(['Drug Name', 'Success', 'Timestamp']);
    for (final item in items) {
      final m = item as Map;
      rows.add(['${m['drug_name'] ?? ''}', '${m['success']}', '${m['timestamp']}']);
    }
  }

  void _addAuditRowsToWord(List<List<String>> rows, Map<String, dynamic> data) {
    final items = data['actions'] as List? ?? [];
    if (items.isEmpty) return;
    rows.add([]);
    rows.add(['Action', 'Entity', 'Description', 'Timestamp']);
    for (final item in items) {
      final m = item as Map;
      rows.add(['${m['action_type'] ?? ''}', '${m['entity_type'] ?? ''}', '${m['description'] ?? ''}', '${m['timestamp']}']);
    }
  }

  /// Share file bytes via share_plus (includes Email option in share sheet)
  Future<void> shareFile(Uint8List bytes, ExportFormat format) async {
    final ext = format.extension;
    final name = 'report_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final xFile = XFile.fromData(
      bytes,
      mimeType: format.mimeType,
      name: name,
    );
    await Share.shareXFiles([xFile], text: 'MedList Report - Share via Email or save');
  }
}
