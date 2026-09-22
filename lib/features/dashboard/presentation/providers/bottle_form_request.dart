import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bottle_form_request.g.dart';

/// Demande d'ouverture du formulaire biberon sur Aujourd'hui (arrivée par notification).
@Riverpod(keepAlive: true)
class BottleFormRequest extends _$BottleFormRequest {
  @override
  bool build() => false;

  void request() => state = true;

  void consume() => state = false;
}
