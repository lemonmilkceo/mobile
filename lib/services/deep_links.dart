import 'package:app_links/app_links.dart';

import '../config.dart';

/// Parses Universal / App Links into in-app routes.
/// `https://privatematching.vercel.app/match/{token}` → interest by share token
/// (resolved via inbox list match on share_token).
/// `?code=` / `?invite=` → invite signup prefill via [InviteCodeHold].
class DeepLinkService {
  DeepLinkService();

  final _appLinks = AppLinks();

  Stream<Uri> get uriLinkStream => _appLinks.uriLinkStream;

  Future<Uri?> getInitialLink() => _appLinks.getInitialLink();

  /// Returns interest share_token or male_contact_token from path.
  static DeepLinkTarget? parse(Uri uri) {
    if (uri.host != AppConfig.deepLinkHost && uri.host != 'localhost') {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments[0] == 'match') {
      if (segments[1] == 'contact' && segments.length >= 3) {
        return DeepLinkTarget.contact(segments[2]);
      }
      return DeepLinkTarget.offer(segments[1]);
    }
    return null;
  }

  /// Invite code from query `code` or `invite` (any path on our host).
  static String? inviteCodeFrom(Uri uri) {
    final hostOk = uri.host.isEmpty ||
        uri.host == AppConfig.deepLinkHost ||
        uri.host == 'localhost';
    if (!hostOk) return null;
    final raw =
        uri.queryParameters['code'] ?? uri.queryParameters['invite'];
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> logStartup() async {}
}

class DeepLinkTarget {
  DeepLinkTarget.offer(this.token) : kind = DeepLinkKind.offer;
  DeepLinkTarget.contact(this.token) : kind = DeepLinkKind.contact;

  final DeepLinkKind kind;
  final String token;
}

enum DeepLinkKind { offer, contact }
