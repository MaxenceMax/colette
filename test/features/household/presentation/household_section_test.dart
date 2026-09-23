import 'package:colette/features/household/domain/entities/device_info.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:colette/features/household/presentation/widgets/household_section.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/documents_repository_override.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('affiche le nom de l\'appareil sous le code', (tester) async {
    await pumpApp(
      tester,
      const HouseholdSection(code: 'ABCDEFGH'),
      overrides: [
        currentDeviceProvider.overrideWith(
          (ref) => Stream.value(
            const DeviceInfo(id: 'dev-1', label: 'iPhone de Maxence'),
          ),
        ),
        documentsRepositoryOverride(),
      ],
    );
    expect(find.textContaining('iPhone de Maxence'), findsOneWidget);
  });

  testWidgets('n\'affiche rien tant que l\'appareil n\'est pas chargé', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const HouseholdSection(code: 'ABCDEFGH'),
      overrides: [
        currentDeviceProvider.overrideWith((ref) => Stream.value(null)),
        documentsRepositoryOverride(),
      ],
    );
    expect(find.textContaining('iPhone'), findsNothing);
  });
}
