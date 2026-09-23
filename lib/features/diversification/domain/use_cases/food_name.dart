const _folded = {
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'á': 'a',
  'ã': 'a',
  'å': 'a',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'í': 'i',
  'ì': 'i',
  'ô': 'o',
  'ö': 'o',
  'ó': 'o',
  'ò': 'o',
  'ø': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ú': 'u',
  'ÿ': 'y',
  'ý': 'y',
  'ñ': 'n',
  'œ': 'oe',
  'æ': 'ae',
  '’': "'",
  '‘': "'",
};

final _combiningMarks = RegExp('[\u0300-\u036f]');
final _spaces = RegExp(r'\s+');

/// Nom normalisé pour la recherche et les doublons : minuscules, apostrophes
/// typographiques (`’`, `‘`) ramenées à `'`, sans accents (y compris marques
/// combinantes d'une saisie NFD), espaces de bord retirés et espaces internes
/// réduits à un seul.
String normalizeFoodName(String name) {
  final buffer = StringBuffer();
  for (final char in name.trim().toLowerCase().split('')) {
    buffer.write(_folded[char] ?? char);
  }
  final withoutMarks = buffer.toString().replaceAll(_combiningMarks, '');
  return withoutMarks.replaceAll(_spaces, ' ');
}
