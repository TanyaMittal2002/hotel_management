// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api_service.dart';
import 'providers/api_provider.dart';
import 'pages/auth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Create and initialize ApiService BEFORE runApp
  final api = ApiService();
  await api.init();              // prepare SharedPreferences
  try {
    await api.ensureVisitorToken(); // registers device if needed and saves visitortoken
  } catch (e, st) {
    debugPrint('Device registration at startup failed: $e\n$st');
    // we continue; later API calls will show meaningful errors if no token
  }

  runApp(
    ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(api),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MyTravaly Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthPage(),
    );
  }
}
