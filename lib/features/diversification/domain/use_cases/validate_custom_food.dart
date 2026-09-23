import 'package:colette/core/result/failure.dart';
import 'package:colette/features/diversification/domain/use_cases/food_name.dart';

/// Contrôle le nom d'un aliment perso ; `null` s'il est valide.
class ValidateCustomFood {
  const ValidateCustomFood();

  static const maxNameLength = 40;

  ValidationReason? call({
    required String name,
    required Iterable<String> existingNames,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return ValidationReason.emptyName;
    if (trimmed.length > maxNameLength) return ValidationReason.foodNameTooLong;
    final normalized = normalizeFoodName(trimmed);
    final duplicate = existingNames.any(
      (existing) => normalizeFoodName(existing) == normalized,
    );
    return duplicate ? ValidationReason.duplicateFoodName : null;
  }
}
