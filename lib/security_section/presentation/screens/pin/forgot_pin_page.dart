import 'package:app_wallet/library_section/main_library.dart';
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

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold('Restablecer PIN', color: Colors.white),
        showBackArrow: true,
        barColor: AwColors.appBarColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: TicketCard(
              notchDepth: 12,
              elevation: 6,
              color: AwColors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon ilustrativo para consistencia con Configuraciones
                    const Center(
                      child: Icon(
                        Icons.lock_reset,
                        size: AwSize.s30,
                        color: AwColors.appBarColor,
                      ),
                    ),
                    AwSpacing.s12,
                    if (state.alias != null && state.alias!.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AwText.bold(
                          'Hola ${state.alias!}, ¿No recuerdas tu PIN?',
                          size: AwSize.s20,
                          color: AwColors.appBarColor,
                        ),
                      ),
                      AwSpacing.s12,
                    ],
                    if (!(state.alias != null && state.alias!.isNotEmpty)) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AwText.bold('Hola, ¿No recuerdas tu PIN?',
                            size: AwSize.s20, color: AwColors.appBarColor),
                      ),
                      AwSpacing.s12,
                    ],
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AwText.normal(
                        'No te preocupes, te ayudaremos a crear uno nuevo.',
                        color: AwColors.boldBlack,
                        size: AwSize.s14,
                      ),
                    ),
                    AwSpacing.s6,
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: AwText.normal(
                        'Para continuar, debes abrir ese enlace desde este mismo dispositivo.',
                        color: AwColors.boldBlack,
                        size: AwSize.s14,
                      ),
                    ),
                    AwSpacing.s12,
                    // Acerca el área del botón al texto
                    _buildSendAreaWithState(state),
                    AwSpacing.s,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSendAreaWithState(ForgotPinState state) {
    final hasSentBefore = state.lastSentAt != null;
    String formatRemainingMinutes(int seconds) {
      final mins = (seconds + 59) ~/ 60; // round up
      return '$mins min';
    }

    final buttonText = state.remainingSeconds > 0
        ? 'Reenviar (${formatRemainingMinutes(state.remainingSeconds)})'
        : (hasSentBefore ? 'Reenviar enlace' : 'Enviar enlace');

    final isDisabled = state.isSending || state.remainingSeconds > 0;

    return Column(
      children: [
        WalletButton.iconButtonText(
          buttonText: buttonText,
          onPressed: () async {
            if (state.remainingSeconds > 0) {
              final formatted = formatRemainingMinutes(state.remainingSeconds);
              if (!mounted) return;
              await AwAlert.showTicketInfo(
                context,
                title: 'Espera antes de reenviar',
                content:
                    'Debes esperar $formatted antes de solicitar otro enlace.',
                titleSize: AwSize.s20,
                contentSize: AwSize.s14,
              );
              return;
            }

            if (state.isSending) return;

            final email = _emailController.text.trim();
            final uid = AuthService().getCurrentUser()?.uid;
            final msg = await ref
                .read(forgotPinProvider(uid).notifier)
                .sendRecoveryEmail(email);
            if (!mounted) return;
            WalletPopup.showNotificationSuccess(
              context: context,
              title: msg,
            );
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
