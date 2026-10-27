import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'product_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE]);
  final _manual = TextEditingController();
  bool _busy = false;

  Future<void> _open(String code) async {
    if (_busy) return;
    _busy = true;
    await _controller.stop();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(barcode: code)));
    _busy = false;
    if (mounted) await _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    _manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a product')),
      body: Column(children: [
        Expanded(
          child: MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null) _open(code);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(controller: _manual, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Or enter barcode'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: () { if (_manual.text.trim().isNotEmpty) _open(_manual.text.trim()); }, child: const Text('Go')),
          ]),
        ),
      ]),
    );
  }
}
