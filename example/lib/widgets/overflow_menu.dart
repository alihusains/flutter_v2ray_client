import 'package:flutter/material.dart';

class OverflowMenu extends StatelessWidget {
  final VoidCallback onUpdateSubscriptions;
  final VoidCallback onDeleteAllServers;
  final VoidCallback onTestAllDelays;
  final VoidCallback onExportConfigs;
  final VoidCallback? onEditSubscription;

  const OverflowMenu({
    super.key,
    required this.onUpdateSubscriptions,
    required this.onDeleteAllServers,
    required this.onTestAllDelays,
    required this.onExportConfigs,
    this.onEditSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEditSubscription != null)
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Subscription'),
            onTap: () {
              Navigator.pop(context);
              onEditSubscription!();
            },
          ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Update all subscriptions'),
          onTap: () {
            Navigator.pop(context);
            onUpdateSubscriptions();
          },
        ),
        ListTile(
          leading: const Icon(Icons.speed),
          title: const Text('Test all delays'),
          onTap: () {
            Navigator.pop(context);
            onTestAllDelays();
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: const Text('Export configurations'),
          onTap: () {
            Navigator.pop(context);
            onExportConfigs();
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_sweep, color: Colors.red),
          title: const Text('Delete all servers', style: TextStyle(color: Colors.red)),
          onTap: () {
            Navigator.pop(context);
            onDeleteAllServers();
          },
        ),
      ],
    );
  }
}
