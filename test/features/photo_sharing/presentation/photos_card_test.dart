import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/clock/now_providers.dart';
import 'package:colette/features/photo_sharing/presentation/providers/photo_sharing_providers.dart';
import 'package:colette/features/photo_sharing/presentation/widgets/photos_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/in_memory_photo_sharing_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 9, 30, 10);

  Future<void> pumpCard(WidgetTester tester, DateTime? lastSentAt) => pumpApp(
    tester,
    const PhotosCard(),
    overrides: [
      clockProvider.overrideWithValue(FixedClock(now)),
      minuteTickerProvider.overrideWith((ref) => const Stream.empty()),
      photoSharingRepositoryProvider.overrideWithValue(
        InMemoryPhotoSharingRepository(lastSentAt: lastSentAt),
      ),
    ],
  );

  testWidgets('aucun envoi', (tester) async {
    await pumpCard(tester, null);
    expect(find.text('Photos'), findsOneWidget);
    expect(find.text("Aucune photo envoyée pour l'instant"), findsOneWidget);
  });

  testWidgets('dernier envoi affiché', (tester) async {
    await pumpCard(tester, DateTime(2026, 9, 30, 8, 5));
    expect(find.text("Dernier envoi · Aujourd'hui, 08h05"), findsOneWidget);
  });
}
