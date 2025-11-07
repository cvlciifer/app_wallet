import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalLoaderNotifier extends StateNotifier<int> {
  GlobalLoaderNotifier() : super(0);

  void show() => state = state + 1;

  void hide() {
    if (state <= 0) return;
    state = state - 1;
  }

  bool get visible => state > 0;
}

final globalLoaderProvider = StateNotifierProvider<GlobalLoaderNotifier, int>(
  (ref) => GlobalLoaderNotifier(),
);
