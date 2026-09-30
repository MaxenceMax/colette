import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_report.freezed.dart';

/// Bilan d'un envoi : une feuille Messages par personne.
@freezed
abstract class SendReport with _$SendReport {
  const SendReport._();

  const factory SendReport({
    required int sent,
    required int cancelled,
    required int failed,
  }) = _SendReport;

  /// Au moins un message est parti.
  bool get anySent => sent > 0;
}
