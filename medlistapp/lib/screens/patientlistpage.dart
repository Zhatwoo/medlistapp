import 'package:flutter/material.dart';
import 'package:medlistapp/models/patient.dart';
import 'package:medlistapp/services/databaseservice.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/screens/patientprofilepage.dart';

class PatientListPage extends StatefulWidget {
  /// When true, tapping a patient returns it to the caller instead of opening profile.
  final bool selectMode;

  const PatientListPage({super.key, this.selectMode = false});

  @override
  State<PatientListPage> createState() => _PatientListPageState();
}

class _PatientListPageState extends State<PatientListPage> {
  final DatabaseService _db = DatabaseService();
  List<Patient> _patients = [];
  List<Patient> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterPatients();
  }

  void _filterPatients() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_patients);
      } else {
        _filtered = _patients
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.allergies.any((a) => a.toLowerCase().contains(q)) ||
                p.conditions.any((c) => c.toLowerCase().contains(q)))
            .toList();
      }
    });
  }

  Future<void> _loadPatients() async {
    setState(() => _loading = true);
    final list = await _db.getAllPatients();
    if (mounted) {
      setState(() {
        _patients = list;
        _filterPatients();
        _loading = false;
      });
    }
  }

  void _onPatientTap(Patient p) {
    if (widget.selectMode) {
      Navigator.pop(context, p);
    } else {
      _openProfile(p);
    }
  }

  Future<void> _openProfile(Patient? patient) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientProfilePage(patient: patient),
      ),
    );
    if (result == true && mounted) _loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.aliceBlue,
      appBar: AppBar(
        title: const Text('Patients'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openProfile(null),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search patients...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: AppColors.mediumGray,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _patients.isEmpty
                                    ? 'No patients yet'
                                    : 'No matching patients',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.mediumGray,
                                    ),
                              ),
                              if (_patients.isEmpty) ...[
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _openProfile(null),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Patient'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.skyBlue,
                                    foregroundColor: AppColors.pureWhite,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final p = _filtered[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.softBlue,
                                  child: Text(
                                    p.name.isNotEmpty
                                        ? p.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.skyBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  [
                                    if (p.age != null) '${p.age} yrs',
                                    if (p.gender != null && p.gender!.isNotEmpty) p.gender!,
                                    if (p.allergies.isNotEmpty) 'Allergies: ${p.allergies.take(2).join(", ")}',
                                  ].where((s) => s.isNotEmpty).join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _onPatientTap(p),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProfile(null),
        backgroundColor: AppColors.skyBlue,
        child: const Icon(Icons.add, color: AppColors.pureWhite),
      ),
    );
  }
}
