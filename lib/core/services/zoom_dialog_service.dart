import 'package:shared_preferences/shared_preferences.dart';

class ZoomDialogService {
  ZoomDialogService._();
  static final ZoomDialogService _instance = ZoomDialogService._();
  factory ZoomDialogService() => _instance;

  static const _kSeenKey = 'zoom_dialog_last_seen_zoom_v1';

  Future<bool> hasSeenDialogFor(bool zoomEnabled) async {
    final sp = await SharedPreferences.getInstance();
    final last = sp.getBool(_kSeenKey);
    if (last == null) return false;
    return last == zoomEnabled;
  }

  Future<void> markSeenFor(bool zoomEnabled) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kSeenKey, zoomEnabled);
  }

  Future<bool> hasSeenDialog() async => hasSeenDialogFor(true);
  Future<void> markSeen() async => markSeenFor(true);
}
