import 'package:app_wallet/library_section/main_library.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPinPage extends ConsumerStatefulWidget {
  final String? initialEmail;
  final bool allowBack;

  const ForgotPinPage({Key? key, this.initialEmail, this.allowBack = false})
      : super(key: key);

  @override
  ConsumerState<ForgotPinPage> createState() => _ForgotPinPageState();
}

class _ForgotPinPageState extends ConsumerState<ForgotPinPage> {
  late final TextEditingController _emailController;
  Timer? _primaryMessageTimer;

  @override
  void initState() {
    super.initState();

    final userEmail = AuthService().getCurrentUser()?.email ?? '';
    _emailController =
        TextEditingController(text: widget.initialEmail ?? userEmail);
  }

  @override
  void dispose() {
    _primaryMessageTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().getCurrentUser()?.uid;
    final state = ref.watch(forgotPinProvider(uid));

    return PinPageScaffold(
      transparentAppBar: true,
      allowBack: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.alias != null && state.alias!.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: AwText.bold(
                    'Hola ${state.alias!}, ¿no recuerdas tu PIN?',
                    size: AwSize.s30,
                    color: AwColors.appBarColor,
                  ),
                ),
                AwSpacing.s12,
              ],
              if (!(state.alias != null && state.alias!.isNotEmpty)) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AwText.bold('Hola, ¿no recuerdas tu PIN?',
                      size: AwSize.s30, color: AwColors.appBarColor),
                ),
                AwSpacing.s12,
              ],
              const Align(
                  alignment: Alignment.centerLeft,
                  child: AwText.normal(
                      'No te preocupes, te ayudaremos a crear uno nuevo.',
                      color: AwColors.boldBlack,
                      size: AwSize.s14)),
              AwSpacing.s6,
              const Align(
                  alignment: Alignment.centerLeft,
                  child: AwText.normal(
                      'Para continuar, debes abrir ese enlace desde este mismo dispositivo.',
                      color: AwColors.boldBlack,
                      size: AwSize.s14)),
              AwSpacing.s20,
              _buildSendAreaWithState(state),
              AwSpacing.s12,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendAreaWithState(ForgotPinState state) {
    final hasSentBefore = state.lastSentAt != null;
    final buttonText = state.remainingSeconds > 0
        ? 'Reenviar (${state.remainingSeconds} s)'
        : (hasSentBefore ? 'Reenviar enlace' : 'Enviar enlace');

    final isDisabled = state.isSending || state.remainingSeconds > 0;

    return Column(
      children: [
        WalletButton.iconButtonText(
          buttonText: buttonText,
          onPressed: () async {
            if (isDisabled) return;
            // send recovery email (UI will reflect cooldown via state)
            final email = _emailController.text.trim();
            final uid = AuthService().getCurrentUser()?.uid;
            final msg = await ref
                .read(forgotPinProvider(uid).notifier)
                .sendRecoveryEmail(email);
            if (!mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          },
          backgroundColor:
              isDisabled ? AwColors.blueGrey : AwColors.appBarColor,
        ),
        AwSpacing.s6,
        AwText.normal(
          'Hoy tienes ${state.remainingAttempts} intento(s) para cambiar tu PIN.',
          size: AwSize.s14,
          color: AwColors.grey,
        ),
        AwSpacing.s12,
      ],
    );
  }
}
