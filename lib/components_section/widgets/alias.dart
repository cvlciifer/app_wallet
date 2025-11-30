import 'package:app_wallet/library_section/main_library.dart';

class AliasForm extends StatelessWidget {
  final TextEditingController controller;
  final String? displayAlias;
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
    this.displayAlias,
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
    final titleText = controller.text.trim().isNotEmpty
        ? '${controller.text.trim()}, Configura Tu Alias'
        : (displayAlias != null && displayAlias!.trim().isNotEmpty
            ? '${displayAlias!.trim()}, Configura Tu Alias'
            : 'Configura Tu Alias');

    return Container(
      decoration: BoxDecoration(
        color: AwColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AwColors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AwSpacing.xl,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: AwSize.s40,
                  color: AwColors.appBarColor,
                ),
                AwSpacing.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AwText.bold(
                        titleText,
                        size: AwSize.s30,
                        color: AwColors.appBarColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AwSpacing.s6,
            const AwText.normal(
              'El alias te identifica en este dispositivo. Debe tener al menos una mayúscula y máximo 15 caracteres.',
              color: AwColors.boldBlack,
              size: AwSize.s14,
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
            AwSpacing.s12,
            const Center(
              child: SizedBox(
                height: 300,
                child: Image(
                  image: AWImage.user,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
