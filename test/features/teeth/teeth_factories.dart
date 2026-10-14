import 'package:colette/features/teeth/domain/entities/tooth_id.dart';

/// Dent de test à partir de son numéro FDI ; échoue si le numéro est inconnu.
ToothId tooth(int number) => ToothId.tryParse(number)!;
