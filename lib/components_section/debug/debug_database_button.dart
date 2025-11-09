import 'package:flutter/material.dart';
import 'package:app_wallet/core/data_base_local/db_debug_helper.dart';

class DebugDatabaseButton extends StatelessWidget {
  const DebugDatabaseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () async {
        await DBDebugHelper.debugDatabase();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Debug info impresa en consola'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      label: const Text('Debug DB'),
      icon: const Icon(Icons.bug_report),
      backgroundColor: Colors.orange,
    );
  }
}
