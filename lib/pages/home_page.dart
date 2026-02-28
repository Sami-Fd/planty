/// HomePage - Main screen of PlantDoctor
///
/// This page serves as the main hub of the app where users can:
/// - View instructions on how to use the app
/// - Access the camera to scan plant leaves
/// - Learn about plant disease detection
///
/// Features a FloatingActionButton to launch the camera scanner.

import 'package:flutter/material.dart';

import 'camera_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // App bar with title
      appBar: AppBar(
        title: const Text('PlantDoctor'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          // Info button for app information
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
            tooltip: 'About',
          ),
        ],
      ),

      // Main content
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              _buildWelcomeCard(context),

              const SizedBox(height: 24),

              // Instructions section title
              Text(
                'How to Use',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Instruction cards
              _buildInstructionCard(
                context,
                icon: Icons.camera_alt,
                title: '1. Capture a Leaf',
                description:
                    'Take a clear photo of the plant leaf you want to analyze. Make sure the leaf fills most of the frame.',
              ),

              const SizedBox(height: 12),

              _buildInstructionCard(
                context,
                icon: Icons.psychology,
                title: '2. AI Analysis',
                description:
                    'Our AI model will analyze the image to detect any signs of plant disease.',
              ),

              const SizedBox(height: 12),

              _buildInstructionCard(
                context,
                icon: Icons.article,
                title: '3. Get Results',
                description:
                    'View the diagnosis results including the disease name, confidence level, and helpful information.',
              ),

              const SizedBox(height: 24),

              // Tips section
              Text(
                'Tips for Best Results',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildTipsList(context),

              // Bottom padding for FAB
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // Floating action button to start scanning
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCamera(context),
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scan Leaf'),
        tooltip: 'Scan a plant leaf',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Build the welcome card at the top of the page
  Widget _buildWelcomeCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Plant logo
            ClipOval(
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 16),

            // Welcome text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to PlantDoctor',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Detect plant diseases instantly using AI',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build an instruction card with icon, title, and description
  Widget _buildInstructionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: colorScheme.onSecondaryContainer,
              ),
            ),

            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the tips list
  Widget _buildTipsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tips = [
      'Use good lighting (natural daylight works best)',
      'Focus on the affected area of the leaf',
      'Keep the camera steady while capturing',
      'Avoid shadows and reflections on the leaf',
      'Include both healthy and diseased parts if possible',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: tips
              .map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(tip, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  /// Navigate to the camera page
  void _navigateToCamera(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CameraPage()));
  }

  /// Show the about dialog
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('About PlantDoctor'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PlantDoctor uses artificial intelligence to detect plant diseases from leaf images.',
            ),
            SizedBox(height: 16),
            Text(
              'Version 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• Works 100% offline\n'
              '• Supports 38 plant diseases\n'
              '• Fast AI inference',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
