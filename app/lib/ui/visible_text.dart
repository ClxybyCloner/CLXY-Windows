/// Removes upstream/provider identity and URLs from text supplied by the core
/// before it is shown or copied by the app UI.
String sanitizeVisibleText(String text) {
  final urlPattern = RegExp(r"""https?://[^\s<>"']+""", caseSensitive: false);
  var result = text.replaceAllMapped(urlPattern, (match) {
    final url = match.group(0)!;
    final trailingPunctuation =
        RegExp(r'[.,;:!?)]*$').firstMatch(url)!.group(0)!;
    return '[link]$trailingPunctuation';
  });
  result = result.replaceAll(
    RegExp(r'\b(?:accounts\.)?firefox\.com\b', caseSensitive: false),
    '[service]',
  );
  result = result.replaceAll(
    RegExp(r'\bmozilla(?:\.org|\.com)?\b', caseSensitive: false),
    'service',
  );
  result = result.replaceAll(
    RegExp(r'\bfirefox(?:\s+account)?\b', caseSensitive: false),
    'account',
  );
  result = result.replaceAll(
    RegExp(r'\barman(?:[\s_-]*vpn)(?:[\s_-]*client)?\b', caseSensitive: false),
    'CLXY',
  );
  result = result.replaceAll(
    RegExp(
      r'\b(?:github\.com/)?arman(?:life|[-_]org|\.org)(?:\.com)?(?:/[a-z0-9_.-]+)*\b',
      caseSensitive: false,
    ),
    '[service]',
  );
  return result;
}
