import 'package:app_wallet/components_section/styles/colors.dart';
import 'package:app_wallet/components_section/styles/sizes.dart';
import 'package:flutter/material.dart';

class WalletLoader extends StatefulWidget {
  final Color color;
  const WalletLoader({super.key, this.color = AwColors.appBarColor});

  @override
  State<WalletLoader> createState() => _WalletLoaderState();
}

class _WalletLoaderState extends State<WalletLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(
        Icons.account_balance_wallet,
        size: AwSize.s50,
        color: widget.color,
      ),
    );
  }
}
