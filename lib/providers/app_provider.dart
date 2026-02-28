/// AppProvider - Global State Management for PlantDoctor
/// 
/// This provider manages the global application state including:
/// - Model loading status
/// - Current prediction results
/// - Error states
/// 
/// Uses ChangeNotifier to notify listeners when state changes.

import 'package:flutter/foundation.dart';

/// Represents the result of a plant disease prediction
class PredictionResult {
  final String diseaseName;      // Name of the detected disease
  final double confidence;        // Confidence score (0.0 - 1.0)
  final String description;       // Description of the disease
  final String imagePath;         // Path to the analyzed image

  const PredictionResult({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.imagePath,
  });
  
  /// Format confidence as percentage string
  String get confidencePercentage => '${(confidence * 100).toStringAsFixed(1)}%';
}

/// AppProvider manages global app state using ChangeNotifier pattern.
/// 
/// Usage:
/// ```dart
/// // Read state
/// final isModelLoaded = context.watch<AppProvider>().isModelLoaded;
/// 
/// // Update state
/// context.read<AppProvider>().setModelLoaded(true);
/// ```
class AppProvider extends ChangeNotifier {
  // ============================================
  // MODEL LOADING STATE
  // ============================================
  
  /// Whether the TFLite model has been successfully loaded
  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;
  
  /// Set model loaded status and notify listeners
  void setModelLoaded(bool value) {
    _isModelLoaded = value;
    notifyListeners();
  }
  
  // ============================================
  // LOADING STATE
  // ============================================
  
  /// Whether the app is currently processing (loading model, running inference, etc.)
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  /// Set loading status and notify listeners
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // ============================================
  // PREDICTION RESULT STATE
  // ============================================
  
  /// The most recent prediction result (null if no prediction yet)
  PredictionResult? _lastPrediction;
  PredictionResult? get lastPrediction => _lastPrediction;
  
  /// Set the prediction result and notify listeners
  void setPrediction(PredictionResult? result) {
    _lastPrediction = result;
    notifyListeners();
  }
  
  /// Clear the last prediction
  void clearPrediction() {
    _lastPrediction = null;
    notifyListeners();
  }
  
  // ============================================
  // ERROR STATE
  // ============================================
  
  /// Current error message (null if no error)
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  /// Whether there's currently an error
  bool get hasError => _errorMessage != null;
  
  /// Set error message and notify listeners
  void setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Clear the current error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // ============================================
  // CAPTURED IMAGE STATE
  // ============================================
  
  /// Path to the currently captured image
  String? _capturedImagePath;
  String? get capturedImagePath => _capturedImagePath;
  
  /// Set the captured image path
  void setCapturedImagePath(String? path) {
    _capturedImagePath = path;
    notifyListeners();
  }
  
  // ============================================
  // UTILITY METHODS
  // ============================================
  
  /// Reset all state to initial values
  void resetState() {
    _isLoading = false;
    _lastPrediction = null;
    _errorMessage = null;
    _capturedImagePath = null;
    notifyListeners();
  }
}
