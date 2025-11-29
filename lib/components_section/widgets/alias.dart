import 'package:app_wallet/library_section/main_library.dart';

class AliasForm extends StatelessWidget {
  final TextEditingController controller;
  final String? aliasError;
  final bool canContinue;
  final bool showInvalidChars;
  final VoidCallback? onBlockedChars;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onConfirm;
  final VoidCallback? onConfigureLater;
  final bool initialSetup;

  const AliasForm({
    Key? key,
    required this.controller,
    this.aliasError,
    required this.canContinue,
    required this.showInvalidChars,
    this.onBlockedChars,
    this.onChanged,
    this.onConfirm,
    this.onConfigureLater,
    this.initialSetup = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      notchDepth: 12,
      elevation: 6,
      color: AwColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(
                Icons.person_outline,
                size: AwSize.s26,
                color: AwColors.appBarColor,
              ),
            ),
            AwSpacing.s12,
            const Center(
              child: AwText.bold(
                'Configura Tu Alias',
                size: AwSize.s20,
                color: AwColors.appBarColor,
                textAlign: TextAlign.center,
              ),
            ),
            AwSpacing.s6,
            const Center(
              child: AwText.normal(
                'Este alias se usará solo en este dispositivo.',
                color: AwColors.boldBlack,
                size: AwSize.s14,
                textAlign: TextAlign.center,
              ),
            ),
            AwSpacing.s12,
            CustomTextField(
              controller: controller,
              label: 'Alias',
              maxLength: 15,
              textAlign: TextAlign.left,
              textAlignVertical: TextAlignVertical.center,
              onChanged: onChanged,
              hideCounter: false,
              inputFormatters: [
                AllowedCharsFormatter(
                  allowedChar: RegExp(r"[A-Za-zÀ-ÖØ-öø-ÿ\s]"),
                  onBlocked: onBlockedChars,
                ),
                LengthLimitingTextInputFormatter(15),
              ],
            ),
            AwSpacing.s12,
            if (showInvalidChars)
              const AwText.normal('Solo se permiten letras y espacios',
                  color: AwColors.red)
            else if (aliasError != null)
              AwText.normal(aliasError!, color: AwColors.red),
            AwSpacing.s12,
            Center(
              child: WalletButton.primaryButton(
                buttonText: 'Confirmar',
                onPressed: canContinue ? onConfirm : null,
                backgroundColor:
                    canContinue ? AwColors.appBarColor : AwColors.blueGrey,
                buttonTextColor: AwColors.white,
              ),
            ),
            AwSpacing.s,
            if (initialSetup)
              WalletButton.textButton(
                buttonText: 'Configurar más tarde',
                onPressed: onConfigureLater,
                alignment: MainAxisAlignment.center,
                colorText: AwColors.blueGrey,
              ),
          ],
        ),
      ),
    );
  }
}
