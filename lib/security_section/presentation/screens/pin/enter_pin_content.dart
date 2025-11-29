import 'dart:async';
import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnterPinContent extends ConsumerStatefulWidget {
  final String accountId;

  const EnterPinContent({Key? key, required this.accountId}) : super(key: key);

  @override
  ConsumerState<EnterPinContent> createState() => _EnterPinContentState();
}

class _EnterPinContentState extends ConsumerState<EnterPinContent> {
  String _currentPin = '';
  int _currentLength = 0;
  bool _submitting = false;

  @override
  void dispose() {
    super.dispose();
  }

  // now returns true on success, false on failure (used by PinSoftUIPage)
  Future<bool?> _onCompleted(String pin) async {
    if (_submitting) return null;
    _submitting = true;
    final notifier = ref.read(enterPinProvider(widget.accountId).notifier);
    final loader = ref.read(globalLoaderProvider.notifier);
    loader.state = true;
    setState(() {});
    bool ok = false;
    try {
      ok = await notifier.verifyPin(pin: pin);
    } finally {
      try {
        loader.state = false;
      } catch (_) {}
      _submitting = false;
      if (mounted) setState(() {});
    }

    if (!mounted) return ok;

    if (ok) {
      try {
        WalletPopup.showNotificationSuccess(
          context: context,
          title: 'PIN correcto',
          visibleTime: 2,
          isDismissible: true,
        );
      } catch (_) {}
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WalletHomePage()));
    } else {
      if (mounted) setState(() => _currentLength = 0);
      try {
        final remaining = (PinService.maxAttempts - ref.read(enterPinProvider(widget.accountId)).attempts)
            .clamp(0, PinService.maxAttempts);
        WalletPopup.showNotificationWarningOrange(
          context: context,
          message: 'PIN incorrecto. Quedan $remaining intento(s).',
          visibleTime: 2,
          isDismissible: true,
        );
      } catch (_) {}
      try {
        final pinService = PinService();
        final lock = await pinService.lockedRemaining(accountId: widget.accountId);
        if (lock != null && lock > Duration.zero) {
          if (!mounted) return ok;
          try {
            ref.read(globalLoaderProvider.notifier).state = false;
          } catch (_) {}
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PinLockedPage(
                    remaining: lock,
                    accountId: widget.accountId,
                    allowBack: false,
                    returnToEnterPin: true,
                  )));
          return ok;
        }
      } catch (_) {}
    }

    return ok;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enterPinProvider(widget.accountId));

    ref.listen(resetFlowProvider, (previous, next) {
      if (next.status == ResetFlowStatus.allowed) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SetPinPage()));
      }
    });

    ref.listen<EnterPinState>(enterPinProvider(widget.accountId), (previous, next) async {
      final wasLocked = previous?.lockedRemaining != null && previous!.lockedRemaining! > Duration.zero;
      final isLocked = next.lockedRemaining != null && next.lockedRemaining! > Duration.zero;
      if (!wasLocked && isLocked) {
        if (!mounted) return;
        try {
          ref.read(globalLoaderProvider.notifier).state = false;
        } catch (_) {}
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PinLockedPage(
                  remaining: next.lockedRemaining ?? Duration.zero,
                  accountId: widget.accountId,
                  allowBack: false,
                  returnToEnterPin: true,
                )));
        return;
      }
    });

    final inner = Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AwSpacing.s12,
                GreetingHeader(alias: state.alias),
                AwSpacing.xs,
                PinSoftUIPage(
                  onCompleted: _onCompleted,
                  onChanged: (len) {
                    if (!mounted) return;
                    setState(() => _currentLength = len);
                  },
                  onPinChanged: (pin) {
                    if (!mounted) return;
                    setState(() => _currentPin = pin);
                  },
                  title: 'Ingresa tu PIN',
                ),
                PinActions(
                  hasConnection: state.hasConnection,
                  onNotYou: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (_) {}
                    await AuthService().clearLoginState();
                    if (!mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  onForgotPin: () async {
                    final email = AuthService().getCurrentUser()?.email;
                    final loader = ref.read(globalLoaderProvider.notifier);
                    loader.state = true;
                    try {
                      final pinService = PinService();
                      final remaining = await pinService.pinChangeRemainingCount(accountId: widget.accountId);
                      final blockedUntil = await pinService.pinChangeBlockedUntilNextDay(accountId: widget.accountId);

                      final isBlocked = (remaining <= 0) || (blockedUntil != null && blockedUntil > Duration.zero);

                      try {
                        loader.state = false;
                      } catch (_) {}

                      if (isBlocked) {
                        final remainingDuration = blockedUntil ?? const Duration(days: 1);
                        if (!mounted) return;
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PinLockedPage(
                                  remaining: remainingDuration,
                                  accountId: widget.accountId,
                                  allowBack: true,
                                  returnToEnterPin: true,
                                )));
                      } else {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ForgotPinPage(
                            initialEmail: email,
                            allowBack: false,
                          ),
                        ));
                      }
                    } catch (e, st) {
                      if (kDebugMode) log('Forgot PIN error', error: e, stackTrace: st);
                      try {
                        ref.read(globalLoaderProvider.notifier).state = false;
                      } catch (_) {}
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return ZoomAware(builder: (ctx, isZoomed, _) {
      // Always allow scrolling to avoid RenderFlex overflow on small screens
      return Scaffold(
        appBar: const WalletAppBar(
          automaticallyImplyLeading: false,
          title: AwText.bold(
            'Admin ',
            color: AwColors.white,
            size: AwSize.s22,
          ),
          barColor: AwColors.appBarColor,
        ),
        backgroundColor: AwColors.white,
        body: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(ctx).size.height),
            child: inner,
          ),
        ),
      );
    });
  }
}
