import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medlistapp/services/barcodescannerservice.dart';
import 'package:medlistapp/utils/appcolors.dart';
import 'package:medlistapp/screens/medicationdetailpage.dart';
import 'package:medlistapp/screens/medicationverificationpage.dart';

class BarcodeScannerPage extends StatefulWidget {
  /// When true, the page pops with the raw barcode string instead of
  /// showing match/not-found dialogs. Used by AddEditMedicationPage.
  final bool returnRawBarcode;

  const BarcodeScannerPage({super.key, this.returnRawBarcode = false});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  MobileScannerController? _controller;
  bool _isScanning = false;
  String? _lastScannedBarcode;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(String barcode) async {
    if (_isScanning || _lastScannedBarcode == barcode) return;
    
    setState(() {
      _isScanning = true;
      _lastScannedBarcode = barcode;
    });

    try {
      if (widget.returnRawBarcode) {
        if (mounted) Navigator.pop(context, barcode);
        return;
      }

      final result = await _scannerService.matchBarcode(barcode, null);
      
      if (!mounted) return;

      if (result.matched && result.medication != null) {
        _showScanResultDialog(result.medication!, barcode);
      } else {
        _showNotFoundDialog(barcode);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _showScanResultDialog(medication, String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode Matched'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medication: ${medication.tradeName}'),
            const SizedBox(height: 16),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicationVerificationPage(),
                ),
              );
            },
            child: const Text('Verify'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (medication.id != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicationDetailPage(
                      medicationId: medication.id!,
                    ),
                  ),
                );
              }
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barcode Not Found'),
        content: Text('Barcode "$barcode" was not found in the database.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MedicationVerificationPage(),
                ),
              );
            },
            child: const Text('Search Manually'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.returnRawBarcode
            ? 'Scan Medicine Barcode'
            : 'Scan Barcode / QR Code'),
        backgroundColor: AppColors.skyBlue,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  _handleBarcode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          if (_isScanning)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          // Scanning frame overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.pureWhite.withOpacity(0.6), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.returnRawBarcode
                    ? 'Scan the DataMatrix / QR code on the medicine box'
                    : 'Position barcode or QR code within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
