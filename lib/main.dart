import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/admin_shell_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/interest_detail_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/shell_screen.dart';
import 'services/deep_links.dart';
import 'services/invite_code_hold.dart';
import 'services/push_service.dart';
import 'services/secure_session_storage.dart';
import 'services/session.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFFFFFFF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  if (AppConfig.supabaseAnonKey.isEmpty && !AppConfig.mockMode) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'SUPABASE_ANON_KEY가 없습니다.\n'
                'lib/secrets.local.dart를 만들거나 --dart-define=MOCK_MODE=true',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  if (AppConfig.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
  } else {
    // Minimal stub client never used in pure mock — still need provider.
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'public-anon-key',
    );
  }

  final session = AppSession(Supabase.instance.client);
  if (AppConfig.mockMode) session.enterMockMode();
  await session.push.initFirebaseIfEnabled();

  runApp(
    ChangeNotifierProvider.value(value: session, child: const BaeAndLeeApp()),
  );
}

class BaeAndLeeApp extends StatefulWidget {
  const BaeAndLeeApp({super.key});

  @override
  State<BaeAndLeeApp> createState() => _BaeAndLeeAppState();
}

class _BaeAndLeeAppState extends State<BaeAndLeeApp> {
  final _navKey = GlobalKey<NavigatorState>();
  final _deepLinks = DeepLinkService();
  String? _pendingShareToken;
  String? _pendingInterestId;
  var _bootstrapped = false;
  var _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (AppConfig.mockMode) {
      final session = context.read<AppSession>();
      session.push.onOpenedInterest = _queueInterest;
      setState(() {
        _showOnboarding = false;
        _bootstrapped = true;
      });
      return;
    }

    await InviteCodeHold.loadFromLaunchExtras();
    await _deepLinks.logStartup();
    final initial = await _deepLinks.getInitialLink();
    if (initial != null) _handleUri(initial);
    _deepLinks.uriLinkStream.listen(_handleUri);

    final done = await OnboardingScreen.hasCompleted();
    if (!mounted) return;
    setState(() {
      _showOnboarding = !done && !AppConfig.mockMode;
      _bootstrapped = true;
    });
    final session = context.read<AppSession>();
    session.push.onOpenedInterest = _queueInterest;
    await session.push.consumeNativeLaunch();
    if (!mounted) return;
    final pendingPush = session.push.takePendingInterestId();
    if (pendingPush != null) _queueInterest(pendingPush);
  }

  String? _lastQueuedInterestId;
  DateTime? _lastQueuedAt;

  void _queueInterest(String interestId) {
    final now = DateTime.now();
    if (interestId == _lastQueuedInterestId &&
        _lastQueuedAt != null &&
        now.difference(_lastQueuedAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastQueuedInterestId = interestId;
    _lastQueuedAt = now;
    final session = context.read<AppSession>();
    if (!session.isSignedIn) {
      setState(() => _pendingInterestId = interestId);
      return;
    }
    _openInterest(interestId);
  }

  void _openInterest(String interestId) {
    context.read<AppSession>().push.dismissBanner();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => InterestDetailScreen(interestId: interestId),
        ),
      );
    });
  }

  void _handleUri(Uri uri) {
    final invite = DeepLinkService.inviteCodeFrom(uri);
    if (invite != null) InviteCodeHold.set(invite);

    final target = DeepLinkService.parse(uri);
    if (target == null) return;
    final session = context.read<AppSession>();
    if (!session.isSignedIn) {
      setState(() => _pendingShareToken = target.token);
      return;
    }
    _resolveAndOpen(target.token);
  }

  Future<void> _resolveAndOpen(String token) async {
    try {
      final api = context.read<AppSession>().api;
      final res = await api.get('/api/mobile/interest/inbox');
      final all = [
        ...((res['received'] as List?) ?? []),
        ...((res['sent'] as List?) ?? []),
      ];
      for (final raw in all) {
        final row = Map<String, dynamic>.from(raw as Map);
        if (row['share_token'] == token || row['male_contact_token'] == token) {
          final id = row['id'] as String;
          _navKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => InterestDetailScreen(interestId: id),
            ),
          );
          return;
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSession>(
      builder: (context, session, _) {
        if (session.isSignedIn && _pendingShareToken != null) {
          final token = _pendingShareToken!;
          _pendingShareToken = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _resolveAndOpen(token);
          });
        }
        if (session.isSignedIn && _pendingInterestId != null) {
          final id = _pendingInterestId!;
          _pendingInterestId = null;
          _openInterest(id);
        }

        Widget home;
        if (!_bootstrapped) {
          home = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (_showOnboarding) {
          home = OnboardingScreen(
            onFinished: () => setState(() => _showOnboarding = false),
            onEnterMock: () {
              session.enterMockMode();
              setState(() => _showOnboarding = false);
            },
          );
        } else if (session.isSignedIn) {
          if (session.showAdminShell) {
            home = const AdminShellScreen();
          } else if (session.requireProfileSetup) {
            home = const ProfileEditScreen(requiredSetup: true);
          } else {
            home = const ShellScreen();
          }
        } else {
          home = const AuthScreen();
        }

        return MaterialApp(
          title: 'Bae & Lee',
          scaffoldMessengerKey: PushService.messengerKey,
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          themeMode: ThemeMode.light,
          navigatorKey: _navKey,
          home: home,
          builder: (context, child) {
            if (!session.isMock) return child ?? const SizedBox.shrink();
            return Banner(
              message: '프로토타입',
              location: BannerLocation.topEnd,
              color: AppTheme.brand,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
