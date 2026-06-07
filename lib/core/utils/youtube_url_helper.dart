/*
Purpose:
Extract a YouTube video id from common share/watch URL formats.

Response:
Video id string, or null when the URL is missing or unrecognized.

Business Rules:
- Supports youtu.be, watch?v=, /embed/, /shorts/, and /live/ paths.
- Empty or scheme-less invalid URLs return null.

Flow:
1. Parse trimmed input as Uri.
2. Match host/path patterns used by YouTube links.
3. Return the first valid id segment.

Side Effects:
  None.

Failure Cases:
- Unparseable URL or unknown format returns null.
*/
String? extractYoutubeVideoId(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  if (uri.host.contains('youtu.be')) {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    return id.isNotEmpty ? id : null;
  }

  if (uri.host.contains('youtube.com') ||
      uri.host.contains('youtube-nocookie.com')) {
    final queryId = uri.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final segments = uri.pathSegments;
    if (segments.length >= 2) {
      final prefix = segments.first;
      if (prefix == 'embed' || prefix == 'shorts' || prefix == 'live') {
        return segments[1];
      }
    }
  }

  return null;
}

String youtubeWatchUrl(String videoId) =>
    'https://www.youtube.com/watch?v=$videoId';
