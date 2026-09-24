import 'package:colette/core/result/failure.dart';
import 'package:colette/features/documents/domain/use_cases/document_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEntryName', () {
    test('renvoie le nom sans espaces autour', () {
      expect(validateEntryName('  Ordonnances ').toNullable(), 'Ordonnances');
    });

    for (final raw in ['', '   ', 'a/b', '.', '..', '.cache']) {
      test('refuse « $raw »', () {
        final failure = validateEntryName(raw).getLeft().toNullable();
        expect(
          failure,
          isA<ValidationFailure>().having(
            (f) => f.reason,
            'reason',
            ValidationReason.invalidDocumentName,
          ),
        );
      });
    }
  });

  group('splitExtension', () {
    test('sépare nom et extension', () {
      expect(splitExtension('facture.2026.pdf'), ('facture.2026', '.pdf'));
    });

    test('sans extension', () {
      expect(splitExtension('Lisez-moi'), ('Lisez-moi', ''));
    });

    test('un point final ou initial n\'est pas une extension', () {
      expect(splitExtension('note.'), ('note.', ''));
      expect(splitExtension('.pdf'), ('.pdf', ''));
    });
  });

  group('canMoveInto', () {
    test('vers un autre dossier', () {
      expect(canMoveInto(source: 'Santé/a.pdf', destination: ''), isTrue);
      expect(canMoveInto(source: 'Santé', destination: 'Papiers'), isTrue);
      expect(canMoveInto(source: 'Santé', destination: 'Santé 2026'), isTrue);
    });

    test('pas dans son dossier actuel', () {
      expect(canMoveInto(source: 'Santé/a.pdf', destination: 'Santé'), isFalse);
      expect(canMoveInto(source: 'a.pdf', destination: ''), isFalse);
    });

    test('pas dans lui-même ni un descendant', () {
      expect(canMoveInto(source: 'Santé', destination: 'Santé'), isFalse);
      expect(
        canMoveInto(source: 'Santé', destination: 'Santé/Vaccins'),
        isFalse,
      );
    });
  });
}
