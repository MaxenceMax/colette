/// Chiffres du numéro, `+` initial conservé : « 06 12-34 » → « 061234 ».
String normalizePhone(String phone) {
  final trimmed = phone.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  return trimmed.startsWith('+') ? '+$digits' : digits;
}
