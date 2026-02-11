import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/server_config.dart';

/// A widget that displays a server configuration as a list item.
class ServerListItem extends StatelessWidget {
  /// The server configuration to display.
  final ServerConfig server;

  /// Whether this server is currently selected.
  final bool isSelected;

  /// Callback when the server is tapped.
  final VoidCallback? onTap;

  /// Callback when share button is pressed.
  final VoidCallback? onShare;

  /// Callback when edit button is pressed.
  final VoidCallback? onEdit;

  /// Callback when delete button is pressed.
  final VoidCallback? onDelete;

  /// Creates a new ServerListItem.
  const ServerListItem({
    super.key,
    required this.server,
    this.isSelected = false,
    this.onTap,
    this.onShare,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _buildLeadingIcon(context),
          title: Text(
            server.remark,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${server.address}:${server.port}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _buildProtocolBadge(context),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.share, size: 20),
                onPressed: onShare ?? () => _copyToClipboard(context),
                tooltip: 'Share',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    // Try to get country flag from remark
    final flag = _extractFlag(server.remark);
    if (flag != null) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Text(
          flag,
          style: const TextStyle(fontSize: 24),
        ),
      );
    }

    // Default protocol icon
    return CircleAvatar(
      radius: 20,
      backgroundColor: _getProtocolColor(server.protocol).withAlpha(30),
      child: Text(
        server.protocol.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: _getProtocolColor(server.protocol),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProtocolBadge(BuildContext context) {
    final color = _getProtocolColor(server.protocol);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        server.protocolDisplay,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getProtocolColor(String protocol) {
    switch (protocol.toLowerCase()) {
      case 'vmess':
        return Colors.blue;
      case 'vless':
        return Colors.green;
      case 'trojan':
        return Colors.orange;
      case 'shadowsocks':
        return Colors.purple;
      case 'socks':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// Extracts emoji flag from remark if present.
  String? _extractFlag(String remark) {
    // Common flag patterns
    final flagRegex = RegExp(
      r'[\u{1F1E0}-\u{1F1FF}]{2}|[\u{1F3F4}][\u{E0060}-\u{E007F}]+',
      unicode: true,
    );
    final match = flagRegex.firstMatch(remark);
    return match?.group(0);
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: server.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Server URL copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
