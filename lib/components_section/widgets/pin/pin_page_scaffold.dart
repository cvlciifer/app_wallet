import 'package:app_wallet/library_section/main_library.dart';

class PinPageScaffold extends StatelessWidget {
  final Widget child;
  final bool allowBack;
  final bool transparentAppBar;
  final PreferredSizeWidget? appBar;

  const PinPageScaffold({
    Key? key,
    required this.child,
    this.allowBack = false,
    this.transparentAppBar = false,
    this.appBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 54, 94),
      appBar: appBar ??
          (transparentAppBar
              ? WalletAppBar(
                  showBackArrow: false,
                  title: ' ',
                  barColor: AwColors.white,
                  leading: allowBack
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: AwColors.appBarColor),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                )
              : null),
      body: SafeArea(
        child: Padding(
          padding: AwSpacing.paddingPage,
          child: child,
        ),
      ),
    );
  }
}
