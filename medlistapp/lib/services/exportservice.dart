import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:medlistapp/models/report.dart';
import 'package:medlistapp/models/exportformat.dart';
import 'package:medlistapp/services/reportservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/services/patientservice.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:intl/intl.dart';

class ExportService {
  final ReportService _reportService = ReportService();
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();
  final PatientService _patientService = PatientService();
  final DatabaseService _dbService = DatabaseService();

  // Export report to CSV
  Future<String> exportToCSV(Report report) async {
    return _reportService.exportToCSV(report);
  }

  // Export report to PDF
  Future<File> exportToPDF(Report report) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Get detailed data for the report
    final detailedData = await _getDetailedReportData(report);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    report.title,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    dateTimeFormat.format(report.generatedAt),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            // Date range
            pw.Text(
              'Period: ${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            // Report content based on type
            ..._buildPDFContent(report, detailedData),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${report.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Export report to Excel
  Future<File> exportToExcel(Report report) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1'); // Delete default sheet

    // Get detailed data for the report
    final detailedData = await _getDetailedReportData(report);

    // Create sheet with report name
    final sheetName = _getSheetName(report.type);
    final sheet = excel[sheetName];

    // Add header
    sheet.appendRow([report.title]);
    sheet.appendRow(['Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(report.generatedAt)}']);
    sheet.appendRow(['Period: ${DateFormat('MMM dd, yyyy').format(report.startDate)} - ${DateFormat('MMM dd, yyyy').format(report.endDate)}']);
    sheet.appendRow([]); // Empty row

    // Add content based on report type
    _buildExcelContent(sheet, report, detailedData);

    // Save Excel file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${report.title.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory.path}/$fileName');
    final excelBytes = excel.save();
    if (excelBytes != null) {
      await file.writeAsBytes(excelBytes);
    }

    return file;
  }

  // Export all data to CSV
  Future<String> exportAllDataToCSV() async {
    final buffer = StringBuffer();
    buffer.writeln('MedList App - Complete Data Export');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    buffer.writeln('');

    // Export medications
    final medications = await _medicationService.getAllMedications();
    buffer.writeln('=== MEDICATIONS ===');
    buffer.writeln('ID,Trade Name,Active Ingredient,Form,Strength,Company');
    for (final med in medications) {
      buffer.writeln('${med.id},${med.tradeName},${med.activeIngredient},${med.form},${med.strength},${med.company}');
    }
    buffer.writeln('');

    // Export stock items
    final stockItems = await _stockService.getAllStockItems();
    buffer.writeln('=== STOCK ITEMS ===');
    buffer.writeln('ID,Medication ID,Quantity,Expiry Date,Batch Number');
    for (final item in stockItems) {
      buffer.writeln('${item.id},${item.medicationId},${item.quantity},${item.expiryDate.toIso8601String()},${item.batchNumber ?? ''}');
    }
    buffer.writeln('');

    // Export patients
    final patients = await _patientService.getAllPatients();
    buffer.writeln('=== PATIENTS ===');
    buffer.writeln('ID,Name,Age,Gender,Weight,Allergies,Conditions');
    for (final patient in patients) {
      buffer.writeln('${patient.id},${patient.name},${patient.age},${patient.gender},${patient.weight ?? ''},${patient.allergies.join(';')},${patient.conditions.join(';')}');
    }

    return buffer.toString();
  }

  // Export all data to PDF
  Future<File> exportAllDataToPDF() async {
    final pdf = pw.Document();
    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Get all data
    final medications = await _medicationService.getAllMedications();
    final stockItems = await _stockService.getAllStockItems();
    final patients = await _patientService.getAllPatients();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'MedList App - Complete Data Export',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Text(
              'Generated: ${dateTimeFormat.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 30),
            // Medications section
            pw.Text(
              'MEDICATIONS (${medications.length})',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Trade Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Active Ingredient', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Form', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...medications.take(50).map((med) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(med.tradeName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(med.activeIngredient),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(med.form),
                    ),
                  ],
                )),
              ],
            ),
            if (medications.length > 50)
              pw.Text('... and ${medications.length - 50} more medications'),
            pw.SizedBox(height: 20),
            // Stock items section
            pw.Text(
              'STOCK ITEMS (${stockItems.length})',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Total stock items: ${stockItems.length}'),
            pw.SizedBox(height: 20),
            // Patients section
            pw.Text(
              'PATIENTS (${patients.length})',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Total patients: ${patients.length}'),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'MedList_Complete_Export_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Export all data to Excel
  Future<File> exportAllDataToExcel() async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    // Get all data
    final medications = await _medicationService.getAllMedications();
    final stockItems = await _stockService.getAllStockItems();
    final patients = await _patientService.getAllPatients();

    // Medications sheet
    final medSheet = excel['Medications'];
    medSheet.appendRow(['ID', 'Trade Name', 'Active Ingredient', 'Form', 'Strength', 'Company']);
    for (final med in medications) {
      medSheet.appendRow([
        med.id,
        med.tradeName,
        med.activeIngredient,
        med.form,
        med.strength,
        med.company,
      ]);
    }

    // Stock items sheet
    final stockSheet = excel['Stock Items'];
    stockSheet.appendRow(['ID', 'Medication ID', 'Quantity', 'Expiry Date', 'Batch Number']);
    for (final item in stockItems) {
      stockSheet.appendRow([
        item.id,
        item.medicationId,
        item.quantity,
        DateFormat('yyyy-MM-dd').format(item.expiryDate),
        item.batchNumber ?? '',
      ]);
    }

    // Patients sheet
    final patientSheet = excel['Patients'];
    patientSheet.appendRow(['ID', 'Name', 'Age', 'Gender', 'Weight', 'Allergies', 'Conditions']);
    for (final patient in patients) {
      patientSheet.appendRow([
        patient.id,
        patient.name,
        patient.age,
        patient.gender,
        patient.weight ?? '',
        patient.allergies.join('; '),
        patient.conditions.join('; '),
      ]);
    }

    // Summary sheet
    final summarySheet = excel['Summary'];
    summarySheet.appendRow(['MedList App - Complete Data Export']);
    summarySheet.appendRow(['Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}']);
    summarySheet.appendRow([]);
    summarySheet.appendRow(['Total Medications', medications.length]);
    summarySheet.appendRow(['Total Stock Items', stockItems.length]);
    summarySheet.appendRow(['Total Patients', patients.length]);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'MedList_Complete_Export_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File('${directory.path}/$fileName');
    final excelBytes = excel.save();
    if (excelBytes != null) {
      await file.writeAsBytes(excelBytes);
    }

    return file;
  }

  // Share exported file
  Future<void> shareFile(File file, ExportFormat format) async {
    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      subject: file.path.split('/').last,
    );
  }

