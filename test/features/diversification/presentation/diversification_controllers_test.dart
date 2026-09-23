import 'package:colette/core/clock/app_clock.dart';
import 'package:colette/core/ids/id_generator.dart';
import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/entities/allergen.dart';
import 'package:colette/features/diversification/domain/entities/food.dart';
import 'package:colette/features/diversification/domain/entities/food_group.dart';
import 'package:colette/features/diversification/domain/entities/tasting.dart';
import 'package:colette/features/diversification/presentation/providers/custom_food_controller.dart';
import 'package:colette/features/diversification/presentation/providers/diversification_providers.dart';
import 'package:colette/features/diversification/presentation/providers/tasting_form_controller.dart';
import 'package:colette/features/household/presentation/providers/household_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/in_memory_household_local_store.dart';
import '../helpers/catalog_fixture.dart';
import '../helpers/diversification_overrides.dart';

void main() {
  const code = 'ABCDEFGH';
  final now = DateTime(2027, 4, 10, 18);
  late MockTastingsRepository tastingsRepo;
  late MockCustomFoodsRepository foodsRepo;
  late ProviderContainer container;
  const kaki = Food(
    id: 'c1',
    name: 'Kaki',
    group: FoodGroup.vitaminAFruitsVeg,
    isCustom: true,
  );

  setUpAll(() {
    registerFallbackValue(Tasting(id: '', foodId: '', at: DateTime(2000)));
    registerFallbackValue(kaki);
  });

  setUp(() async {
    tastingsRepo = MockTastingsRepository();
    foodsRepo = MockCustomFoodsRepository();
    when(() => tastingsRepo.save(any(), any()))
        .thenAnswer((_) async => right(null));
    when(() => tastingsRepo.delete(any(), any()))
        .thenAnswer((_) async => right(null));
    when(() => foodsRepo.save(any(), any()))
        .thenAnswer((_) async => right(null));
    when(() => foodsRepo.delete(any(), any()))
        .thenAnswer((_) async => right(null));
    container = ProviderContainer(
      overrides: [
        tastingsRepositoryProvider.overrideWithValue(tastingsRepo),
        customFoodsRepositoryProvider.overrideWithValue(foodsRepo),
        clockProvider.overrideWithValue(FixedClock(now)),
        idGeneratorProvider.overrideWithValue(const FixedIdGenerator('new-id')),
        householdLocalStoreProvider.overrideWithValue(
          InMemoryHouseholdLocalStore(householdCode: code),
        ),
        foodCatalogProvider.overrideWith((ref) async => catalogFixture()),
        customFoodsProvider.overrideWith((ref) => Stream.value(const [kaki])),
        tastingsProvider.overrideWith(
          (ref) => Stream.value([
            Tasting(id: 't1', foodId: 'c1', at: DateTime(2027, 4, 1)),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Ne pas écouter foodsProvider/tastingsProvider directement : on reproduit
    // la situation d'une feuille (CustomFoodSheet/TastingFormSheet) ouverte
    // depuis un Scaffold nu, où seuls les contrôleurs sont watchés. C'est aux
    // contrôleurs eux-mêmes de garder leurs sources en vie.
    container
      ..listen(tastingFormControllerProvider, (_, _) {})
      ..listen(customFoodControllerProvider, (_, _) {});
    await container.read(foodCatalogProvider.future);
    await container.read(customFoodsProvider.future);
    await container.read(tastingsProvider.future);
  });

  group('TastingFormController', () {
    TastingFormController controller() =>
        container.read(tastingFormControllerProvider.notifier);

    test('nouvelle dégustation : id généré, note nettoyée', () async {
      final ok = await controller().save(
        Tasting(id: '', foodId: 'carotte', at: now, note: '  '),
      );
      expect(ok, isTrue);
      final saved =
          verify(() => tastingsRepo.save(code, captureAny())).captured.single
              as Tasting;
      expect(saved.id, 'new-id');
      expect(saved.note, isNull);
    });

    test('modification : id conservé', () async {
      await controller().save(
        Tasting(id: 't1', foodId: 'carotte', at: now, note: ' Aimé '),
      );
      final saved =
          verify(() => tastingsRepo.save(code, captureAny())).captured.single
              as Tasting;
      expect(saved.id, 't1');
      expect(saved.note, 'Aimé');
    });

    test('date future refusée', () async {
      final ok = await controller().save(
        Tasting(
          id: '',
          foodId: 'carotte',
          at: now.add(const Duration(minutes: 1)),
        ),
      );
      expect(ok, isFalse);
      verifyNever(() => tastingsRepo.save(any(), any()));
      final state = container.read(tastingFormControllerProvider);
      expect(
        (state.error! as ValidationFailure).reason,
        ValidationReason.startInFuture,
      );
    });

    test('échec du repository : état en erreur', () async {
      when(() => tastingsRepo.save(any(), any()))
          .thenAnswer((_) async => left(const NetworkFailure()));
      expect(
        await controller().save(Tasting(id: '', foodId: 'carotte', at: now)),
        isFalse,
      );
      expect(
        container.read(tastingFormControllerProvider).error,
        isA<NetworkFailure>(),
      );
    });

    test('delete', () async {
      expect(await controller().delete('t1'), isNull);
      verify(() => tastingsRepo.delete(code, 't1')).called(1);
    });
  });

  group('CustomFoodController', () {
    CustomFoodController controller() =>
        container.read(customFoodControllerProvider.notifier);

    test('création : id généré, nom nettoyé, marqué perso', () async {
      final ok = await controller().save(
        name: ' Datte ',
        group: FoodGroup.otherFruitsVeg,
        allergens: const {Allergen.sulphites},
      );
      expect(ok, isTrue);
      final saved =
          verify(() => foodsRepo.save(code, captureAny())).captured.single
              as Food;
      expect(
        saved,
        const Food(
          id: 'new-id',
          name: 'Datte',
          group: FoodGroup.otherFruitsVeg,
          allergens: {Allergen.sulphites},
          isCustom: true,
        ),
      );
    });

    test('doublon avec le catalogue refusé', () async {
      final ok = await controller().save(
        name: 'carotte',
        group: FoodGroup.dairy,
        allergens: const {},
      );
      expect(ok, isFalse);
      expect(
        (container.read(customFoodControllerProvider).error!
                as ValidationFailure)
            .reason,
        ValidationReason.duplicateFoodName,
      );
    });

    test('doublon avec un autre aliment perso refusé', () async {
      final ok = await controller().save(
        name: 'kaki',
        group: FoodGroup.otherFruitsVeg,
        allergens: const {},
      );
      expect(ok, isFalse);
      expect(
        (container.read(customFoodControllerProvider).error!
                as ValidationFailure)
            .reason,
        ValidationReason.duplicateFoodName,
      );
    });

    test(
      'renommer un aliment perso sans changer son nom n\'est pas un doublon',
      () async {
        final ok = await controller().save(
          id: 'c1',
          name: 'Kaki',
          group: FoodGroup.otherFruitsVeg,
          allergens: const {},
        );
        expect(ok, isTrue);
      },
    );

    test('suppression refusée si des dégustations existent', () async {
      final failure = await controller().delete('c1');
      expect(
        (failure! as ValidationFailure).reason,
        ValidationReason.customFoodInUse,
      );
      verifyNever(() => foodsRepo.delete(any(), any()));
      expect(
        (container.read(customFoodControllerProvider).error!
                as ValidationFailure)
            .reason,
        ValidationReason.customFoodInUse,
      );
    });

    test('suppression sans dégustation', () async {
      expect(await controller().delete('c2'), isNull);
      verify(() => foodsRepo.delete(code, 'c2')).called(1);
    });
  });
}
