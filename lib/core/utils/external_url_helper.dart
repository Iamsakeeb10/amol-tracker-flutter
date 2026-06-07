import 'package:url_launcher/url_launcher.dart';

/*
Purpose:
Open an external http(s) URL in the platform browser or default handler.

Response:
true when launch succeeds, false when URL is invalid or launch fails.

Business Rules:
- Prepends https:// when the input has no scheme.
- Uses external application mode so PDFs open in a viewer app when available.

Flow:
1. Normalize and parse the URL.
2. Call launchUrl with externalApplication mode.

Side Effects:
- May leave the app to show browser/PDF viewer.

Failure Cases:
- Empty input, invalid URI, or platform launch failure returns false.
*/
Future<bool> launchExternalUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;

  var uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) {
    uri = Uri.tryParse('https://$trimmed');
  }
  if (uri == null) return false;

  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
