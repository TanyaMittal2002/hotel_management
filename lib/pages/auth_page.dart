import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/api_provider.dart';
import 'home_page.dart';

final googleSignInProvider = Provider(
      (ref) => GoogleSignIn(scopes: ['email', 'profile']),
);

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _initializing = false;

  void _goToHome() {
    final api = ref.read(apiServiceProvider);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(api: api)),
    );
  }

  Future<void> _handleSignIn() async {
    final google = ref.read(googleSignInProvider);
    try {
      setState(() => _initializing = true);
      final user = await google.signIn();
      if (user != null) _goToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $e')),
      );
    } finally {
      setState(() => _initializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final google = ref.read(googleSignInProvider);

    return StreamBuilder<GoogleSignInAccount?>(
      stream: google.onCurrentUserChanged,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFFCE93D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: _initializing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : user == null
                    ? _buildSignInCard()
                    : _buildWelcomeCard(user),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInCard() {
    return Container(
      key: const ValueKey('signIn'),
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlutterLogo(size: 80),
          const SizedBox(height: 20),
          const Text(
            "Welcome to Flutter Auth",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildGoogleButton(),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _goToHome,
            child: const Text(
              'Continue as Guest',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(GoogleSignInAccount user) {
    return Container(
      key: const ValueKey('welcome'),
      width: 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user.photoUrl != null)
            CircleAvatar(radius: 40, backgroundImage: NetworkImage(user.photoUrl!)),
          const SizedBox(height: 12),
          Text(
            'Hello, ${user.displayName ?? user.email}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _goToHome,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return ElevatedButton.icon(
      onPressed: _handleSignIn,
      icon: Image.asset('assets/images/google-logo.png', height: 24),
      label: const Text(
        'Sign in with Google',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        elevation: 3,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
