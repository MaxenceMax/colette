/// Dentition : dents de lait ou dents définitives.
enum Dentition { primary, permanent }

/// Arcade dentaire.
enum ToothArch { upper, lower }

/// Côté de l'enfant (et non de l'écran).
enum ToothSide { right, left }

/// Type de dent, du milieu vers le fond ; l'index suit la position des dents définitives.
enum ToothKind {
  centralIncisor,
  lateralIncisor,
  canine,
  firstPremolar,
  secondPremolar,
  firstMolar,
  secondMolar,
  thirdMolar,
}

/// Numéro international (FDI) d'une dent : quadrant puis position depuis le milieu.
///
/// Quadrants 1 à 4 (définitives) et 5 à 8 (lait) : haut droite, haut gauche,
/// bas gauche, bas droite, du point de vue de l'enfant.
extension type const ToothId._(int value) {
  /// `null` si [value] ne désigne aucune dent de lait ou définitive.
  static ToothId? tryParse(int value) {
    final quadrant = value ~/ 10;
    final position = value % 10;
    final count = switch (quadrant) {
      1 || 2 || 3 || 4 => _permanentPerQuadrant,
      5 || 6 || 7 || 8 => _primaryPerQuadrant,
      _ => 0,
    };
    return position >= 1 && position <= count ? ToothId._(value) : null;
  }

  static const _primaryPerQuadrant = 5;
  static const _permanentPerQuadrant = 8;

  /// Pas de prémolaire dans la denture de lait : les molaires suivent la canine.
  static const _primaryKinds = [
    ToothKind.centralIncisor,
    ToothKind.lateralIncisor,
    ToothKind.canine,
    ToothKind.firstMolar,
    ToothKind.secondMolar,
  ];

  /// Les 20 dents de lait dans l'ordre du schéma.
  static final List<ToothId> primaryAll = _chartOrder(
    firstQuadrant: 5,
    perQuadrant: _primaryPerQuadrant,
  );

  /// Les 32 dents définitives dans l'ordre du schéma.
  static final List<ToothId> permanentAll = _chartOrder(
    firstQuadrant: 1,
    perQuadrant: _permanentPerQuadrant,
  );

  /// Dents de [dentition] dans l'ordre du schéma.
  static List<ToothId> all(Dentition dentition) => switch (dentition) {
    Dentition.primary => primaryAll,
    Dentition.permanent => permanentAll,
  };

  /// Vu de face, de gauche à droite de l'écran : arcade du haut puis du bas.
  /// La droite de l'enfant est à gauche de l'écran.
  static List<ToothId> _chartOrder({
    required int firstQuadrant,
    required int perQuadrant,
  }) {
    final upperRight = firstQuadrant;
    final upperLeft = firstQuadrant + 1;
    final lowerLeft = firstQuadrant + 2;
    final lowerRight = firstQuadrant + 3;
    return [
      for (var p = perQuadrant; p >= 1; p--) ToothId._(upperRight * 10 + p),
      for (var p = 1; p <= perQuadrant; p++) ToothId._(upperLeft * 10 + p),
      for (var p = perQuadrant; p >= 1; p--) ToothId._(lowerRight * 10 + p),
      for (var p = 1; p <= perQuadrant; p++) ToothId._(lowerLeft * 10 + p),
    ];
  }

  int get _quadrant => value ~/ 10;

  /// Position depuis le milieu : 1 (incisive centrale) à 5 ou 8.
  int get position => value % 10;

  Dentition get dentition =>
      _quadrant >= 5 ? Dentition.primary : Dentition.permanent;

  ToothArch get arch => switch (_quadrant) {
    1 || 2 || 5 || 6 => ToothArch.upper,
    _ => ToothArch.lower,
  };

  ToothSide get side => switch (_quadrant) {
    1 || 4 || 5 || 8 => ToothSide.right,
    _ => ToothSide.left,
  };

  ToothKind get kind => switch (dentition) {
    Dentition.primary => _primaryKinds[position - 1],
    Dentition.permanent => ToothKind.values[position - 1],
  };
}
