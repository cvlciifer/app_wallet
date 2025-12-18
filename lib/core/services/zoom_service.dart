import 'package:display_zoom_checker/display_zoom_checker.dart';
import 'package:app_wallet/library_section/main_library.dart';

class ZoomService {
  ZoomService._internal();
  static final ZoomService _instance = ZoomService._internal();
  factory ZoomService() => _instance;

  final ValueNotifier<bool?> isZoomed = ValueNotifier<bool?>(null);

  Future<void> init() async {
    try {
      final zoomed = await DisplayZoomChecker.isDisplayZoomed();
      isZoomed.value = zoomed;
    } catch (e) {
      isZoomed.value = false;
    }
  }
}
