import 'package:colette/features/photo_sharing/domain/entities/broadcast_list.dart';
import 'package:colette/features/photo_sharing/domain/entities/recipient.dart';
import 'package:colette/features/photo_sharing/domain/entities/send_report.dart';
import 'package:colette/features/photo_sharing/domain/use_cases/normalize_phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mamie = Recipient(name: 'Mamie', phone: '06 12 34 56 78');
  const papi = Recipient(name: 'Papi', phone: '+33 6 98 76 54 32');
  const list = BroadcastList(
    id: 'l1',
    name: 'Grands-parents',
    recipients: [mamie],
  );

  group('normalizePhone', () {
    test('garde les chiffres', () {
      expect(normalizePhone(' 06.12-34 56 78 '), '0612345678');
    });

    test('garde le + initial', () {
      expect(normalizePhone('+33 6 98'), '+33698');
    });
  });

  group('BroadcastList', () {
    test('withRecipient ajoute en fin de liste', () {
      expect(list.withRecipient(papi).recipients, [mamie, papi]);
    });

    test('withRecipient ignore un numéro déjà présent, même mis en forme autrement', () {
      const again = Recipient(name: 'Maman de Max', phone: '0612345678');
      expect(list.withRecipient(again), list);
    });

    test('withoutRecipient retire par numéro exact', () {
      expect(list.withoutRecipient(mamie.phone).recipients, isEmpty);
    });
  });

  group('SendReport', () {
    test('anySent', () {
      expect(
        const SendReport(sent: 1, cancelled: 2, failed: 0).anySent,
        isTrue,
      );
      expect(
        const SendReport(sent: 0, cancelled: 2, failed: 1).anySent,
        isFalse,
      );
    });
  });
}
