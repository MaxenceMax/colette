import 'package:colette/core/theme/app_colors.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:colette/shared/domain/care_type.dart';
import 'package:flutter/material.dart';

/// Rendu d'un [CareType] : icône, libellé, couleur.
extension CareTypeUi on CareType {
  IconData get icon => switch (this) {
    CareType.pee => Icons.water_drop_outlined,
    CareType.poop => Icons.cloud_outlined,
    CareType.diaperChange => Icons.baby_changing_station,
    CareType.adrigyl => Icons.medication_liquid_outlined,
    CareType.bath => Icons.bathtub_outlined,
    CareType.eyeCare => Icons.visibility_outlined,
    CareType.noseCare => Icons.air,
    CareType.umbilicalCare => Icons.healing_outlined,
  };

  String label(S s) => switch (this) {
    CareType.pee => s.carePee,
    CareType.poop => s.carePoop,
    CareType.diaperChange => s.careDiaperChange,
    CareType.adrigyl => s.careAdrigyl,
    CareType.bath => s.careBath,
    CareType.eyeCare => s.careEyeCare,
    CareType.noseCare => s.careNoseCare,
    CareType.umbilicalCare => s.careUmbilicalCare,
  };

  AppColors get color => category.color;
}

/// Couleur d'une catégorie de soin.
extension CareCategoryUi on CareCategory {
  AppColors get color => switch (this) {
    CareCategory.feeding => AppColors.categoryFeeding,
    CareCategory.diaper => AppColors.categoryDiaper,
    CareCategory.care => AppColors.categoryCare,
    CareCategory.bath => AppColors.categoryBath,
  };
}
