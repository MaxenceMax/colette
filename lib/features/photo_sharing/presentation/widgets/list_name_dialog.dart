import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Demande le nom d'une liste ; `null` si l'utilisateur annule.
Future<String?> showListNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialName = '',
}) => showDialog<String>(
  context: context,
  builder: (_) => _ListNameDialog(
    title: title,
    confirmLabel: confirmLabel,
    initialName: initialName,
  ),
);

/// Champ de nom : le bouton reste inactif tant que le nom est vide.
class _ListNameDialog extends StatefulWidget {
  const _ListNameDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialName,
  });

  final String title;
  final String confirmLabel;
  final String initialName;

  @override
  State<_ListNameDialog> createState() => _ListNameDialogState();
}

class _ListNameDialogState extends State<_ListNameDialog> {
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: .sentences,
        textInputAction: .done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(labelText: s.photosListNameLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.actionCancel),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => TextButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}
