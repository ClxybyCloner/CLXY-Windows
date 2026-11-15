import 'package:flutter_test/flutter_test.dart';

import 'package:arman_vpn/ui/visible_text.dart';

void main() {
  test('sanitizes upstream names and URLs for UI output', () {
    expect(
      sanitizeVisibleText(
        'Mozilla rejected Firefox Account at https://accounts.firefox.com/x; '
        'Arman VPN failed',
      ),
      'service rejected account at [link]; CLXY failed',
    );
  });

  test('does not alter ordinary app-owned text', () {
    expect(sanitizeVisibleText('CLXY server is ready'), 'CLXY server is ready');
  });

  test('removes upstream names and repository paths without a scheme', () {
    expect(
      sanitizeVisibleText(
        'ArmanVPN and arman-vpn-client at github.com/armanlife/arman-vpn-client',
      ),
      'CLXY and CLXY at [service]',
    );
  });
}
