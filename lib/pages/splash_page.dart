/// SplashPage - Initial loading screen for PlantDoctor
///
/// This page is shown when the app first launches.
/// It displays the app logo and loading indicator while:
/// - Loading the TFLite model
/// - Initializing services
/// - Loading disease information data
///
/// After loading completes, automatically navigates to HomePage.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/disease_info_loader.dart';
import '../providers/app_provider.dart';
import '../services/model_service.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // Animation controller for the pulsing logo effect
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Loading status message
  String _loadingMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();

    // Setup pulsing animation for the logo
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start the initialization process
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Initialize the app by loading the model and data.
  Future<void> _initializeApp() async {
    try {
      final modelService = ModelService();
      final diseaseInfoLoader = DiseaseInfoLoader();

      // Load the TFLite model
      setState(() => _loadingMessage = 'Loading AI model...');
      try {
        await modelService.loadModel();
      } catch (e) {
        // Model loading can fail if .tflite file is not present
        // Continue anyway - will show error when user tries to scan
        debugPrint('Warning: Model loading failed: $e');
      }

      // Load disease information from JSON
      setState(() => _loadingMessage = 'Loading disease data...');
      await diseaseInfoLoader.loadDiseaseInfo();

      // Mark model as loaded in the provider
      if (mounted) {
        context.read<AppProvider>().setModelLoaded(modelService.isModelLoaded);

        // Update loading message
        setState(() => _loadingMessage = 'Ready!');

        // Short delay to show "Ready!" message
        await Future.delayed(const Duration(milliseconds: 300));

        // Navigate to HomePage, replacing the splash screen
        _navigateToHome();
      }
    } catch (e) {
      // Handle initialization errors
      if (mounted) {
        context.read<AppProvider>().setError('Failed to initialize: $e');
        setState(() => _loadingMessage = 'Error: $e');

        // Navigate anyway after showing error briefly
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _navigateToHome();
        }
      }
    }
  }

  /// Navigate to HomePage, replacing the splash screen in the navigation stack
  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Gradient background for visual appeal
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primaryContainer, colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo container
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App name
                Text(
                  'PlantDoctor',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 8),

                // App tagline
                Text(
                  'AI-Powered Plant Disease Detection',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 60),

                // Loading indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 20),

                // Loading status message
                Text(
                  _loadingMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
