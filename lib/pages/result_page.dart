/// ResultPage - Displays plant disease detection results
///
/// This page shows:
/// - The captured leaf image
/// - Detected disease name
/// - Confidence percentage
/// - Disease description and information
/// - Option to scan again

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/disease_info_loader.dart';
import '../providers/app_provider.dart';
import '../services/model_service.dart';

class ResultPage extends StatefulWidget {
  /// Path to the captured image file
  final String imagePath;

  const ResultPage({super.key, required this.imagePath});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  // Whether analysis is in progress
  bool _isAnalyzing = true;

  // Error message (if any)
  String? _errorMessage;

  // Result data from ML inference
  String _diseaseName = '';
  String _plantName = '';
  double _confidence = 0.0;
  String _description = '';
  String _treatment = '';
  String _guidance = '';
  String _irrigation = '';
  String _fertilization = '';
  String _diseaseLabel = '';
  bool _isHealthy = false;

  @override
  void initState() {
    super.initState();
    // Start the analysis when the page loads
    _analyzeImage();
  }

  /// Analyze the captured image using ML model
  Future<void> _analyzeImage() async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final modelService = ModelService();
      final diseaseInfoLoader = DiseaseInfoLoader();

      // Ensure model is loaded
      if (!modelService.isModelLoaded) {
        await modelService.loadModel();
      }

      // Ensure disease info is loaded
      if (!diseaseInfoLoader.isLoaded) {
        await diseaseInfoLoader.loadDiseaseInfo();
      }

      // Run inference on the image
      final imageFile = File(widget.imagePath);
      final prediction = await modelService.predict(imageFile);

      // Get disease info from the loaded JSON
      final diseaseInfo = diseaseInfoLoader.getDiseaseByLabel(prediction.label);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _isHealthy = prediction.isHealthy;
          _confidence = prediction.confidence;

