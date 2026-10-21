import 'package:flutter/material.dart';

import 'app.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/services/local_storage_service.dart';

/// Application entry point.
///
/// Boot sequence:
///  1. Ensure Flutter bindings are ready (needed before any plugin call).
///  2. Initialise the `SharedPreferences`-backed local storage.
///  3. Run the app.
///
/// The backend is chosen at compile time (see `ApiConstants.useMockMode`):
/// the app talks to a Laravel server in `live` mode and to the bundled
/// in-memory catalogue in `mock` mode. Nothing has to be initialised here
/// beyond local storage, so the app starts even when the server is down.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final localStorage = await LocalStorageService.init();
    runApp(FolioApp(localStorage: localStorage));
  } catch (error, stack) {
    debugPrint('Bootstrap failed: $error\n$stack');
    runApp(const _BootstrapErrorApp());
  }
}

/// Minimal app shown only when bootstrapping fails.
class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: AppColors.danger,
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.appFailedToStart,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please restart the app.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
