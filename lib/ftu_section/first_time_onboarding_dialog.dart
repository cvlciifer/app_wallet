import 'package:app_wallet/library_section/main_library.dart';

class FirstTimeOnboardingDialog extends StatelessWidget {
  const FirstTimeOnboardingDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AwColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AwText.bold('¡Bienvenido a AdminWallet!', size: AwSize.s18, color: AwColors.boldBlack),
              AwSpacing.s20,
              const AwText.normal(
                'Gracias por instalar la aplicación.',
                size: AwSize.s16,
                color: AwColors.modalGrey,
              ),
              const AwText.normal(
                'A continuación verás una guía por la app para el primer uso.',
                size: AwSize.s16,
                color: AwColors.modalGrey,
              ),
              AwSpacing.s20,
              Row(
                children: [
                  Expanded(
                    child: WalletButton.primaryButton(
                      buttonText: 'Comenzar guía',
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ),
                  AwSpacing.w12,
                  Expanded(
                    child: WalletButton.textButton(
                      buttonText: 'Ahora no',
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