          if (diseaseInfo != null) {
            // Use data from disease_info.json
            _diseaseName = diseaseInfo.disease;
            _plantName = diseaseInfo.plant;
            _description = diseaseInfo.description;
            _treatment = diseaseInfo.treatment;
            _guidance = diseaseInfo.guidance;
            _irrigation = diseaseInfo.irrigation;
            _fertilization = diseaseInfo.fertilization;
            _diseaseLabel = diseaseInfo.label;
          } else {
            // Fallback if disease info not found
            _diseaseName = _formatLabel(prediction.label);
            _plantName = _extractPlantName(prediction.label);
            _description =
                'No detailed description available for this condition.';
            _treatment =
                'Please consult a local agricultural expert for treatment advice.';
            _guidance = '';
            _irrigation = '';
            _fertilization = '';
            _diseaseLabel = prediction.label;
          }
        });

        // Update provider with prediction result
        context.read<AppProvider>().setPrediction(
          PredictionResult(
            diseaseName: _diseaseName,
            confidence: _confidence,
            description: _description,
            imagePath: widget.imagePath,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = 'Failed to analyze image: $e';
          _diseaseName = 'Analysis Error';
          _description = 'Unable to process the image. Please try again.';
        });
      }
    }
  }

  /// Format a label string into a human-readable name
  /// e.g., "Tomato___Early_blight" -> "Early Blight"
  String _formatLabel(String label) {
    final parts = label.split('___');
    if (parts.length > 1) {
      return parts[1].replaceAll('_', ' ').trim();
    }
    return label.replaceAll('_', ' ').trim();
  }

  /// Extract plant name from label
  /// e.g., "Tomato___Early_blight" -> "Tomato"
  String _extractPlantName(String label) {
    final parts = label.split('___');
    if (parts.isNotEmpty) {
      return parts[0].replaceAll('_', ' ').replaceAll('(', ' (').trim();
    }
    return 'Unknown Plant';
  }

  /// Navigate back to scan again
  void _scanAgain() {
    // Pop back to the camera page (or home if camera was dismissed)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),

      body: _isAnalyzing
          ? _buildLoadingState(context, colorScheme)
          : _buildResultState(context, theme, colorScheme),

      // Scan again button at the bottom
      bottomNavigationBar: _isAnalyzing
          ? null
          : _buildBottomButton(context, colorScheme),
    );
  }

  /// Build the loading state while analyzing
  Widget _buildLoadingState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(height: 32),

          // Analyzing text
          Text(
            'Analyzing leaf...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            'Our AI is examining the image',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 48),

          // Loading steps indicator
          _buildLoadingSteps(context, colorScheme),
        ],
      ),
    );
  }

  /// Build the loading steps indicator
  Widget _buildLoadingSteps(BuildContext context, ColorScheme colorScheme) {
    final steps = [
      'Processing image...',
      'Running AI model...',
      'Identifying disease...',
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary.withAlpha(128),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                entry.value,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Build the result state after analysis completes
  Widget _buildResultState(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Use the _isHealthy flag from inference
    final resultColor = _isHealthy ? Colors.green : Colors.orange;

    // Handle error state
    if (_errorMessage != null) {
      return _buildErrorState(context, colorScheme);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image preview
          _buildImagePreview(context),

          // Result card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Disease name card
                Card(
                  color: resultColor.withAlpha(26),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Status icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: resultColor.withAlpha(51),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isHealthy ? Icons.check_circle : Icons.warning,
                            size: 40,
                            color: resultColor,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Plant name
                        // if (_plantName.isNotEmpty)
                        //   Padding(
                        //     padding: const EdgeInsets.only(bottom: 4),
                        //     child: Text(
                        //       _plantName,
                        //       style: theme.textTheme.titleMedium?.copyWith(
                        //         color: colorScheme.onSurfaceVariant,
                        //       ),
                        //       textAlign: TextAlign.center,
                        //     ),
                        //   ),

                        // Disease name
                        Text(
                          _diseaseName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: resultColor.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Confidence badge
                        // Container(
                        //   padding: const EdgeInsets.symmetric(
                        //     horizontal: 16,
                        //     vertical: 8,
                        //   ),
                        //   decoration: BoxDecoration(
                        //     color: colorScheme.primaryContainer,
                        //     borderRadius: BorderRadius.circular(20),
                        //   ),
                        //   child: Text(
                        //     'Confidence: ${(_confidence * 100).toStringAsFixed(1)}%',
                        //     style: TextStyle(
                        //       color: colorScheme.onPrimaryContainer,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'About this condition',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          _description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Treatment card (only show if not healthy and treatment available)
                if (!_isHealthy && _treatment.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildTreatmentCard(context, theme, colorScheme),
                ],

                // Guidance card
                if (_guidance.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    theme,
                    colorScheme,
                    title: 'Guidance',
                    content: _guidance,
                    icon: Icons.tips_and_updates_outlined,
                    color: Colors.blue,
                  ),
                ],

                // Irrigation card
                if (_irrigation.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    theme,
                    colorScheme,
                    title: 'Irrigation',
                    content: _irrigation,
                    icon: Icons.water_drop_outlined,
                    color: Colors.cyan,
                  ),
                ],

                // Fertilization card
                if (_fertilization.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    theme,
                    colorScheme,
                    title: 'Fertilization',
                    content: _fertilization,
                    icon: Icons.grass_outlined,
                    color: Colors.brown,
                  ),
                ],

                // Learn more link
                if (!_isHealthy && _diseaseLabel.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildLearnMoreCard(context, theme, colorScheme),
                ],

                const SizedBox(height: 16),

                // Confidence bar
                // _buildConfidenceBar(context, colorScheme),
                const SizedBox(height: 16),

                // Retry analysis button
                OutlinedButton.icon(
                  onPressed: _analyzeImage,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-analyze Image'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build error state when analysis fails
  Widget _buildErrorState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Analysis Failed',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _analyzeImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build treatment recommendations card
  Widget _buildTreatmentCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      color: Colors.green.withAlpha(26),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Treatment Recommendations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              _treatment,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a generic info card for guidance, irrigation, fertilization
  Widget _buildInfoCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: color.withAlpha(26),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Build disease images gallery card
  Widget _buildLearnMoreCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Create search query from disease label
    final searchQuery = Uri.encodeComponent(
      '$_plantName $_diseaseName plant disease',
    );
    final googleUrl = 'https://www.google.com/search?q=$searchQuery';
    final plantVillageUrl = 'https://plantvillage.psu.edu/topics';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Learn More',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Find more information about this disease:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(googleUrl),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search Google'),
                  ),
                ),
                // const SizedBox(width: 8),
                // Expanded(
                //   child: OutlinedButton.icon(
                //     onPressed: () => _launchUrl(plantVillageUrl),
                //     icon: const Icon(Icons.eco, size: 18),
                //     label: const Text('PlantVillage'),
                //   ),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Build the image preview section
  Widget _buildImagePreview(BuildContext context) {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.black,
      child: widget.imagePath.startsWith('/mock')
          // Show placeholder for mock image
          ? Container(
              color: Colors.grey[800],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 64, color: Colors.white38),
                    SizedBox(height: 8),
                    Text(
                      'Captured Image\n(Placeholder)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
              ),
            )
          // Show actual image
          : Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// Build the confidence bar visualization
  Widget _buildConfidenceBar(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confidence Level',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _confidence,
                minHeight: 12,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _confidence > 0.8
                      ? Colors.green
                      : _confidence > 0.5
                      ? Colors.orange
                      : Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Confidence interpretation
            Text(
              _getConfidenceInterpretation(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get confidence interpretation text
  String _getConfidenceInterpretation() {
    if (_confidence > 0.9) {
      return 'High confidence - The model is very certain about this diagnosis.';
    } else if (_confidence > 0.7) {
      return 'Good confidence - The diagnosis is likely accurate.';
    } else if (_confidence > 0.5) {
      return 'Moderate confidence - Consider taking another photo for verification.';
    } else {
      return 'Low confidence - Please retake the photo with better lighting.';
    }
  }

  /// Build the bottom scan again button
  Widget _buildBottomButton(BuildContext context, ColorScheme colorScheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _scanAgain,
          icon: const Icon(Icons.document_scanner),
          label: const Text('Scan Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ),
    );
  }
}

// Extension to get shade colors for MaterialColor
extension ColorShade on Color {
  Color get shade700 {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
  }
}
