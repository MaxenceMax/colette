/// Dossier contenant [path] (chemin relatif à la racine) ; `''` à la racine.
String parentPath(String path) {
  final index = path.lastIndexOf('/');
  return index < 0 ? '' : path.substring(0, index);
}
