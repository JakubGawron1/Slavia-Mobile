import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../widgets/qr_scan_overlay.dart';

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
    final today = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Skaner obecności'),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          const QrScanOverlay(
            hint: 'Skieruj kod QR w sali na ramkę. Data treningu: dzisiaj.',
          ),
          if (_busy)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Data treningu: $today',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (_lastMessage != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: (_success ? cs.primary : cs.error)
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_success ? cs.primary : cs.error)
                              .withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        _lastMessage!,
                        style: TextStyle(
                          color: _success ? cs.primary : cs.error,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
