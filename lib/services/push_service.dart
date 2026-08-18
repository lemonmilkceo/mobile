import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../firebase_options.dart';
import 'api_client.dart';

/// Registers FCM tokens with the BFF when `FCM_ENABLED=true`.
class PushService {
  PushService(this._api);

  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  final ApiClient _api;
  String? _token;
  var _firebaseReady = false;
  String? _pendingInterestId;
  String? _lastOpenedId;
  DateTime? _lastOpenedAt;
  String? viewingInterestId;
  void Function(String interestId)? onOpenedInterest;

  void dismissBanner() {
    messengerKey.currentState?.hideCurrentSnackBar();
  }

  static const _native = MethodChannel('app.privatematching.baeandlee/push');
  static const _nativeOpens =
      EventChannel('app.privatematching.baeandlee/push_opens');

  String? takePendingInterestId() {
    final id = _pendingInterestId;
    _pendingInterestId = null;
    return id;
  }

  static String? interestIdFrom(RemoteMessage message) {
    final id = message.data['interest_id']?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Future<void> initFirebaseIfEnabled() async {
    if (!AppConfig.fcmEnabled) return;
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      debugPrint('PushService: FCM is Android/iOS only');
      return;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
      messaging.onTokenRefresh.listen(registerToken);
      FirebaseMessaging.onMessage.listen(_showForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleOpened(initial);
      if (Platform.isAndroid) {
        _nativeOpens.receiveBroadcastStream().listen((event) {
          if (event is String) _handleOpenedId(event);
        });
        try {
          final nativeId =
              await _native.invokeMethod<String>('getLaunchInterestId');
          if (nativeId != null) _handleOpenedId(nativeId);
        } on MissingPluginException {
          // Older APK without the native channel.
        }
      }
      _firebaseReady = true;
      await registerIfPossible();
    } catch (e) {
      debugPrint('PushService: Firebase init failed: $e');
    }
  }

  void _handleOpened(RemoteMessage message) {
    debugPrint('PushService: opened data=${message.data}');
    final id = interestIdFrom(message);
    if (id == null) return;
    _handleOpenedId(id);
  }

  void _handleOpenedId(String id) {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    if (trimmed == _lastOpenedId &&
        _lastOpenedAt != null &&
        now.difference(_lastOpenedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastOpenedId = trimmed;
    _lastOpenedAt = now;
    _pendingInterestId = trimmed;
    dismissBanner();
    onOpenedInterest?.call(trimmed);
  }

  void _showForeground(RemoteMessage message) {
    final id = interestIdFrom(message);
    if (id != null &&
        (id == viewingInterestId || id == _lastOpenedId)) {
      return;
    }
    final title = message.notification?.title ?? '알림';
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(title),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  Future<void> consumeNativeLaunch() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final nativeId =
          await _native.invokeMethod<String>('getLaunchInterestId');
      if (nativeId != null) _handleOpenedId(nativeId);
    } on MissingPluginException {
      // Channel not registered yet.
    } on PlatformException {
      // Ignore; FCM open handlers still apply.
    }
  }

  Future<void> registerIfPossible() async {
    if (!AppConfig.fcmEnabled || !_firebaseReady) {
      if (AppConfig.fcmEnabled && !_firebaseReady) {
        debugPrint('PushService: Firebase not ready — skip token register');
      } else if (!AppConfig.fcmEnabled) {
        debugPrint('PushService: FCM_ENABLED=false — skip token register');
      }
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;
    try {
      if (Platform.isIOS) {
        String? apns = await FirebaseMessaging.instance.getAPNSToken();
        for (var i = 0; i < 10 && apns == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          apns = await FirebaseMessaging.instance.getAPNSToken();
        }
        if (apns == null) {
          debugPrint('PushService: APNs token not ready — skip FCM register');
          return;
        }
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await registerToken(token);
    } catch (e) {
      debugPrint('PushService: token register failed: $e');
    }
  }

  Future<void> registerToken(String token) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    await _api.put('/api/mobile/device-token', {
      'token': token,
      'platform': platform,
    });
    _token = token;
  }

  Future<void> unregisterCurrent() async {
    final token = _token;
    if (token == null) return;
    try {
      await _api.delete('/api/mobile/device-token', {'token': token});
    } catch (_) {}
    _token = null;
  }
}
