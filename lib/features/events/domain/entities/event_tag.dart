import 'package:colette/shared/domain/care_type.dart';

/// Critère de filtrage d'un événement de soin : un soin coché ou un biberon.
sealed class EventTag {
  const EventTag();
}

/// Événements où [type] est coché.
final class CareTag extends EventTag {
  const CareTag(this.type);

  final CareType type;

  @override
  bool operator ==(Object other) => other is CareTag && other.type == type;

  @override
  int get hashCode => type.hashCode;
}

/// Événements avec un biberon.
final class BottleTag extends EventTag {
  const BottleTag();
}
