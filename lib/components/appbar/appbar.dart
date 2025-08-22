import 'package:app_wallet/library/main_library.dart';

class WalletAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool zoomLogo;
  final dynamic title;
  final bool? automaticallyImplyLeading;
  final bool? showCloseIcon;
  final bool? showBackArrow;
  final Widget? leading;
  final Color? barColor;
  final bool centerTitle;

  const WalletAppBar({
    super.key,
    this.zoomLogo = false,
    this.title = '',
    this.automaticallyImplyLeading = true,
    this.showCloseIcon = false,
    this.showBackArrow = false,
    this.leading,
    this.barColor = AwColors.appBarColor,
    this.centerTitle = false,
  });

  @override
  _WalletAppBarState createState() => _WalletAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(55);
}

class _WalletAppBarState extends State<WalletAppBar> {
  
  bool _shouldShowLogo() {
    if (widget.title is String) {
      return (widget.title as String).isEmpty;
    } else if (widget.title is AwText) {
      final awText = widget.title as AwText;
      return awText.text == null || awText.text!.isEmpty;
    }
    return widget.title == null || widget.title == '';
  }

  Widget _buildTitle() {
    final textAlign = widget.centerTitle ? TextAlign.center : TextAlign.left;
    
    if (widget.title is String) {
      return AwText.bold(widget.title, textAlign: textAlign);
    } else if (widget.title is AwText) {
      return widget.title;
    } else {
      return AwText.bold(widget.title.toString(), textAlign: textAlign);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: widget.barColor ?? AwColors.blue,
      shadowColor: widget.barColor ?? Colors.transparent,
      surfaceTintColor: widget.barColor ?? AwColors.blue,
      leading: widget.leading ?? 
        (widget.showBackArrow! 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          : widget.automaticallyImplyLeading! ? null : const SizedBox.shrink()),
      title: widget.title is Text
          ? widget.title
          : _shouldShowLogo()
              ? Icon(
                  Icons.account_balance_wallet,
                  size: widget.zoomLogo ? AwSize.s32 : AwSize.s24,
                )
              : _buildTitle(),
      centerTitle: widget.centerTitle,
      automaticallyImplyLeading: widget.automaticallyImplyLeading!,
      actions: [
        if (widget.showCloseIcon!)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        if (widget.zoomLogo)
          Icon(
            Icons.account_balance_wallet,
            size: widget.zoomLogo ? AwSize.s32 : AwSize.s24,
          ),
        const SizedBox(width: AwSize.s16),
      ],
    );
  }
}