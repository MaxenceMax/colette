import 'package:colette/core/ui/failure_message.dart';
import 'package:colette/features/documents/domain/use_cases/document_names.dart';
import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Demande un nom de fichier ou de dossier ; `null` si l'utilisateur annule.
/// [suffix] (l'extension d'un fichier) est affiché mais non modifiable.
Future<String?> showDocumentNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
  String suffix = '',
}) => showDialog<String>(
  context: context,
  builder: (_) => _DocumentNameDialog(
    title: title,
    confirmLabel: confirmLabel,
    initialName: initialName,
    suffix: suffix,
  ),
);

/// Champ de nom validé à la saisie : le bouton reste inactif tant que le nom
/// est invalide.
class _DocumentNameDialog extends StatefulWidget {
  const _DocumentNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.suffix,
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final String suffix;

  @override
  State<_DocumentNameDialog> createState() => _DocumentNameDialogState();
}

class _DocumentNameDialogState extends State<_DocumentNameDialog> {
  late final _controller = TextEditingController(text: widget.initialName)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialName.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (validateEntryName(_controller.text).isRight()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, _) => TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: .done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: s.documentsNameLabel,
            suffixText: widget.suffix.isEmpty ? null : widget.suffix,
            errorText: value.text.isEmpty
                ? null
                : validateEntryName(
                    value.text,
                  ).match((failure) => failureMessage(failure, s), (_) => null),
            errorMaxLines: 3,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.actionCancel),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => TextButton(
            onPressed: validateEntryName(value.text).isRight() ? _submit : null,
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}
