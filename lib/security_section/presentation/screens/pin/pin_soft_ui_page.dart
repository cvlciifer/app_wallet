import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../library_section/main_library.dart';

typedef PinCompletedCallback = Future<bool?> Function(String pin);

class PinSoftUIPage extends StatefulWidget {
  final PinCompletedCallback? onCompleted;
  final String title;
  final ValueChanged<int>? onChanged;
  final ValueChanged<String>? onPinChanged;

  const PinSoftUIPage({
    Key? key,
    this.onCompleted,
    this.title = 'Ingresa tu PIN',
    this.onChanged,
    this.onPinChanged,
  }) : super(key: key);

  @override
  State<PinSoftUIPage> createState() => _PinSoftUIPageState();
}

class _PinSoftUIPageState extends State<PinSoftUIPage> with TickerProviderStateMixin {
  final List<int> _pin = [];

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _successController;

  int? _pressedKey;

  // ------------ COLORES VIDRIO SOBRE FONDO BLANCO ---------------
  final Color _bg = Colors.white;

  final Color _buttonColor = Colors.white.withOpacity(0.20);
  final Color _buttonColorPressed = Colors.white.withOpacity(0.35);

  final Color _indicatorFilled = Colors.black87;
  final Color _indicatorEmpty = Colors.black26;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------
  // -------------------- LOGICA -----------------------
  // ---------------------------------------------------

  void _addDigit(int digit) {
    if (_pin.length >= 4) return;

    setState(() => _pin.add(digit));
    widget.onChanged?.call(_pin.length);
    widget.onPinChanged?.call(_pin.join());

    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), () => _onCompleted());
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() => _pin.removeLast());
    }
    widget.onChanged?.call(_pin.length);
    widget.onPinChanged?.call(_pin.join());
  }

  Future<void> _onCompleted() async {
    final pin = _pin.join();
    if (widget.onCompleted == null) return;

    try {
      final result = await widget.onCompleted!(pin);

      if (result == true) {
        await _playSuccess();
      } else {
        await _playError();
      }
    } catch (_) {
      await _playError();
    }
  }

  Future<void> _playError() async {
    _shakeController.reset();
    _shakeController.forward();

    await Future.delayed(const Duration(milliseconds: 420));
    setState(() => _pin.clear());

    widget.onChanged?.call(0);
    widget.onPinChanged?.call('');
  }

  Future<void> _playSuccess() async {
    await _successController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 260));

    setState(() => _pin.clear());
    widget.onChanged?.call(0);
    widget.onPinChanged?.call('');
    _successController.reset();
  }

  // ---------------------------------------------------
  // -------------------- BUILD ------------------------
  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: AnimatedBuilder(
          animation: _shakeController,
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildIndicators(),
                  const SizedBox(height: 15),
                  _buildKeypad(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------
  // ---------------- INDICADORES PIN ------------------
  // ---------------------------------------------------

  Widget _buildIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final filled = index < _pin.length;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: filled ? _indicatorFilled : AwColors.boldBlack,
            shape: BoxShape.circle,
            border: Border.all(
              color: filled ? Colors.transparent : _indicatorEmpty,
              width: 1.6,
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------
  // ------------------- KEYPAD ------------------------
  // ---------------------------------------------------

  Widget _buildKeypad() {
    const keys = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
      ['', 0, '<'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildSoftKey(key),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------
  // ------------------- TECLAS FLOATING ---------------
  // ---------------------------------------------------

  Widget _buildSoftKey(dynamic key) {
    final isEmpty = key == '';
    final isBack = key == '<';

    if (isEmpty) return const SizedBox();

    final label = isBack ? '⌫' : key.toString();
    final pressed = _pressedKey == key.hashCode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(72.0, 110.0);

        return GestureDetector(
          onTapDown: (_) => setState(() => _pressedKey = key.hashCode),
          onTapUp: (_) => setState(() => _pressedKey = null),
          onTapCancel: () => setState(() => _pressedKey = null),
          onTap: () {
            if (isBack) {
              _removeDigit();
            } else {
              _addDigit(int.parse(label));
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed ? Colors.black.withOpacity(0.10) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            transform: Matrix4.identity()..scale(pressed ? 0.90 : 1.0),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.black87.withOpacity(pressed ? 0.9 : 1.0),
              ),
            ),
          ),
        );
      },
    );
  }
}
