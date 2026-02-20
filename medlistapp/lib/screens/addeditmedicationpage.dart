import 'package:flutter/material.dart';
import 'package:medlistapp/models/medication.dart';
import 'package:medlistapp/models/stockitem.dart';
import 'package:medlistapp/services/barcodescannerservice.dart';
import 'package:medlistapp/services/gs1parserservice.dart';
import 'package:medlistapp/services/medicationservice.dart';
import 'package:medlistapp/services/stockservice.dart';
import 'package:medlistapp/screens/barcodescannerpage.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/widgets/searchbarwidget.dart';
import 'package:intl/intl.dart';

class AddEditMedicationPage extends StatefulWidget {
  final Medication? medication;
  final bool openScannerOnLoad;

  const AddEditMedicationPage({
    super.key,
    this.medication,
    this.openScannerOnLoad = false,
  });

  @override
  State<AddEditMedicationPage> createState() => _AddEditMedicationPageState();
}

class _AddEditMedicationPageState extends State<AddEditMedicationPage> {
  final MedicationService _medicationService = MedicationService();
  final StockService _stockService = StockService();
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _expectedQuantityController = TextEditingController();

  Medication? _selectedMedication;
  DateTime? _expiryDate;
  DateTime? _purchaseDate;
  DateTime? _manufacturingDate;
  String? _serialNumber;
  GS1Data? _lastScanData;
  List<Medication> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
    if (widget.medication != null) {
      _selectedMedication = widget.medication;
    }
    if (widget.openScannerOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scanBarcode());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quantityController.dispose();
    _batchNumberController.dispose();
    _locationController.dispose();
    _expectedQuantityController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final rawBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(returnRawBarcode: true),
      ),
    );

    if (rawBarcode == null || !mounted) return;

    final gs1 = _scannerService.parseGS1(rawBarcode);
    if (gs1 == null || !gs1.hasAnyField) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not parse barcode — try scanning again')),
      );
      return;
    }

    final filledFields = <String>[];

    setState(() {
      _lastScanData = gs1;

      if (gs1.batchNumber != null) {
        _batchNumberController.text = gs1.batchNumber!;
        filledFields.add('Batch');
      }
      if (gs1.expiryDate != null) {
        _expiryDate = gs1.expiryDate;
        filledFields.add('Expiry');
      }
      if (gs1.manufacturingDate != null) {
        _manufacturingDate = gs1.manufacturingDate;
        filledFields.add('Mfg Date');
      }
      if (gs1.serialNumber != null) {
        _serialNumber = gs1.serialNumber;
        filledFields.add('S/N');
      }
      if (gs1.count != null && gs1.count! > 0) {
        _quantityController.text = gs1.count.toString();
        filledFields.add('Qty');
      }
    });

    if (gs1.gtin != null) {
      final result = await _scannerService.matchBarcode(rawBarcode, null);
      if (result.matched && result.medication != null && mounted) {
        setState(() {
          _selectedMedication = result.medication;
          _searchController.text = result.medication!.tradeName;
          _searchResults = [];
          filledFields.add('Medication');
        });
      }
    }

    if (mounted && filledFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto-filled: ${filledFields.join(", ")}'),
          backgroundColor: AppColors.skyBlue,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _selectPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _selectManufacturingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _manufacturingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _manufacturingDate = picked);
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
          manufacturingDate: _manufacturingDate,
          expectedQuantity: _expectedQuantityController.text.isEmpty
              ? null
              : int.tryParse(_expectedQuantityController.text),
          serialNumber: _serialNumber,
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

  Widget _buildScanSummary() {
    if (_lastScanData == null) return const SizedBox.shrink();

    final fmt = DateFormat('MMM yyyy');
    final items = <MapEntry<String, String>>[];

    if (_lastScanData!.gtin != null) {
      items.add(MapEntry('GTIN', _lastScanData!.gtin!));
    }
    if (_lastScanData!.batchNumber != null) {
      items.add(MapEntry('LOT / Batch', _lastScanData!.batchNumber!));
    }
    if (_lastScanData!.expiryDate != null) {
      items.add(MapEntry('EXP', fmt.format(_lastScanData!.expiryDate!)));
    }
    if (_lastScanData!.manufacturingDate != null) {
      items.add(MapEntry('MFG', fmt.format(_lastScanData!.manufacturingDate!)));
    }
    if (_lastScanData!.serialNumber != null) {
      items.add(MapEntry('S/N', _lastScanData!.serialNumber!));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.skyBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.skyBlue, size: 18),
              const SizedBox(width: 6),
              Text(
                'Scanned Data',
                style: TextStyle(
                  color: AppColors.skyBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _scanBarcode,
                child: Text(
                  'Rescan',
                  style: TextStyle(
                    color: AppColors.skyBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: items.map((e) => _scanChip(e.key, e.value)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _scanChip(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mediumGray,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.deepNavy,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medication != null ? 'Add Stock' : 'Add Medication Stock'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scan button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
                  label: Text(_lastScanData != null
                      ? 'Scan Another Box'
                      : 'Scan Medicine Box QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Scan summary
              _buildScanSummary(),

              // Medication selection
              if (widget.medication == null) ...[
                Text('Select Medication',
                    style: Theme.of(context).textTheme.titleMedium),
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
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.medication_rounded,
                          color: AppColors.skyBlue),
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
                const SizedBox(height: 20),
              ] else ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.medication_rounded,
                        color: AppColors.skyBlue),
                    title: Text(widget.medication!.tradeName),
                    subtitle: Text(widget.medication!.form),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text('Stock Information',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              // Quantity (default 1 per box)
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity (per box) *',
                  hintText: '1',
                  helperText: 'Each scan counts as 1 box. Edit if needed.',
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

              // Expiry Date
              InkWell(
                onTap: _selectExpiryDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expiry Date *',
                    suffixIcon: const Icon(Icons.calendar_today),
                    labelStyle: _expiryDate != null
                        ? TextStyle(color: AppColors.skyBlue)
                        : null,
                  ),
                  child: Text(
                    _expiryDate != null
                        ? DateFormat('MMM dd, yyyy').format(_expiryDate!)
                        : 'Select expiry date',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _expiryDate != null ? null : AppColors.mediumGray,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Batch Number
              TextFormField(
                controller: _batchNumberController,
                decoration: const InputDecoration(
                  labelText: 'Batch / LOT Number',
                  hintText: 'Auto-filled from scan or enter manually',
                ),
              ),
              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Storage location (optional)',
                ),
              ),
              const SizedBox(height: 16),

              // Mfg Date
              InkWell(
                onTap: _selectManufacturingDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Manufacturing Date',
                    suffixIcon: const Icon(Icons.calendar_today),
                    labelStyle: _manufacturingDate != null
                        ? TextStyle(color: AppColors.skyBlue)
                        : null,
                  ),
                  child: Text(
                    _manufacturingDate != null
                        ? DateFormat('MMM dd, yyyy').format(_manufacturingDate!)
                        : 'Auto-filled from scan or select manually',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _manufacturingDate != null
                              ? null
                              : AppColors.mediumGray,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Purchase Date
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              _purchaseDate != null ? null : AppColors.mediumGray,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Expected Quantity
              TextFormField(
                controller: _expectedQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Expected Quantity',
                  hintText: 'Enter expected quantity (optional)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (int.tryParse(value) == null || int.parse(value) < 0) {
                      return 'Please enter a valid expected quantity';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveStockItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.skyBlue,
                    foregroundColor: AppColors.pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Stock Item',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
