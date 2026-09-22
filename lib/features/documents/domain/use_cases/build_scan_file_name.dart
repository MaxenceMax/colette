String _two(int value) => value.toString().padLeft(2, '0');

/// Nom du PDF produit par le scanner : « Scan 22-09-2026 14h32.pdf ».
/// Préfixe fixe : le domaine n'a pas accès à la l10n.
String buildScanFileName(DateTime now) =>
    'Scan ${_two(now.day)}-${_two(now.month)}-${now.year} '
    '${_two(now.hour)}h${_two(now.minute)}.pdf';
