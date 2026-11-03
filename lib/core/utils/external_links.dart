import 'package:url_launcher/url_launcher.dart';

/// Links can come from remote feeds, so only web URLs may leave the app.
/// Schemes such as `intent:`, `file:` or `tel:` are never launched.
Uri? parseWebUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
  return uri.isScheme('http') || uri.isScheme('https') ? uri : null;
}

/// Opens a web URL externally. Returns false when it is rejected or fails.
Future<bool> openWebUrl(
  String url, {
  Future<bool> Function(Uri uri)? launcher,
}) async {
  final uri = parseWebUrl(url);
  if (uri == null) return false;
  try {
    return await (launcher ?? _launchExternally)(uri);
  } on Exception {
    return false;
  }
}

Future<bool> _launchExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
