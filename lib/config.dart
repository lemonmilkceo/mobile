import 'secrets.local.dart' as local;

/// Runtime config. Override with `--dart-define=SUPABASE_URL=...` etc.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: local.localSupabaseUrl,
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: local.localSupabaseAnonKey,
  );

  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://privatematching.vercel.app',
  );

  /// When true, initializes Firebase Messaging (requires FlutterFire configure).
  static const fcmEnabled = bool.fromEnvironment(
    'FCM_ENABLED',
    defaultValue: false,
  );

  static const deepLinkHost = String.fromEnvironment(
    'DEEP_LINK_HOST',
    defaultValue: 'privatematching.vercel.app',
  );

  /// Force mock prototype mode (no Supabase session required).
  static const mockMode = bool.fromEnvironment(
    'MOCK_MODE',
    defaultValue: false,
  );

  /// When true in mock mode, feed shows wait notice like production flag.
  static const mockFeedWaitNotice = bool.fromEnvironment(
    'MOCK_FEED_WAIT_NOTICE',
    defaultValue: false,
  );
}
