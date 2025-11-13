import 'package:app_wallet/library_section/main_library.dart';

class RecurrentDetailItems extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> row) onTapItem;

  const RecurrentDetailItems(
      {Key? key, required this.items, required this.onTapItem})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: AwText.normal('No hay items para esta recurrencia.',
            color: AwColors.modalGrey),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) => const AwDivider(),
      itemBuilder: (ctx, i) {
        final r = items[i];
        final dt = DateTime.fromMillisecondsSinceEpoch(r['fecha'] as int);
        return ListTile(
          title: AwText.bold(
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}',
              color: AwColors.boldBlack),
          subtitle: AwText(text: 'Monto: ${r['cantidad']}'),
          onTap: () => onTapItem(r),
        );
      },
    );
  }
}
