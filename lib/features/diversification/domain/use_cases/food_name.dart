const _folded = {
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'á': 'a',
  'ã': 'a',
  'ç': 'c',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'î': 'i',
  'ï': 'i',
  'í': 'i',
  'ô': 'o',
  'ö': 'o',
  'ó': 'o',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ú': 'u',
  'ÿ': 'y',
  'ñ': 'n',
  'œ': 'oe',
  'æ': 'ae',
};

final _spaces = RegExp(r'\s+');

/// Nom normalisé pour la recherche et les doublons : minuscules, sans accents,
/// espaces de bord retirés et espaces internes réduits à un seul.
String normalizeFoodName(String name) {
  final buffer = StringBuffer();
  for (final char in name.trim().toLowerCase().split('')) {
    buffer.write(_folded[char] ?? char);
  }
  return buffer.toString().replaceAll(_spaces, ' ');
}
