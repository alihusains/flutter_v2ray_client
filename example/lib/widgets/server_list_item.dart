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

  /// Callback when test delay is pressed.
  final VoidCallback? onTestDelay;

  /// Creates a new ServerListItem.
  const ServerListItem({
    super.key,
    required this.server,
    this.isSelected = false,
    this.onTap,
    this.onShare,
    this.onEdit,
    this.onDelete,
    this.onTestDelay,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: [
          ListTile(
            onTap: onTap,
            dense: false,
            selected: isSelected,
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withAlpha(40),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: _buildLeadingIcon(context),
            title: Text(
              server.remark,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${server.address}:${server.port}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildProtocolBadge(context),
                    const Spacer(),
                    ValueListenableBuilder<bool>(
                      valueListenable: server.isTestingNotifier,
                      builder: (context, isTesting, _) {
                        if (isTesting) {
                          return const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          );
                        }
                        return ValueListenableBuilder<int>(
                          valueListenable: server.delayNotifier,
                          builder: (context, delay, _) {
                            if (delay == -1) return const SizedBox.shrink();
                            return Text(
                              delay > 0 ? '${delay}ms' : 'Timeout',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getDelayColor(delay),
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionIcon(Icons.share, 'Share', onShare ?? () => _copyToClipboard(context)),
                _buildActionIcon(Icons.edit_outlined, 'Edit', onEdit),
                _buildActionIcon(Icons.delete_outline, 'Delete', onDelete, isDestructive: true),
              ],
            ),
          ),
          const Divider(height: 1, indent: 70),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String tooltip, VoidCallback? onPressed, {bool isDestructive = false}) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
      padding: EdgeInsets.zero,
      color: isDestructive ? Colors.red.withAlpha(200) : null,
      visualDensity: VisualDensity.compact,
    );
  }

  Color _getDelayColor(int delay) {
    if (delay <= 0) return Colors.red;
    if (delay < 150) return Colors.greenAccent[700]!;
    if (delay < 350) return Colors.green;
    if (delay < 600) return Colors.orange;
    return Colors.red;
  }

  Widget _buildLeadingIcon(BuildContext context) {
    // Try to get country flag from remark
    final flag = _extractFlag(server.remark);
    if (flag != null) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Text(flag, style: const TextStyle(fontSize: 24)),
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
