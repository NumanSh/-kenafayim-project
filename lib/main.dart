import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:knafayim_app/services/enhanced_notification_service.dart';
import 'package:knafayim_app/services/notification_integration_service.dart';
import 'package:knafayim_app/services/report_scheduler_service.dart';
// ✅ ADD NOTIFICATION SCREEN IMPORTS
import 'package:knafayim_app/presentation/screens/notifications/notification_center_screen.dart';
import 'package:knafayim_app/presentation/screens/notifications/notification_settings_screen.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'services/firebase_options.dart';
import 'config/themes.dart';
import 'config/service_locator.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'services/auth_wrapper.dart';
import 'presentation/widgets/common/rtl_wrapper.dart';

class KnafayimApp extends StatelessWidget {
  const KnafayimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RTLTextDirectionWrapper(
      child: ProviderScope(
        child: AuthWrapper(
          child: MaterialApp(
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
            home: const LoginScreen(),
            // ✅ ADD NOTIFICATION ROUTES
            routes: {
              '/notifications': (context) => const NotificationCenterScreen(),
              '/notification-settings': (context) =>
                  const NotificationSettingsScreen(),
            },
          ),
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase with explicit options
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // ✅ Initialize timezone for scheduled notifications
      tz.initializeTimeZones();

      // ✅ Setup service locator after Firebase is initialized
      setupServiceLocator();

      // ✅ Initialize notification services

      // ✅ Initialize scheduler after services are registered
      final schedulerService = serviceLocator<ReportSchedulerService>();
      schedulerService.initialize();

      // Add a small delay to ensure everything is properly initialized
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('he', 'IL'), Locale('en', 'US')],
        locale: const Locale('he', 'IL'),
        home: _buildErrorScreen(),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('he', 'IL'), Locale('en', 'US')],
        locale: const Locale('he', 'IL'),
        home: _buildLoadingScreen(),
      );
    }

    return const KnafayimApp();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;
            final isSmallScreen = availableHeight < 600;
            final isTablet = availableWidth > 600;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48 : 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: availableHeight * 0.1),

                      // Logo container - responsive
                      Container(
                        width: isTablet ? 100 : 80,
                        height: isTablet ? 100 : 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: isTablet ? 50 : 40,
                          color: const Color(0xFF3b82f6),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Title - responsive
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: availableWidth * 0.9,
                        ),
                        child: Text(
                          'מכין את האפליקציה...',
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? 16
                                : isTablet
                                ? 22
                                : 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1f2937),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 4 : 8),

                      // Subtitle - responsive
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: availableWidth * 0.8,
                        ),
                        child: Text(
                          'אנא המתן רגע',
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? 12
                                : isTablet
                                ? 16
                                : 14,
                            color: const Color(0xFF6b7280),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Loading indicator - responsive
                      SizedBox(
                        width: isSmallScreen ? 28 : 32,
                        height: isSmallScreen ? 28 : 32,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF3b82f6),
                          ),
                        ),
                      ),

                      SizedBox(height: availableHeight * 0.1),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFf8fafc),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final availableWidth = constraints.maxWidth;
            final isSmallScreen = availableHeight < 600;
            final isTablet = availableWidth > 600;

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: availableHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 48 : 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top spacer
                      SizedBox(height: availableHeight * 0.05),

                      // Error icon
                      Container(
                        width: isTablet ? 100 : 80,
                        height: isTablet ? 100 : 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: isTablet ? 50 : 40,
                          color: Colors.red,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Error title
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: availableWidth * 0.9,
                        ),
                        child: Text(
                          'שגיאה באתחול האפליקציה',
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? 16
                                : isTablet
                                ? 22
                                : 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 16),

                      // Error message
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: availableWidth * 0.85,
                        ),
                        child: Text(
                          _errorMessage ?? 'אירעה שגיאה בלתי צפויה',
                          style: TextStyle(
                            fontSize: isSmallScreen
                                ? 12
                                : isTablet
                                ? 16
                                : 14,
                            color: const Color(0xFF6b7280),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Retry button
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 280 : 220,
                        ),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                              _isInitialized = false;
                            });
                            _initializeApp();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3b82f6),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 12 : 16,
                              horizontal: 24,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.refresh,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'נסה שוב',
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 14
                                      : isTablet
                                      ? 18
                                      : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // Help text
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: availableWidth * 0.8,
                        ),
                        child: Text(
                          'בדוק את החיבור לאינטרנט ונסה שוב',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: const Color(0xFF9ca3af),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Bottom spacer
                      SizedBox(height: availableHeight * 0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ADD: Optimize keyboard performance
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );

  // ✅ ADD: Disable unnecessary animations
  if (Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ),
    );
  }

  // Your existing initialization...
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // setupServiceLocator();
  // await NotificationService().initialize();

  runApp(const ProviderScope(child: AppInitializer()));
}
