import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return false;
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (kIsWeb) return true;

    try {
      final bool canAuthenticate = await isBiometricsAvailable();
      if (!canAuthenticate) return true;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your notes',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }
}
