import 'package:flutter_test/flutter_test.dart';
import 'package:app/services/auth_service.dart';

void main() {
  group('AuthService (Wave 5 - Google SSO & Error Handling)', () {
    tearDown(() {
      AuthService.serverClientIdOverride = null;
    });

    test(
      'activeServerClientId returns default OAuth web client ID when unconfigured',
      () {
        AuthService.serverClientIdOverride = null;
        expect(
          AuthService.activeServerClientId,
          '124622276181-2n4dn9nln4c3p90qof67dsij13bv7vtv.apps.googleusercontent.com',
        );
      },
    );

    test(
      'activeServerClientId supports runtime credential injection via serverClientIdOverride',
      () {
        AuthService.serverClientIdOverride =
            'custom_test_client_id.apps.googleusercontent.com';
        expect(
          AuthService.activeServerClientId,
          'custom_test_client_id.apps.googleusercontent.com',
        );
      },
    );

    test('AuthService singleton maintains consistent instance', () {
      final instance1 = AuthService();
      final instance2 = AuthService();
      expect(identical(instance1, instance2), isTrue);
    });
  });
}
