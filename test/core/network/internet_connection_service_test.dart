import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/network/internet_connection_service.dart';

void main() {
  group('InternetConnectionService', () {
    test(
      'hasInternetConnection returns true when check succeeds with true',
      () async {
        final service = InternetConnectionService(
          internetCheck: () async => true,
        );

        final hasConnection = await service.hasInternetConnection;

        expect(hasConnection, isTrue);
      },
    );

    test(
      'hasInternetConnection returns false when check succeeds with false',
      () async {
        final service = InternetConnectionService(
          internetCheck: () async => false,
        );

        final hasConnection = await service.hasInternetConnection;

        expect(hasConnection, isFalse);
      },
    );

    test(
      'hasInternetConnection returns false when check throws an exception',
      () async {
        final service = InternetConnectionService(
          internetCheck: () async {
            throw Exception('Connection check failed');
          },
        );

        final hasConnection = await service.hasInternetConnection;

        expect(hasConnection, isFalse);
      },
    );

    test(
      'hasInternetConnection calls internetCheck function once per request',
      () async {
        var callCount = 0;
        final service = InternetConnectionService(
          internetCheck: () async {
            callCount++;
            return true;
          },
        );

        await service.hasInternetConnection;

        expect(callCount, 1);
      },
    );
  });
}
