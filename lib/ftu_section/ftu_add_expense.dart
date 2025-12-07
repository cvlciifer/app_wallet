import 'package:app_wallet/library_section/main_library.dart';
import 'package:app_wallet/ftu_section/ftu_two_options.dart';

class FTUAddExpensePage extends StatefulWidget {
  const FTUAddExpensePage({Key? key}) : super(key: key);

  @override
  State<FTUAddExpensePage> createState() => _FTUAddExpensePageState();
}

class _FTUAddExpensePageState extends State<FTUAddExpensePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold('Agregar gasto', color: AwColors.white),
        showBackArrow: true,
        barColor: AwColors.appBarColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AwSpacing.s12,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ExpenseForm(
                    showFTUOnOpen: true,
                    onSubmit: (expense) async {
                      Navigator.of(context).pop('expense');
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('first_time_add_shown', true);
                      } catch (_) {}
                      try {
                        final popupCtx = Navigator.of(context, rootNavigator: true).overlay?.context ?? context;

                        // Esperar un poco antes de mostrar el diálogo FTU
                        await Future.delayed(const Duration(milliseconds: 300));

                        // Llamar a showFTUTwoOptions iniciando desde el paso 'recurrent'
                        // ya que el paso 'expense' fue completado
                        await showFTUTwoOptions(
                          popupCtx,
                          initialStep: 'recurrent',
                          onAddExpense: () async {
                            // Expense ya completado, no hacer nada
                          },
                          onAddRecurrent: () async {
                            try {
                              final res = await Navigator.of(popupCtx).push<String>(
                                MaterialPageRoute(builder: (_) => const FTUAddRecurrentPage()),
                              );
                              // Si se completó el recurrente, regresar al home con indicación de mostrar FTU de estadísticas
                              if (res == 'recurrent') {
                                // Cerrar el diálogo de opciones y regresar con el indicador
                                Navigator.of(popupCtx).popUntil((route) => route.isFirst);
                              }
                            } catch (_) {}
                          },
                          onFTUComplete: () {
                            // FTU completado, no hacer nada adicional
                          },
                        );
                      } catch (_) {}
                    },
                  ),
                ),
              ),
              AwSpacing.s12,
            ],
          ),
        ),
      ),
    );
  }
}
