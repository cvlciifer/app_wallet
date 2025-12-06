import 'dart:developer';
import 'package:app_wallet/library_section/main_library.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as prov;
import 'dart:math' as math;

class _HolePainter extends CustomPainter {
  final Rect holeRect;
  final double borderRadius;
  final Color overlayColor;

  _HolePainter({required this.holeRect, this.borderRadius = 8.0, required this.overlayColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, paint);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)), clearPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolePainter old) {
    return old.holeRect != holeRect || old.borderRadius != borderRadius || old.overlayColor != overlayColor;
  }
}

class WalletProfilePage extends ConsumerStatefulWidget {
  final String? userEmail;

  const WalletProfilePage({Key? key, this.userEmail}) : super(key: key);

  @override
  ConsumerState<WalletProfilePage> createState() => _WalletProfilePageState();
}

class _WalletProfilePageState extends ConsumerState<WalletProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  late String? userEmail;
  late String? userName;

  // GlobalKeys para FTU
  final GlobalKey _headerCardKey = GlobalKey();
  final GlobalKey _ingresosMenualesKey = GlobalKey();
  final GlobalKey _ingresosImprevistosKey = GlobalKey();
  final GlobalKey _gmailKey = GlobalKey();
  final GlobalKey _recurrentesKey = GlobalKey();
  final GlobalKey _configuracionKey = GlobalKey();
  bool _ftuShown = false;

  @override
  void initState() {
    super.initState();

    userEmail = user?.email;
    userName = user?.displayName;
    _checkConnection();

    // Verificar si debe mostrar FTU
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map && args['showProfileFTU'] == true && !_ftuShown) {
          _ftuShown = true;
          _showProfileFTU();
        }
      } catch (_) {}
    });
  }

  Future<void> _checkConnection() async {
    try {
      await Connectivity().checkConnectivity();
    } catch (_) {}
  }

  String getFirstName(String? fullName) {
    if (fullName == null || fullName.isEmpty) return '';
    return fullName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final aliasFromProvider = prov.Provider.of<AliasProvider>(context).alias;

    double aliasSize = responsiveFontSize(context, AwSize.s24, min: AwSize.s14, max: AwSize.s20);
    double emailSize = responsiveFontSize(context, AwSize.s14, min: AwSize.s8, max: AwSize.s14);
    double buttonTextSize = responsiveFontSize(context, AwSize.s14, min: AwSize.s8, max: AwSize.s14);

    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: const WalletAppBar(
        title: AwText.bold('Mi Wallet', color: AwColors.white),
        actions: [],
      ),
      body: Column(
        children: [
          AwSpacing.m,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: HeaderLabel(
              key: _headerCardKey,
              cardStyle: true,
              backChild: HomeIncomeSummary(
                controller: prov.Provider.of<WalletExpensesController>(context, listen: false),
                mainTextColor: AwColors.white,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AwColors.blue,
                    child: Icon(Icons.person, size: 40, color: AwColors.white),
                  ),
                  AwSpacing.w16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AwText.bold(
                          aliasFromProvider != null && aliasFromProvider.isNotEmpty
                              ? 'Hola, $aliasFromProvider 👋'
                              : 'Hola...👋',
                          color: AwColors.white,
                          size: aliasSize,
                          textOverflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        AwSpacing.s6,
                        AwText.bold(
                          userEmail ?? '',
                          color: AwColors.white.withOpacity(0.95),
                          size: emailSize,
                          textOverflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        AwSpacing.s6,
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final textScale = MediaQuery.textScaleFactorOf(context);
                            double dateSize = AwSize.s14;
                            if (textScale > 1.0) {
                              dateSize = (AwSize.s14 / textScale) * 0.95;
                              dateSize = dateSize.clamp(AwSize.s8, AwSize.s14);
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: AwText.normal(
                                    "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
                                    color: AwColors.white.withOpacity(0.95),
                                    size: responsiveFontSize(context, AwSize.s14, min: AwSize.s8, max: AwSize.s14),
                                    textOverflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                AwSpacing.w6,
                                GestureDetector(
                                  onTap: () {
                                    LogOutDialog.showLogOutDialog(context);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.logout, color: AwColors.white, size: 16),
                                        AwSpacing.w6,
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 140),
                                          child: Text(
                                            'Cerrar sesión',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: buttonTextSize,
                                              fontWeight: FontWeight.bold,
                                              color: AwColors.white,
                                              decoration: TextDecoration.underline,
                                              decorationColor: AwColors.white,
                                              decorationThickness: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AwSpacing.s20,
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AwText.bold('Menú', color: AwColors.blue, size: AwSize.s18),
            ),
          ),
          AwSpacing.s12,
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SettingsCard(
                          key: _ingresosMenualesKey,
                          title: 'Ingresos Mensuales',
                          icon: Icons.calendar_month,
                          onTap: () async {
                            try {
                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IngresosPage()));
                            } catch (_) {}
                          },
                        ),
                      ),
                      AwSpacing.s6,
                      SizedBox(
                        width: double.infinity,
                        child: SettingsCard(
                          key: _ingresosImprevistosKey,
                          title: 'Ingresos Imprevistos',
                          icon: Icons.savings,
                          onTap: () async {
                            try {
                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => const IngresosImprevistosPage(),
                                ),
                              );
                              if (!mounted) return;
                              if (result == true) {
                                WalletPopup.showNotificationSuccess(
                                  context: context,
                                  title: 'Ingreso imprevisto guardado',
                                  visibleTime: 2,
                                  isDismissible: true,
                                );
                              }
                            } catch (_) {}
                          },
                        ),
                      ),
                      AwSpacing.s6,
                      SizedBox(
                        width: double.infinity,
                        child: SettingsCard(
                          key: _gmailKey,
                          title: 'Ver correos (Gmail)',
                          icon: Icons.email,
                          onTap: () async {
                            final connectivity = await Connectivity().checkConnectivity();
                            if (connectivity == ConnectivityResult.none) {
                              if (!mounted) return;
                              WalletPopup.showNotificationWarningOrange(
                                // ignore: use_build_context_synchronously
                                context: context,
                                message: 'No es posible abrir correos sin conexión',
                                visibleTime: 2,
                                isDismissible: true,
                              );
                              return;
                            }
                            try {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => const GmailInboxPage()));
                            } catch (e) {
                              if (kDebugMode) log('Error abriendo GmailInboxPage: $e');
                              if (mounted) {
                                WalletPopup.showNotificationWarningOrange(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  message: 'No es posible abrir la bandeja de correos',
                                  visibleTime: 2,
                                  isDismissible: true,
                                );
                                return;
                              }
                            }
                          },
                        ),
                      ),
                      AwSpacing.s6,
                      SizedBox(
                        width: double.infinity,
                        child: SettingsCard(
                          key: _recurrentesKey,
                          title: 'Registro de Gastos Recurrentes',
                          icon: Icons.list_alt,
                          onTap: () async {
                            try {
                              await Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (_) => const RecurrentRegistryPage()));
                            } catch (_) {}
                          },
                        ),
                      ),
                      AwSpacing.s6,
                      SizedBox(
                        width: double.infinity,
                        child: SettingsCard(
                          key: _configuracionKey,
                          title: 'Configuración',
                          icon: Icons.settings,
                          onTap: () async {
                            try {
                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                            } catch (_) {}
                          },
                        ),
                      ),
                      AwSpacing.s18,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileFTU() async {
    try {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));

      // Paso 1: Destacar la card principal
      await _showOverlayForKey(
        _headerCardKey,
        title: 'Información Personal',
        message: 'Aquí están tus datos personales y puedes cerrar sesión cuando lo necesites.',
      );

      // Paso 2: Ingresos Mensuales
      await _showOverlayForKey(
        _ingresosMenualesKey,
        title: 'Ingresos Mensuales',
        message: 'Desde aquí podrás editar o agregar tu ingreso mensual.',
      );

      // Paso 3: Ingresos Imprevistos
      await _showOverlayForKey(
        _ingresosImprevistosKey,
        title: 'Ingresos Imprevistos',
        message: 'Aquí podrás agregar ingresos imprevistos o extraordinarios.',
      );

      // Paso 4: Ver correos (Gmail)
      await _showOverlayForKey(
        _gmailKey,
        title: 'Ver correos (Gmail)',
        message: 'Desde aquí podrás identificar correos asociados al banco y agregar gastos directamente desde ellos.',
      );

      // Paso 5: Registro de Gastos Recurrentes
      await _showOverlayForKey(
        _recurrentesKey,
        title: 'Gastos Recurrentes',
        message: 'Aquí podrás ver la lista y el registro de los gastos recurrentes que vayas agregando.',
      );

      // Paso 6: Configuración (último paso)
      await _showOverlayForKey(
        _configuracionKey,
        title: 'Configuración',
        message:
            'Aquí dentro podrás editar tu alias, configurar el PIN de seguridad y visualizar los términos y condiciones.',
        isFinalStep: true,
      );

      // Mostrar popup final de bienvenida
      if (mounted) {
        await _showFinalWelcomeDialog();
      }
    } catch (_) {}
  }

  Future<void> _showOverlayForKey(
    GlobalKey key, {
    required String title,
    required String message,
    bool isFinalStep = false,
  }) async {
    try {
      final ctx = key.currentContext;
      if (ctx == null) return;

      try {
        await Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.3);
      } catch (_) {}

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final targetPos = renderBox.localToGlobal(Offset.zero);
      final targetSize = renderBox.size;

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'profile_ftu',
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, a1, a2) {
          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HolePainter(
                      holeRect: Rect.fromLTWH(
                        targetPos.dx - 8,
                        targetPos.dy - 8,
                        targetSize.width + 16,
                        targetSize.height + 16,
                      ),
                      borderRadius: 12,
                      overlayColor: AwColors.black.withOpacity(0.45),
                    ),
                  ),
                ),
                Positioned(
                  left: targetPos.dx - 8,
                  top: targetPos.dy - 8,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: targetSize.width + 16,
                      height: targetSize.height + 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AwColors.appBarColor, width: 3),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (() {
                    final screenW = MediaQuery.of(context).size.width;
                    final popupW = math.min(320, screenW - 32);
                    return (screenW - popupW) / 2;
                  })(),
                  top: (() {
                    const popupApproxH = 160.0;
                    final preferAbove = targetPos.dy - popupApproxH - 12;
                    if (preferAbove >= 16) return preferAbove;
                    final preferBelow = targetPos.dy + targetSize.height + 12;
                    final screenH = MediaQuery.of(context).size.height;
                    if (preferBelow + popupApproxH <= screenH - 16) return preferBelow;
                    return 16.0;
                  })(),
                  child: Container(
                    width: math.min(320, MediaQuery.of(context).size.width - 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AwColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AwColors.black.withOpacity(0.18), blurRadius: 8)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AwText.bold(title, size: AwSize.s14),
                        AwSpacing.s6,
                        AwText.normal(message, size: AwSize.s12, color: AwColors.modalGrey),
                        AwSpacing.s10,
                        Row(
                          children: [
                            Expanded(
                              child: WalletButton.primaryButton(
                                buttonText: 'Continuar',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {}
  }

  Future<void> _showFinalWelcomeDialog() async {
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AwColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AwColors.green,
                    size: 64,
                  ),
                  AwSpacing.m,
                  const AwText.bold(
                    '¡Recorrido Completado!',
                    size: AwSize.s20,
                    color: AwColors.appBarColor,
                    textAlign: TextAlign.center,
                  ),
                  AwSpacing.s12,
                  const AwText.normal(
                    'Has terminado el recorrido guiado del primer uso de la app.',
                    size: AwSize.s14,
                    color: AwColors.modalGrey,
                    textAlign: TextAlign.center,
                  ),
                  AwSpacing.s12,
                  const AwText.normal(
                    'Muchas gracias por utilizar Admin Wallet 💙',
                    size: AwSize.s16,
                    color: AwColors.boldBlack,
                    textAlign: TextAlign.center,
                  ),
                  AwSpacing.m,
                  SizedBox(
                    width: double.infinity,
                    child: WalletButton.primaryButton(
                      buttonText: 'Cerrar',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (_) {}
  }
}
