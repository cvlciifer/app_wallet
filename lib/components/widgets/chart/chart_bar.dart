import 'package:app_wallet/library/main_library.dart';

class ChartBar extends StatelessWidget {
  const ChartBar({
    super.key,
    required this.fill,
    required this.barColor, // Color que se pasa como argumento
  });

  final double fill;
  final Color barColor; // Agregamos el color como propiedad

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // Ajuste del padding horizontal
      child: FractionallySizedBox(
        heightFactor: fill, // De 0 a 1
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: barColor, // Usamos el color proporcionado
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
