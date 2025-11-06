import 'package:flutter/material.dart';
import 'package:app_wallet/library_section/main_library.dart';

class MonthActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const MonthActionButton({super.key, required this.label, required this.onTap});

  @override
  State<MonthActionButton> createState() => _MonthActionButtonState();
}

class _MonthActionButtonState extends State<MonthActionButton> {
  double _scale = 1.0;

  void _pressDown(_) => setState(() => _scale = 0.96);
  void _pressUp() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AwColors.appBarColor,
          decorationColor: AwColors.appBarColor,
        );

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          widget.onTap();
          _pressUp();
        },
        onTapDown: _pressDown,
        onTapCancel: _pressUp,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Text(widget.label, style: textStyle),
        ),
      ),
    );
  }
}
