import 'package:colette/features/events/domain/entities/timeline_filter.dart';
import 'package:colette/features/events/presentation/providers/events_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_filter_controller.g.dart';

/// Filtre actif du Journal ; « Tout » par défaut, gardé en mémoire.
@riverpod
class TimelineFilterController extends _$TimelineFilterController {
  @override
  TimelineFilter build() => const AllEntriesFilter();

  /// Active [filter] et repart d'une seule page.
  void select(TimelineFilter filter) {
    if (filter == state) return;
    state = filter;
    ref.read(timelineLimitProvider.notifier).reset();
  }
}
