import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Outdoor / sunlight** mode: maximum contrast theme for volunteer & responder UIs.
class HighContrastOpsNotifier extends Notifier<bool> {
  static const _prefKey = 'responder_high_contrast_ops_v1';

  @override
  bool build() {
    Future.microtask(() async {
      final p = await SharedPreferences.getInstance();
      final v = p.getBool(_prefKey) ?? false;
      if (state != v) state = v;
    });
    return false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefKey, value);
  }
}

final highContrastOpsProvider = NotifierProvider<HighContrastOpsNotifier, bool>(HighContrastOpsNotifier.new);
