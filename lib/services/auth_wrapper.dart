import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:knafayim_app/presentation/screens/auth/login_screen.dart';
import 'package:knafayim_app/presentation/screens/home/client_home_screen.dart';
import 'package:knafayim_app/presentation/screens/home/mentor_home_screen.dart';
import 'package:knafayim_app/presentation/screens/home/staff_home_screen.dart';
import '../../../data/models/user.dart';
import '../../../services/custom_auth_service.dart';
import '../../../config/service_locator.dart';
import '../../../config/themes.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final CustomAuthService _authService = serviceLocator<CustomAuthService>();
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final user = await _authService.checkPersistedAuth();
      if (mounted) {
        setState(() {
          _isAuthenticated = user != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_isAuthenticated) {
      return widget.child;
    } else {
      // Redirect to login screen
      return MaterialApp(
        title: 'Knafayim Association',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('he', 'IL'), // Hebrew
          Locale('en', 'US'), // English
        ],
        locale: const Locale('he', 'IL'), // Default to Hebrew
        home: StreamBuilder<User?>(
          // ✅ FIX: Use Firebase Auth directly and map to your User model
          stream: auth.FirebaseAuth.instance.authStateChanges().asyncMap((
            firebaseUser,
          ) async {
            if (firebaseUser == null) {
              return null;
            }

            try {
              // Get user from Firestore
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(firebaseUser.uid)
                  .get();

              if (!userDoc.exists || userDoc.data() == null) {
                return null;
              }

              return User.fromMap({...userDoc.data()!, 'id': userDoc.id});
            } catch (e) {
              print('Error getting user: $e');
              return null;
            }
          }),
          builder: (context, snapshot) {
            // ✅ Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ✅ Handle error state
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('שגיאה: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ✅ Handle user state
            final user = snapshot.data;
            if (user == null) {
              return const LoginScreen();
            }

            return _navigateToHomeScreen(user);
          },
        ),
      );
    }
  }

  Widget _navigateToHomeScreen(User user) {
    try {
      switch (user.role) {
        case UserRole.client:
          return ClientHomeScreen(user: user);
        case UserRole.mentor:
          return MentorHomeScreen(user: user);
        case UserRole.staff:
          return StaffHomeScreen(user: user);
        default:
          return const LoginScreen();
      }
    } catch (e) {
      print('Error navigating to home screen: $e');
      return const LoginScreen();
    }
  }
}
