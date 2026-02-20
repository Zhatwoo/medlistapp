import 'package:flutter/material.dart';
import 'package:medlistapp/models/patient.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/screens/diagnosishelperpage.dart';

class PatientProfilePage extends StatefulWidget {
  final Patient? patient;

  const PatientProfilePage({super.key, this.patient});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _allergiesController;
  late TextEditingController _conditionsController;
  late TextEditingController _medicationsController;
  late TextEditingController _notesController;
  String? _gender;
  bool _saving = false;

  bool get _isEditing => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameController = TextEditingController(text: p?.name ?? '');
    _ageController = TextEditingController(text: p?.age?.toString() ?? '');
    _weightController = TextEditingController(
      text: p?.weight != null ? p!.weight.toString() : '',
    );
    _allergiesController = TextEditingController(
      text: p?.allergies.join(', ') ?? '',
    );
    _conditionsController = TextEditingController(
      text: p?.conditions.join(', ') ?? '',
    );
    _medicationsController = TextEditingController(
      text: p?.medications.join(', ') ?? '',
    );
    _notesController = TextEditingController(text: p?.notes ?? '');
    _gender = p?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _medicationsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<String> _parseList(String text) {
    return text
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;

    setState(() => _saving = true);
    try {
      final patient = Patient(
        id: widget.patient?.id,
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        weight: double.tryParse(_weightController.text.trim()),
        allergies: _parseList(_allergiesController.text),
        conditions: _parseList(_conditionsController.text),
        medications: _parseList(_medicationsController.text),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.patient?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await _db.updatePatient(patient);
      } else {
        await _db.insertPatient(patient);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Patient updated' : 'Patient added'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openDiagnosisHelper() {
    final patient = Patient(
      id: widget.patient?.id,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      gender: _gender,
      weight: double.tryParse(_weightController.text.trim()),
      allergies: _parseList(_allergiesController.text),
      conditions: _parseList(_conditionsController.text),
      medications: _parseList(_medicationsController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: widget.patient?.createdAt,
      updatedAt: DateTime.now(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosisHelperPage(initialPatient: patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Patient' : 'Add Patient'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.medical_information),
              tooltip: 'Check medication suitability',
              onPressed: _openDiagnosisHelper,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Select'),
                        ),
                        const DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        const DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        const DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Allergies (comma-separated)',
                  hintText: 'e.g. Penicillin, Sulfa',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _conditionsController,
                decoration: InputDecoration(
                  labelText: 'Conditions (comma-separated)',
                  hintText: 'e.g. Diabetes, Hypertension',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _medicationsController,
                decoration: InputDecoration(
                  labelText: 'Current medications (comma-separated)',
                  hintText: 'e.g. Aspirin, Metformin',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  foregroundColor: AppColors.pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save' : 'Add Patient'),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openDiagnosisHelper,
                  icon: const Icon(Icons.medical_information),
                  label: const Text('Check medication suitability'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
