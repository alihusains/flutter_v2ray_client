import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import '../models/server_config.dart';

class EditServerPage extends StatefulWidget {
  final ServerConfig server;

  const EditServerPage({super.key, required this.server});

  @override
  State<EditServerPage> createState() => _EditServerPageState();
}

class _EditServerPageState extends State<EditServerPage> {
  late TextEditingController _remarkController;
  late TextEditingController _addressController;
  late TextEditingController _portController;
  late TextEditingController _urlController;
  String _protocol = '';

  @override
  void initState() {
    super.initState();
    _remarkController = TextEditingController(text: widget.server.remark);
    _addressController = TextEditingController(text: widget.server.address);
    _portController = TextEditingController(text: widget.server.port.toString());
    _urlController = TextEditingController(text: widget.server.url);
    _protocol = widget.server.protocol;
  }

  @override
  void dispose() {
    _remarkController.dispose();
    _addressController.dispose();
    _portController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _save() {
    final String newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL cannot be empty')),
      );
      return;
    }

    try {
      // Parse the URL to verify it and get new details
      final v2rayUrl = V2ray.parseFromURL(newUrl);

      // Create updated ServerConfig
      // We prioritize the parsed values from the URL
      final newServer = widget.server.copyWith(
        url: newUrl,
        remark: v2rayUrl.remark.isNotEmpty ? v2rayUrl.remark : _remarkController.text,
        address: v2rayUrl.address.isNotEmpty ? v2rayUrl.address : _addressController.text,
        port: v2rayUrl.port > 0 ? v2rayUrl.port : int.tryParse(_portController.text) ?? 443,
        fullConfig: v2rayUrl.getFullConfiguration(),
        protocol: v2rayUrl.url.split('://')[0],
      );

      Navigator.pop(context, newServer);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid config: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Server'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: 'Remark',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Ideally, update URL fragment or JSON ps field
                _tryUpdateUrl();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _tryUpdateUrl(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _tryUpdateUrl(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
             TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Share URL (Source of Truth)',
                border: OutlineInputBorder(),
                helperText: 'Edit this to change configuration',
              ),
              maxLines: 5,
              onChanged: (value) {
                // If user edits URL, we should update fields?
                // Parsing might be expensive or fail while typing.
                // We can do it on focus lost or just leave it.
              },
            ),
             const SizedBox(height: 8),
             ElevatedButton(
               onPressed: () {
                 // Try to parse URL and update fields
                 try {
                   final v2rayUrl = V2ray.parseFromURL(_urlController.text.trim());
                   setState(() {
                     _remarkController.text = v2rayUrl.remark;
                     _addressController.text = v2rayUrl.address;
                     _portController.text = v2rayUrl.port.toString();
                     _protocol = v2rayUrl.url.split('://')[0];
                   });
                 } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Invalid URL format')),
                   );
                 }
               },
               child: const Text('Parse URL to Fields'),
             ),
          ],
        ),
      ),
    );
  }

  void _tryUpdateUrl() {
    // Attempt to update the URL based on fields
    // This is tricky as we need to preserve other params in the URL
    final String currentUrl = _urlController.text.trim();
    if (currentUrl.isEmpty) return;

    try {
      String newUrl = currentUrl;
      final remark = _remarkController.text;
      final address = _addressController.text;
      final port = int.tryParse(_portController.text) ?? 0;

      if (_protocol.toLowerCase() == 'vmess') {
        // Handle VMess
        final String base64Part = currentUrl.substring(8);
        String padded = base64Part;
        if (padded.length % 4 > 0) {
          padded += '=' * (4 - padded.length % 4);
        }
        try {
          final jsonString = utf8.decode(base64Decode(padded));
          final Map<String, dynamic> config = jsonDecode(jsonString);

          config['ps'] = remark;
          config['add'] = address;
          config['port'] = port;

          final newJson = jsonEncode(config);
          final newBase64 = base64Encode(utf8.encode(newJson));
          newUrl = 'vmess://$newBase64';
        } catch (e) {
          // ignore parsing error
        }
      } else {
        // Handle Uri based (vless, trojan, etc)
        final uri = Uri.parse(currentUrl);
        // Uri is immutable, create new one

        // Host and Port are in authority usually, or host param
        // VLESS: vless://uuid@host:port?params#remark
        // We can replace fields.
        // NOTE: This is fragile if we don't parse strictly.
        // But Uri class handles most.

        // Construct new URI
        newUrl = uri.replace(
          host: address,
          port: port,
          fragment: remark,
        ).toString();
      }

      if (newUrl != currentUrl) {
        _urlController.text = newUrl;
      }
    } catch (e) {
      // Ignore errors during auto-update
    }
  }
}
