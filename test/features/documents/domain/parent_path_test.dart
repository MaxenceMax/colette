import 'package:colette/features/documents/domain/use_cases/parent_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parentPath renvoie le dossier contenant', () {
    expect(parentPath('Ordonnances/2026/a.pdf'), 'Ordonnances/2026');
    expect(parentPath('Ordonnances/a.pdf'), 'Ordonnances');
  });

  test('parentPath renvoie la racine pour un chemin sans séparateur', () {
    expect(parentPath('a.pdf'), '');
    expect(parentPath(''), '');
  });
}
