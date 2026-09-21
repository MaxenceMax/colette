import 'package:colette/features/events/domain/use_cases/new_event_draft.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 21, 14, 30);

  test(
    'le brouillon est daté de maintenant, vide, avec l\'appareil courant',
    () {
      final draft = newEventDraft(now: now, deviceId: 'dev-1', id: 'e1');
      expect(draft.startAt, now);
      expect(draft.endAt, now);
      expect(draft.createdByDeviceId, 'dev-1');
      expect(draft.isEmpty, isTrue);
    },
  );

  test('preChecked et bottleMl préremplissent le brouillon', () {
    final draft = newEventDraft(
      now: now,
      deviceId: 'dev-1',
      id: 'e1',
      preChecked: CareType.adrigyl,
      bottleMl: 120,
    );
    expect(draft.adrigyl, isTrue);
    expect(draft.bottleMl, 120);
  });
}
