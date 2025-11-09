import 'dart:math' as math;

import 'package:app_wallet/library_section/main_library.dart';

class _AngularSample {
  final double angle;
  final double time;
  _AngularSample({required this.angle, required this.time});
}

class WalletPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const WalletPieChart({Key? key, required this.data}) : super(key: key);

  @override
  WalletPieChartState createState() => WalletPieChartState();
}

class WalletPieChartState extends State<WalletPieChart> with SingleTickerProviderStateMixin {
  double chartAngle = 0.0;
  double? _startGestureAngle;
  double _baseAngle = 0.0;

  final List<_AngularSample> _samples = [];

  late final AnimationController _animController;
  Animation<double>? _angleAnim;
  VoidCallback? _animListener;

  static const double _maxInertiaTime = 10.0;
  static const double _decayRate = 3.0;
  static const double _stopVelocity = 0.05;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onPanStart: (details) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);
          final center = box.size.center(Offset.zero);
          _startGestureAngle = math.atan2(local.dy - center.dy, local.dx - center.dx);
          _baseAngle = chartAngle;
          _stopInertia();
          _samples.clear();
          _samples
              .add(_AngularSample(angle: _startGestureAngle!, time: DateTime.now().millisecondsSinceEpoch.toDouble()));
        },
        onPanUpdate: (details) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);
          final center = box.size.center(Offset.zero);
          final currentAngle = math.atan2(local.dy - center.dy, local.dx - center.dx);
          if (_startGestureAngle != null) {
            final delta = _normalizeAngle(currentAngle - _startGestureAngle!);
            setState(() {
              chartAngle = _baseAngle + delta;
            });

            _samples.add(_AngularSample(angle: currentAngle, time: DateTime.now().millisecondsSinceEpoch.toDouble()));

            final cutoff = DateTime.now().millisecondsSinceEpoch.toDouble() - 200.0;
            _samples.removeWhere((s) => s.time < cutoff);
          }
        },
        onPanEnd: (_) {
          final velocity = _estimateAngularVelocity();
          _startGestureAngle = null;
          _samples.clear();

          if (velocity.abs() > 0.0002) {
            final velocityPerSec = velocity * 1000.0;
            _startInertia(velocityPerSec);
          }
        },
        child: Transform.rotate(
          angle: chartAngle,
          alignment: Alignment.center,
          child: SizedBox(
            height: 300,
            width: 300,
            child: PieChart(
              PieChartData(
                sections: _getPieChartSections(widget.data),
                pieTouchData: PieTouchData(touchCallback: (event, response) {
                  try {
                    if (response == null) return;
                    final touched = response.touchedSection;
                    if (touched == null) return;

                    final index = touched.touchedSectionIndex;
                    if (index < 0 || index >= widget.data.length) return;

                    final item = widget.data[index];
                    if (event.runtimeType.toString().contains('FlTapUpEvent')) {
                      _showCategoryPopup(context, item);
                    }
                  } catch (_) {}
                }),
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPopup(BuildContext context, Map<String, dynamic> item) {
    final label = item['label'] as String;
    final Color color = (item['color'] as Color?) ?? WalletCategoryHelper.getCategoryColor(label);
    final IconData icon = WalletCategoryHelper.getCategoryIcon(label);

    final amount = (item['amount'] as double?) ?? 0.0;
    final total = widget.data.fold<double>(0.0, (sum, it) => sum + ((it['amount'] as double?) ?? 0.0));
    final percent = total == 0.0 ? 0.0 : (amount / total) * 100;
    final percentStr = '${percent.toStringAsFixed(1)}%';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AwColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        percentStr,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
  }

  @override
  void dispose() {
    _stopInertia();
    _animController.dispose();
    super.dispose();
  }

  double _normalizeAngle(double angle) {
    while (angle > math.pi) angle -= 2 * math.pi;
    while (angle < -math.pi) angle += 2 * math.pi;
    return angle;
  }

  double _estimateAngularVelocity() {
    if (_samples.length < 2) return 0.0;
    final first = _samples.first;
    final last = _samples.last;
    var deltaAngle = _normalizeAngle(last.angle - first.angle);
    var deltaTime = last.time - first.time;
    if (deltaTime <= 0) return 0.0;
    return deltaAngle / deltaTime;
  }

  void _startInertia(double initialVelocity) {
    _stopInertia();

    final decay = _decayRate;
    final startAngle = chartAngle;

    _angleAnim = _animController.drive(Tween(begin: 0.0, end: 1.0));

    _animListener = () {
      final t = _animController.value * _maxInertiaTime;

      final angleOffset = (initialVelocity / decay) * (1 - math.exp(-decay * t));

      final currentVelocity = initialVelocity * math.exp(-decay * t);
      setState(() {
        chartAngle = _normalizeAngle(startAngle + angleOffset);
      });

      if (currentVelocity.abs() < _stopVelocity) {
        _stopInertia();
      }
    };

    _animController.duration = const Duration(seconds: 10);
    _animController.addListener(_animListener!);
    _animController.reset();
    _animController.forward();
  }

  void _stopInertia() {
    try {
      _animController.stop();
    } catch (_) {}
    if (_angleAnim != null) {
      _angleAnim = null;
    }
    if (_animListener != null) {
      _animController.removeListener(_animListener!);
      _animListener = null;
    }
    _animController.reset();
  }

  List<PieChartSectionData> _getPieChartSections(List<Map<String, dynamic>> data) {
    final labels = data.map((d) => (d['label'] as String)).toList();

    final Map<String, Color> labelColor = {};
    for (final item in data) {
      final label = item['label'] as String;
      final Color? c = item['color'] as Color?;
      labelColor[label] = c ?? WalletCategoryHelper.getCategoryColor(label);
    }

    final List<Color> palette = [
      Colors.blue,
      Colors.pink,
      Colors.green,
      Colors.brown,
      Colors.indigo,
      Colors.orange,
      Colors.deepPurple,
      Colors.teal,
      Colors.red,
      Colors.cyan,
      Colors.lime,
      Colors.amber,
    ];

    final Set<int> usedColorValues = {};
    int paletteIndex = 0;

    for (final label in labels) {
      final current = labelColor[label]!;
      final int value = current.value;
      if (!usedColorValues.contains(value)) {
        usedColorValues.add(value);
        continue;
      }
      Color pick = palette[paletteIndex % palette.length];
      paletteIndex++;
      while (usedColorValues.contains(pick.value)) {
        pick = palette[paletteIndex % palette.length];
        paletteIndex++;
      }
      labelColor[label] = pick;
      usedColorValues.add(pick.value);
    }

    final List<PieChartSectionData> sections = [];
    for (final item in data) {
      final label = item['label'] as String;
      final amount = item['amount'] as double;
      final color = labelColor[label]!;

      sections.add(PieChartSectionData(
        color: color,
        value: amount,
        title: '',
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AwColors.white,
        ),
      ));
    }

    return sections;
  }
}
