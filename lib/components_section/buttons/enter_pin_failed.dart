import 'package:flutter/material.dart';
import 'package:app_wallet/library_section/main_library.dart';

class EnterPinFailed extends StatelessWidget {
  final int remainingAttempts;

  const EnterPinFailed({Key? key, required this.remainingAttempts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange[700],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PIN incorrecto. Quedan $remainingAttempts intento(s).',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
