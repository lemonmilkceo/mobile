import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import 'api_client.dart';
import 'push_service.dart';

class AppSession extends ChangeNotifier {
  AppSession(this.client) {
    _api = ApiClient(client);
    _push = PushService(_api);
    _mockMode = AppConfig.mockMode;
    client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
      if (isSignedIn && !isMock) {
        _push.registerIfPossible();
      }
    });
  }

  final SupabaseClient client;
  late final ApiClient _api;
  late final PushService _push;
  var _mockMode = false;
  var _preferAdminShell = true;
  var _requireProfileSetup = false;
  Map<String, dynamic>? memberState;

  ApiClient get api => _api;
  PushService get push => _push;

  Session? get session => client.auth.currentSession;
  User? get user => client.auth.currentUser;
  bool get isMock => _mockMode;
  bool get isSignedIn => _mockMode || session != null;
  bool get isAdmin => !isMock && user?.appMetadata['role'] == 'admin';
  bool get showAdminShell => isAdmin && _preferAdminShell;
  bool get requireProfileSetup => _requireProfileSetup;

  void beginProfileSetup() {
    _requireProfileSetup = true;
    notifyListeners();
  }

  void finishProfileSetup() {
    if (!_requireProfileSetup) return;
    _requireProfileSetup = false;
    notifyListeners();
  }

  void enterMemberApp() {
    _preferAdminShell = false;
    notifyListeners();
  }

  void enterAdminConsole() {
    _preferAdminShell = true;
    notifyListeners();
  }

  void enterMockMode() {
    _mockMode = true;
    notifyListeners();
  }

  void exitMockMode() {
    _mockMode = false;
    notifyListeners();
  }

  Future<void> signIn(
    String email,
    String password, {
    bool requireProfileSetup = false,
  }) async {
    _mockMode = false;
    _requireProfileSetup = requireProfileSetup;
    await client.auth.signInWithPassword(email: email, password: password);
    await _push.registerIfPossible();
    if (isAdmin) _preferAdminShell = true;
    await refreshMemberState();
    if (!isAdmin && memberState?['profile']?['complete'] != true) {
      _requireProfileSetup = true;
    }
    notifyListeners();
  }

  Future<void> refreshMemberState() async {
    if (_mockMode || session == null) return;
    try {
      memberState = await _api.get('/api/mobile/me/state');
    } catch (_) {
      memberState = null;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    if (_mockMode) {
      exitMockMode();
      return;
    }
    await _push.unregisterCurrent();
    await client.auth.signOut();
    _requireProfileSetup = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> health() {
    if (_mockMode) {
      return Future.value({
        'ok': true,
        'feedWaitNotice': AppConfig.mockFeedWaitNotice,
        'pushEnabled': false,
        'mock': true,
      });
    }
    return _api.get('/api/mobile/health');
  }
}
