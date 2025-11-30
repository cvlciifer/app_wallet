import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/core/providers/profile/ingresos_provider.dart';

class IngresosControls extends StatelessWidget {
  final DateTime initialMonth;
  final int startOffset;
  final int months;
  final IngresosNotifier ctrl;
  final VoidCallback onSave;
  final VoidCallback onOpenRegistro;

  const IngresosControls({
    Key? key,
    required this.initialMonth,
    required this.startOffset,
    required this.months,
    required this.ctrl,
    required this.onSave,
    required this.onOpenRegistro,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AwText.normal('Selecciona el mes de inicio',
            size: AwSize.s14, color: AwColors.grey),
        AwSpacing.s6,
        AwSpacing.s6,
        MonthSelector(
          month: initialMonth,
          canPrev: startOffset > -12,
          canNext: startOffset < 12,
          onPrev: () => ctrl.setStartOffset(startOffset - 1),
          onNext: () => ctrl.setStartOffset(startOffset + 1),
        ),
        AwSpacing.s12,
        const AwText.normal('Selecciona la cantidad de meses',
            size: AwSize.s14, color: AwColors.grey),
        AwSpacing.s6,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (months > 1)
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: AwColors.appBarColor,
                onPressed: () => ctrl.setMonths(months - 1),
              )
            else
              AwSpacing.w48,
            AwText.bold(
              months == 0
                  ? 'Selecciona'
                  : (months == 1 ? '1 mes' : '$months meses'),
              size: AwSize.s16,
              color: AwColors.appBarColor,
            ),
            if (months < 12)
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: AwColors.appBarColor,
                onPressed: () => ctrl.setMonths(months + 1),
              )
            else
              AwSpacing.w48,
          ],
        ),
        AwSpacing.s12,
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AwColors.blueGrey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AwSize.s12)),
                ),
                child: const AwText.bold('Guardar Ingreso',
                    color: AwColors.white, size: AwSize.s14),
              ),
            ),
          ],
        ),
        AwSpacing.s12,
        SizedBox(
          height: AwSize.s40,
          child: ElevatedButton(
            onPressed: onOpenRegistro,
            style: ElevatedButton.styleFrom(
              backgroundColor: AwColors.appBarColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AwSize.s16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long,
                    color: AwColors.white, size: AwSize.s16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registro de ingresos',
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AwColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: AwSize.s14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
