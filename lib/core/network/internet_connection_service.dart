import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

typedef InternetCheck = Future<bool> Function();

class InternetConnectionService {
  // Allow injecting an internet check function to isolate tests from real network calls.
  InternetConnectionService({InternetCheck? internetCheck})
    : _internetCheck =
          internetCheck ?? (() => InternetConnection().hasInternetAccess);

  final InternetCheck _internetCheck;

  Future<bool> get hasInternetConnection async {
    try {
      return await _internetCheck();
    } catch (_) {
      return false;
    }
  }
}
