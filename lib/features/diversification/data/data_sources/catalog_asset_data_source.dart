import 'dart:convert';

import 'package:flutter/services.dart';

/// Lit le JSON du catalogue embarqué.
class CatalogAssetDataSource {
  const CatalogAssetDataSource(this._bundle);

  /// Chemin déclaré dans `pubspec.yaml`.
  static const path = 'assets/diversification/catalogue.json';

  final AssetBundle _bundle;

  Future<Map<String, dynamic>> load() async =>
      jsonDecode(await _bundle.loadString(path, cache: false))
          as Map<String, dynamic>;
}