  // Helper methods
  Future<Map<String, dynamic>> _getDetailedReportData(Report report) async {
    final data = <String, dynamic>{};

    switch (report.type) {
      case ReportType.expiry:
        final expiringItems = report.data['expiring_items'] as List? ?? [];
        final expiredItems = report.data['expired_items'] as List? ?? [];
        
        // Get medication details
        final expiringDetails = <Map<String, dynamic>>[];
        for (final item in expiringItems) {
          final medication = await _medicationService.getMedicationById(item['medication_id'] as int);
          if (medication != null) {
            expiringDetails.add({
              'medication': medication.tradeName,
              'quantity': item['quantity'],
              'expiry_date': item['expiry_date'],
            });
          }
        }

        final expiredDetails = <Map<String, dynamic>>[];
        for (final item in expiredItems) {
          final medication = await _medicationService.getMedicationById(item['medication_id'] as int);
          if (medication != null) {
            expiredDetails.add({
              'medication': medication.tradeName,
              'quantity': item['quantity'],
              'expiry_date': item['expiry_date'],
            });
          }
        }

        data['expiring_details'] = expiringDetails;
        data['expired_details'] = expiredDetails;
        break;

      case ReportType.stock:
        // Add stock details if needed
        break;

      default:
        break;
    }

    return data;
  }

