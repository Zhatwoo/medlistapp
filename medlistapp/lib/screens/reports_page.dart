import 'package:flutter/material.dart';
import 'package:medlistapp/services/report_service.dart';
import 'package:medlistapp/models/report.dart';
import 'package:medlistapp/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ReportService _reportService = ReportService();
  final List<ReportType> _reportTypes = [
    ReportType.expiry,
    ReportType.stock,
    ReportType.verification,
    ReportType.mimsAccess,
    ReportType.audit,
  ];
  
  ReportType? _selectedType;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;
  List<Report> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = await _reportService.getAllReports(type: _selectedType);
    setState(() => _reports = reports);
  }

  Future<void> _generateReport() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a report type')),
      );
      return;
    }

    setState(() => _isGenerating = true);
    try {
      Report report;
      switch (_selectedType!) {
        case ReportType.expiry:
          report = await _reportService.generateExpiryReport(_startDate, _endDate);
          break;
        case ReportType.stock:
          report = await _reportService.generateStockReport(_startDate, _endDate);
          break;
        case ReportType.verification:
          report = await _reportService.generateVerificationReport(_startDate, _endDate);
          break;
        case ReportType.mimsAccess:
          report = await _reportService.generateMimsAccessReport(_startDate, _endDate);
          break;
        case ReportType.audit:
          report = await _reportService.generateAuditReport(_startDate, _endDate);
          break;
        default:
          throw Exception('Unknown report type');
      }

      setState(() {
        _reports.insert(0, report);
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully')),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  Future<void> _exportReport(Report report) async {
    try {
      final csv = _reportService.exportToCSV(report);
      await Share.share(csv, subject: report.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report type selection
            Text(
              'Report Type',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _reportTypes.map((type) {
                return FilterChip(
                  label: Text(_getReportTypeName(type)),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    setState(() => _selectedType = selected ? type : null);
                    _loadReports();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Date range
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(true),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isGenerating ? null : _generateReport,
                child: _isGenerating
                    ? const CircularProgressIndicator()
                    : const Text('Generate Report'),
              ),
            ),
            const SizedBox(height: 24),
            // Reports list
            Text(
              'Generated Reports',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_reports.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No reports generated yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
              )
            else
              ..._reports.map((report) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(report.title),
                  subtitle: Text(
                    'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(report.generatedAt)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _exportReport(report),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  String _getReportTypeName(ReportType type) {
    switch (type) {
      case ReportType.expiry:
        return 'Expiry';
      case ReportType.stock:
        return 'Stock';
      case ReportType.verification:
        return 'Verification';
      case ReportType.mimsAccess:
        return 'MIMS Access';
      case ReportType.audit:
        return 'Audit';
      case ReportType.interaction:
        return 'Interaction';
    }
  }
}

