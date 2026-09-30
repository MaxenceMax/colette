/// Chiffres du numéro, `+` initial conservé : « 06 12-34 » → « 061234 ».
///
/// Les formats national (« 06… ») et international (« +33 6… ») ne sont pas
/// rapprochés : deux écritures du même numéro restent différentes.
String normalizePhone(String phone) {
  final trimmed = phone.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}
