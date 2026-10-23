import 'package:flutter_test/flutter_test.dart';
import 'package:hollowmere_files/content/browser_pages.dart';

void main() {
  const discovered = {'release_log_pdf'};

  test('release log extract matches the URL Ardis sends in ep4', () {
    final pages = searchPages('hollowmere-authority.gov/log/extract', discovered);
    expect(pages.map((p) => p.id), contains('release_log_pdf'));
  });

  test('release log matches https prefix and pasted chat line', () {
    expect(
      searchPages('https://hollowmere-authority.gov/log/extract', discovered)
          .map((p) => p.id),
      contains('release_log_pdf'),
    );
    expect(
      searchPages(
        'hollowmere-authority.gov/log/extract - it should put the siren stories to bed.',
        discovered,
      ).map((p) => p.id),
      contains('release_log_pdf'),
    );
  });

  test('hidden release log does not appear until discovered', () {
    expect(
      searchPages('hollowmere-authority.gov/log/extract', {}).map((p) => p.id),
      isNot(contains('release_log_pdf')),
    );
  });
}
