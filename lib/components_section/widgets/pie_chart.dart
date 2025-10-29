import 'package:app_wallet/library_section/main_library.dart';

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
    return data.map((item) {
      final label = item['label'] as String;
      final amount = item['amount'] as double;
      final Color? color = item['color'] as Color?;

      return PieChartSectionData(
        color: color ?? WalletCategoryHelper.getCategoryColor(label),
        value: amount,
        title: '',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AwColors.white,
        ),
      );
    }).toList();
  }
}