  List<pw.Widget> _buildPDFContent(Report report, Map<String, dynamic> detailedData) {
    switch (report.type) {
      case ReportType.expiry:
        return [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Expiring Items: ${report.data['expiring_count'] ?? 0}'),
          pw.Text('Expired Items: ${report.data['expired_count'] ?? 0}'),
          pw.SizedBox(height: 20),
          if (detailedData['expiring_details'] != null && (detailedData['expiring_details'] as List).isNotEmpty)
            ..._buildExpiryTable('Expiring Items', (detailedData['expiring_details'] as List?)?.cast<Map<String, dynamic>>() ?? []),
          if (detailedData['expired_details'] != null && (detailedData['expired_details'] as List).isNotEmpty)
            ..._buildExpiryTable('Expired Items', (detailedData['expired_details'] as List).cast<Map<String, dynamic>>()),
        ];

      case ReportType.stock:
        return [
          pw.Text(
            'Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Total Stock Items: ${report.data['total_stock_items'] ?? 0}'),
          pw.Text('Total Quantity: ${report.data['total_quantity'] ?? 0}'),
          pw.Text('Low Stock Items: ${report.data['low_stock_count'] ?? 0}'),
        ];

      default:
        return [
          pw.Text('Report Data: ${report.data}'),
        ];
    }
  }

  List<pw.Widget> _buildExpiryTable(String title, List<Map<String, dynamic>> items) {
    return [
      pw.SizedBox(height: 20),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 10),
      pw.Table(
        border: pw.TableBorder.all(),
        children: [
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Medication', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text('Expiry Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          ...items.map((item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item['medication']?.toString() ?? ''),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item['quantity']?.toString() ?? ''),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(item['expiry_date']?.toString() ?? ''),
              ),
            ],
          )),
        ],
      ),
    ];
  }

  void _buildExcelContent(dynamic sheet, Report report, Map<String, dynamic> detailedData) {
    switch (report.type) {
      case ReportType.expiry:
        sheet.appendRow(['Summary']);
        sheet.appendRow(['Expiring Items', report.data['expiring_count'] ?? 0]);
        sheet.appendRow(['Expired Items', report.data['expired_count'] ?? 0]);
        sheet.appendRow([]);

        if (detailedData['expiring_details'] != null && (detailedData['expiring_details'] as List).isNotEmpty) {
          sheet.appendRow(['Expiring Items']);
          sheet.appendRow(['Medication', 'Quantity', 'Expiry Date']);
          for (final item in detailedData['expiring_details'] as List) {
            sheet.appendRow([
              item['medication']?.toString() ?? '',
              item['quantity']?.toString() ?? '',
              item['expiry_date']?.toString() ?? '',
            ]);
          }
          sheet.appendRow([]);
        }

        if (detailedData['expired_details'] != null && (detailedData['expired_details'] as List).isNotEmpty) {
          sheet.appendRow(['Expired Items']);
          sheet.appendRow(['Medication', 'Quantity', 'Expiry Date']);
          for (final item in detailedData['expired_details'] as List) {
            sheet.appendRow([
              item['medication']?.toString() ?? '',
              item['quantity']?.toString() ?? '',
              item['expiry_date']?.toString() ?? '',
            ]);
          }
        }
        break;

      case ReportType.stock:
        sheet.appendRow(['Summary']);
        sheet.appendRow(['Total Stock Items', report.data['total_stock_items'] ?? 0]);
        sheet.appendRow(['Total Quantity', report.data['total_quantity'] ?? 0]);
        sheet.appendRow(['Low Stock Items', report.data['low_stock_count'] ?? 0]);
        break;

      default:
        sheet.appendRow(['Report Data']);
        sheet.appendRow([report.data.toString()]);
    }
  }

  String _getSheetName(ReportType type) {
    switch (type) {
      case ReportType.expiry:
        return 'Expiry Report';
      case ReportType.stock:
        return 'Stock Report';
      case ReportType.verification:
        return 'Verification Report';
      case ReportType.mimsAccess:
        return 'MIMS Access Report';
      case ReportType.audit:
        return 'Audit Report';
      case ReportType.interaction:
        return 'Interaction Report';
    }
  }
}

