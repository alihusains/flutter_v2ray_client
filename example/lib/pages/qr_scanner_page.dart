import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _importFromGallery() async {
    if (_isProcessing) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      // In mobile_scanner 5.x, analyzeImage might not return the value directly.
      // We rely on the barcodes stream or a dedicated call if available.
      // Some versions of mobile_scanner have a bug where analyzeImage doesn't return the value.
      // We will try to analyze it and if it returns true, we wait a bit for the stream or show a message.
      final result = await controller.analyzeImage(image.path);
      if (!result) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No QR code found in image')),
          );
        }
      } else {
        // If it found something, it usually triggers onDetect.
        // If it doesn't, we might be stuck.
        // For better UX, we'll give it a moment.
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && _isProcessing) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Code detected, processing...')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _importFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // Zoom Slider
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ValueListenableBuilder(
              valueListenable: controller.zoomScaleState,
              builder: (context, zoom, child) {
                return Slider(
                  value: zoom,
                  onChanged: (value) => controller.setZoomScale(value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
