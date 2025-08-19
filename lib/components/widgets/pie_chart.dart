import 'package:app_wallet/library/main_library.dart';

class WalletPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const WalletPieChart({Key? key, required this.data}) : super(key: key);

  @override
  WalletPieChartState createState() => WalletPieChartState();
}

class WalletPieChartState extends State<WalletPieChart> {
  double chartAngle = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          chartAngle += details.delta.dx * 0.01;
        });
      },
      child: Transform.rotate(
        angle: chartAngle,
        child: SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: _getPieChartSections(widget.data),
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections(List<Map<String, dynamic>> data) {
    final total = data.fold(0.0, (sum, item) => sum + (item['amount'] as double));

    return data.map((item) {
      final category = item['category'] as String;
      final amount = item['amount'] as double;
      final percentage = (amount / total) * 100;

      return PieChartSectionData(
        color: WalletCategoryHelper.getCategoryColor(category),
        value: percentage,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}