import 'package:colette/features/documents/domain/use_cases/build_scan_file_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('« Scan jj-MM-aaaa HHhmm.pdf »', () {
    expect(
      buildScanFileName(DateTime(2026, 9, 22, 14, 32)),
      'Scan 22-09-2026 14h32.pdf',
    );
  });

  test('zéros de tête', () {
    expect(
      buildScanFileName(DateTime(2026, 1, 5, 8, 7)),
      'Scan 05-01-2026 08h07.pdf',
    );
  });
}
