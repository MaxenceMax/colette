import 'package:colette/app/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('racine', () {
    expect(AppRoutes.documentsLocation(''), '/today/documents');
  });

  test('sous-dossier encodé en paramètre de requête', () {
    expect(
      AppRoutes.documentsLocation('Ordonnances/2026'),
      '/today/documents?path=Ordonnances%2F2026',
    );
  });
}
