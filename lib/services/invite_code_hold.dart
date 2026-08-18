import 'package:flutter/services.dart';

/// In-memory hold for invite codes from deep links / launch Intent extras.
class InviteCodeHold {
  InviteCodeHold._();

  static const _channel =
      MethodChannel('app.privatematching.baeandlee/invite');

  static String? _code;

  static String? get code => _code;

  static void set(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return;
    _code = t;
  }

  /// Reads Android Intent extras (`code` / `invite`) once at cold start.
  static Future<void> loadFromLaunchExtras() async {
    try {
      final raw = await _channel.invokeMethod<String>('getLaunchInviteCode');
      set(raw);
    } on MissingPluginException {
      // iOS / desktop — deep links only.
    } on PlatformException {
      // Ignore; deep-link path still works.
    }
  }
}
