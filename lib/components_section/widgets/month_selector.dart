import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<DateTime?> showMonthSelector(BuildContext context, List<DateTime> availableMonths) async {
  try {
    await initializeDateFormatting('es');
  } catch (_) {}

  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Seleccionar mes', style: Theme.of(ctx).textTheme.titleMedium),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...availableMonths.map((m) {
              final label = DateFormat.yMMMM('es').format(m);
              return ListTile(
                title: Text(label),
                onTap: () => Navigator.of(ctx).pop(m),
              );
            }).toList(),
          ],
        ),
      );
    },
  );
}
