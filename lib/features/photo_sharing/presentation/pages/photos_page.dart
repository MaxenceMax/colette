import 'package:colette/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Listes de diffusion de cet iPhone ; un appui envoie des photos à une liste.
class PhotosPage extends StatelessWidget {
  const PhotosPage({super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text(S.of(context).photosPageTitle)));
}
