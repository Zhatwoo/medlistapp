import 'package:flutter/material.dart';
import 'package:medlistapp/services/auditservice.dart';
import 'package:medlistapp/models/auditlog.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:intl/intl.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  final AuditService _auditService = AuditService();
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  String? _selectedActionType;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _actionTypes = [
    'create',
    'update',
    'delete',
    'verify',
    'barcode_scan',
    'mims_access',
    'stock_adjust',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _auditService.getAuditLogs(
        startDate: _startDate,
        endDate: _endDate,
        actionType: _selectedActionType,
      );
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logs: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
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
      _loadLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.pureWhite,
            child: Column(
              children: [
                // Action type filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _actionTypes.length,
                    itemBuilder: (context, index) {
                      final type = _actionTypes[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type),
                          selected: _selectedActionType == type,
                          onSelected: (selected) {
                            setState(() => _selectedActionType = selected ? type : null);
                            _loadLogs();
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Date filters
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_startDate != null
                            ? DateFormat('MMM dd').format(_startDate!)
                            : 'Start Date'),
                        onPressed: () => _selectDate(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_endDate != null
                            ? DateFormat('MMM dd').format(_endDate!)
                            : 'End Date'),
                        onPressed: () => _selectDate(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectedActionType = null;
                        });
                        _loadLogs();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No audit logs found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.mediumGray,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Icon(
                                  _getActionIcon(log.actionType),
                                  color: _getActionColor(log.actionType),
                                ),
                                title: Text(log.actionType.toUpperCase()),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (log.description != null)
                                      Text(log.description!),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${log.entityType}${log.entityId != null ? " #${log.entityId}" : ""}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      DateFormat('MMM dd, yyyy HH:mm:ss').format(log.timestamp),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.mediumGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'verify':
        return Icons.verified;
      case 'barcode_scan':
        return Icons.qr_code_scanner;
      case 'mims_access':
        return Icons.search;
      case 'stock_adjust':
        return Icons.inventory;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'create':
        return AppColors.successGreen;
      case 'update':
        return AppColors.skyBlue;
      case 'delete':
        return AppColors.errorRed;
      case 'verify':
        return AppColors.successGreen;
      default:
        return AppColors.mediumGray;
    }
  }
}

