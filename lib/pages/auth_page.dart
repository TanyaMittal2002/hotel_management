// lib/pages/auth_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/api_provider.dart';
import 'home_page.dart';

final googleSignInProvider = Provider((ref) => GoogleSignIn(scopes: ['email', 'profile']));

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _initializing = false; // no registration here; main did it

  void _goToHome() {
    final api = ref.read(apiServiceProvider);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage(api: api)));
  }

  Future<void> _handleSignIn() async {
    final google = ref.read(googleSignInProvider);
    try {
      final user = await google.signIn();
      if (user != null) _goToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final google = ref.read(googleSignInProvider);

    return StreamBuilder<GoogleSignInAccount?>(
      stream: google.onCurrentUserChanged,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Google Sign In')),
          body: Center(
            child: user == null
                ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FlutterLogo(size: 96),
                const SizedBox(height: 24),
                ElevatedButton.icon(icon: const Icon(Icons.login), label: const Text('Sign in with Google'), onPressed: _handleSignIn),
                const SizedBox(height: 12),
                TextButton(child: const Text('Continue as Guest'), onPressed: _goToHome),
              ],
            )
                : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.photoUrl != null) CircleAvatar(radius: 40, backgroundImage: NetworkImage(user.photoUrl!)),
                const SizedBox(height: 12),
                Text('Hello, ${user.displayName ?? user.email}'),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _goToHome, child: const Text('Continue')),
              ],
            ),
          ),
        );
      },
    );
  }
}