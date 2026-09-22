import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_root.freezed.dart';

/// Dossier racine choisi par l'utilisateur dans le sélecteur iOS.
@freezed
abstract class DocumentRoot with _$DocumentRoot {
  const factory DocumentRoot({required String name}) = _DocumentRoot;
}
