
class StringHelpers {
  static String camelCaseToCapitalized(String text) {
    return _camelCaseToCapitalized(text);
  }

  static String capitalize(String text) {
    return _capitalize(text);
  }
}
String _camelCaseToCapitalized(String text) {
  final res =
      text
          .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
          .trim();
  return _capitalize(res);
}

String _capitalize(String text) {
  return text[0].toUpperCase() + text.substring(1);
}
