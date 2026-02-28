/// PlantDoctor - AI-powered Plant Disease Detection App
///
/// This is the main entry point of the application.
/// The app uses Provider for state management and Material 3 for UI design.
///
/// Architecture:
/// - pages/: Contains all screen widgets (SplashPage, HomePage, CameraPage, ResultPage)
/// - services/: Business logic and ML model handling
/// - data/: Data loading utilities
/// - widgets/: Reusable UI components

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import pages
import 'pages/splash_page.dart';

// Import providers (state management)
import 'providers/app_provider.dart';

void main() {
  // Ensure Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const PlantDoctorApp());
}

/// Root widget of the PlantDoctor application.
///
/// This widget sets up:
/// - Provider for state management across the app
/// - Material 3 theming with a green color scheme (plant-themed)
/// - Initial route to SplashPage
class PlantDoctorApp extends StatelessWidget {
  const PlantDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider allows us to provide multiple state objects to the widget tree
    return MultiProvider(
      providers: [
        // AppProvider manages global app state (model loading status, etc.)
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        // App title shown in task switcher
        title: 'PlantDoctor',

        // Disable the debug banner in release builds
        debugShowCheckedModeBanner: false,

        // Material 3 theme configuration with plant-themed green colors
        theme: ThemeData(
          // Enable Material 3 design
          useMaterial3: true,

          // Green color scheme - perfect for a plant app!
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50), // Green 500
            brightness: Brightness.light,
          ),

          // Card theme for consistent card styling
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          // Elevated button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // FloatingActionButton theme
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            extendedPadding: EdgeInsets.symmetric(horizontal: 24),
          ),

          // AppBar theme
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),

        // Dark theme configuration (optional - for system dark mode)
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.dark,
          ),
        ),

        // Use system theme mode (light/dark based on device settings)
        themeMode: ThemeMode.system,

        // Start the app with SplashPage
        home: const SplashPage(),
      ),
    );
  }
}
