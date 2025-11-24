import 'package:app_wallet/library_section/main_library.dart';

class PinPageScaffold extends StatelessWidget {
  final Widget child;
  final bool allowBack;
  final bool transparentAppBar;

  const PinPageScaffold({
    Key? key,
    required this.child,
    this.allowBack = false,
    this.transparentAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AwColors.white,
      appBar: transparentAppBar
          ? WalletAppBar(
              showBackArrow: false,
              title: ' ',
              barColor: Colors.transparent,
              leading: allowBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AwColors.appBarColor),
                      onPressed: () => Navigator.pop(context),
                    )
                  : null,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: AwSpacing.paddingPage,
          child: child,
        ),
      ),
    );
  }
}
