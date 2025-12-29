import 'package:flutter/material.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/stock_item.dart';
import 'package:medlistapp/services/medication_service.dart';
import 'package:medlistapp/services/stock_service.dart';
import 'package:medlistapp/widgets/search_bar_widget.dart';
import 'package:intl/intl.dart';

class AddEditMedicationPage extends StatefulWidget {
  final Medication? medication;

  const AddEditMedicationPage({super.key, this.medication});

  @override
  State<AddEditMedicationPage> createState() => _AddEditMedicationPageState();
}

class _AddEditMedicationPageState extends State<AddEditMedicationPage> {
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  Medication? _selectedMedication;
  DateTime? _expiryDate;
  DateTime? _purchaseDate;
  List<Medication> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _selectedMedication = widget.medication;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _batchNumberController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _searchMedication(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _medicationService.searchMedications(query);
      setState(() {
        _searchResults = results.take(10).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _selectExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _saveStockItem() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMedication == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a medication')),
        );
        return;
      }

      if (_expiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an expiry date')),
        );
        return;
      }

      try {
        final stockItem = StockItem(
          medicationId: _selectedMedication!.id!,
          quantity: int.parse(_quantityController.text),
          expiryDate: _expiryDate!,
          batchNumber: _batchNumberController.text.isEmpty
              ? null
              : _batchNumberController.text,
          location: _locationController.text.isEmpty
              ? null
              : _locationController.text,
          purchaseDate: _purchaseDate,
        );

        await _stockService.addStockItem(stockItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stock item added successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding stock: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication != null ? 'Add Stock' : 'Add Medication Stock'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.medication == null) ...[
                Text(
                  'Select Medication',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search medication...',
                  onChanged: _searchMedication,
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_searchResults.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final medication = _searchResults[index];
                        return ListTile(
                          title: Text(medication.tradeName),
                          subtitle: Text(medication.form),
                          onTap: () {
                            setState(() {
                              _selectedMedication = medication;
                              _searchController.text = medication.tradeName;
                              _searchResults = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                if (_selectedMedication != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      title: Text(_selectedMedication!.tradeName),
                      subtitle: Text(_selectedMedication!.form),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedMedication = null;
                            _searchController.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ] else ...[
                Card(
                  child: ListTile(
                    title: Text(widget.medication!.tradeName),
                    subtitle: Text(widget.medication!.form),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Stock Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  hintText: 'Enter quantity',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectExpiryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiry Date *',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _expiryDate != null
                        ? DateFormat('MMM dd, yyyy').format(_expiryDate!)
                        : 'Select expiry date',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _batchNumberController,
                decoration: const InputDecoration(
                  labelText: 'Batch Number',
                  hintText: 'Enter batch number (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter location (optional)',
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectPurchaseDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Purchase Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _purchaseDate != null
                        ? DateFormat('MMM dd, yyyy').format(_purchaseDate!)
                        : 'Select purchase date (optional)',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveStockItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Save Stock Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

