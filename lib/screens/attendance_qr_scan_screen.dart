import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';

/// Skaner QR obecności — tylko dla zalogowanego zawodnika.
class AttendanceQrScanScreen extends StatefulWidget {
  const AttendanceQrScanScreen({super.key});

  @override
  State<AttendanceQrScanScreen> createState() => _AttendanceQrScanScreenState();
}

class _AttendanceQrScanScreenState extends State<AttendanceQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _busy = false;
  String? _lastMessage;
  bool _success = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;

    setState(() {
      _busy = true;
      _lastMessage = null;
      _success = false;
    });

    final api = Provider.of<ApiService>(context, listen: false);
    final sessionDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      await api.qrCheckin(payload: raw, sessionDate: sessionDate);
      if (!mounted) return;
      setState(() {
        _success = true;
        _lastMessage = 'Obecność zapisana na $sessionDate';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zatwierdzono obecność · $sessionDate'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lastMessage = e.toString().replaceFirst('Exception: ', '');
        _success = false;
      });
    } finally {
      if (mounted) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skaner obecności'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Skieruj aparat na kod QR w sali. Data treningu: dzisiejsza (${DateFormat('dd.MM.yyyy').format(DateTime.now())}).',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          if (_lastMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _lastMessage!,
                style: TextStyle(
                  color: _success ? cs.primary : cs.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: CircularProgressIndicator(),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
