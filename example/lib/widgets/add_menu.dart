import 'package:flutter/material.dart';

class AddMenu extends StatelessWidget {
  final VoidCallback onImportClipboard;
  final VoidCallback onAddSubscription;
  final VoidCallback onScanQr;

  const AddMenu({
    super.key,
    required this.onImportClipboard,
    required this.onAddSubscription,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.content_paste),
          title: const Text('Import from clipboard'),
          onTap: () {
            Navigator.pop(context);
            onImportClipboard();
          },
        ),
        ListTile(
          leading: const Icon(Icons.rss_feed),
          title: const Text('Add subscription'),
          onTap: () {
            Navigator.pop(context);
            onAddSubscription();
          },
        ),
        ListTile(
          leading: const Icon(Icons.qr_code_scanner),
          title: const Text('Scan QR code'),
          onTap: () {
            Navigator.pop(context);
            onScanQr();
          },
        ),
      ],
    );
  }
}
