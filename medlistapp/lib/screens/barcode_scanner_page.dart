import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:medlistapp/services/barcode_scanner_service.dart';
import 'package:medlistapp/services/verification_service.dart';
import 'package:medlistapp/utils/app_colors.dart';
import 'package:medlistapp/screens/medication_detail_page.dart';
import 'package:medlistapp/screens/medication_verification_page.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final BarcodeScannerService _scannerService = BarcodeScannerService();
  final VerificationService _verificationService = VerificationService();
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
      final result = await _scannerService.matchBarcode(barcode, 'EAN13');
      
      if (!mounted) return;

      if (result.matched && result.medication != null) {
        // Show success dialog with options
        _showScanResultDialog(result.medication!, barcode);
      } else {
        // Show not found dialog
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
        title: const Text('Scan Barcode'),
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
                if (barcode.rawValue != null) {
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
          // Scanning overlay
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Position barcode within the frame',
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

