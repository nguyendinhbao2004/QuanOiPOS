import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'env/.env.dev');
  } catch (error) {
    debugPrint('Failed to load env/.env.dev: $error');
  }

  await setupDependencies(enableLogging: true);
  runApp(const ProviderScope(child: MyApp()));
}
