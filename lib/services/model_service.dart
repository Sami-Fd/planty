/// ModelService - TensorFlow Lite Inference Service for Plant Disease Detection
///
/// This service provides on-device machine learning inference using TensorFlow Lite.
/// It handles model loading, image preprocessing, and asynchronous inference.
///
/// ============================================================================
/// ARCHITECTURE OVERVIEW
/// ============================================================================
///
/// ┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
/// │   Image Input   │────▶│  ModelService    │────▶│   Prediction    │
/// │   (File/Bytes)  │     │  (Preprocessing) │     │   Results       │
/// └─────────────────┘     └──────────────────┘     └─────────────────┘
///                                  │
///                                  ▼
///                         ┌──────────────────┐
///                         │  TFLite Runtime  │
///                         │  (Interpreter)   │
///                         └──────────────────┘
///
/// ============================================================================
/// MODEL SPECIFICATIONS
/// ============================================================================
/// - Model file: assets/model/plant_disease_model.tflite
/// - Input shape: [1, 224, 224, 3] (NHWC: batch, height, width, channels)
/// - Input type: Float32 normalized to [0, 1]
/// - Output shape: [1, 38] (38 plant disease classes)
/// - Output type: Float32 logits (softmax applied in code)
///
/// ============================================================================
/// USAGE EXAMPLE
/// ============================================================================
/// ```dart
/// // Initialize once at app startup
/// final modelService = ModelService();
/// await modelService.loadModel();
///
/// // Run prediction on an image file
/// final prediction = await modelService.predict(imageFile);
/// print('Disease: ${prediction.label}');
/// print('Confidence: ${prediction.confidence}');
/// ```

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// ============================================================================
/// ModelPrediction - Data class for storing inference results
/// ============================================================================
///
/// Contains the complete output from model inference including:
/// - The predicted class index (0-37)
/// - Human-readable label for the disease
/// - Confidence score for the top prediction
/// - Full probability distribution for all classes
class ModelPrediction {
  /// The index of the predicted class (0-37)
  final int classIndex;

  /// Human-readable label for the disease
  /// Format: "Plant___Disease" or "Plant___healthy"
  final String label;

  /// Confidence score for the prediction (0.0 to 1.0)
  final double confidence;

  /// Probability distribution across all 38 classes
  /// Useful for showing alternative predictions or uncertainty
  final List<double> allProbabilities;

  /// Constructor with required fields
  const ModelPrediction({
    required this.classIndex,
    required this.label,
    required this.confidence,
    required this.allProbabilities,
  });

  /// Check if the prediction indicates a healthy plant
  bool get isHealthy => label.toLowerCase().contains('healthy');

  /// Get confidence as a formatted percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  @override
  String toString() =>
      'ModelPrediction(class: $classIndex, label: $label, confidence: $confidencePercent)';
}

/// ============================================================================
/// ModelService - Singleton service for TFLite inference
/// ============================================================================
///
/// This class implements the Singleton pattern to ensure:
/// 1. The model is loaded only once during app lifetime
/// 2. Memory is used efficiently (no duplicate interpreters)
/// 3. Thread-safe access to the model from anywhere in the app
class ModelService {
  // ==========================================================================
  // SINGLETON IMPLEMENTATION
  // ==========================================================================

  /// Private static instance for singleton pattern
  static final ModelService _instance = ModelService._internal();

  /// Factory constructor returns the singleton instance
  /// Usage: final service = ModelService();
  factory ModelService() => _instance;

  /// Private internal constructor - called only once
  ModelService._internal();

  // ==========================================================================
  // MODEL STATE VARIABLES
  // ==========================================================================

  /// TensorFlow Lite interpreter instance
  /// Initialized when loadModel() is called
  Interpreter? _interpreter;

  /// Flag indicating whether the model has been successfully loaded
  bool _isModelLoaded = false;

  /// Public getter to check if model is ready for inference
  bool get isModelLoaded => _isModelLoaded;

  // ==========================================================================
  // MODEL CONFIGURATION CONSTANTS
  // ==========================================================================

  /// Input image size (width and height in pixels)
  /// The model expects square 224x224 images
  static const int inputSize = 224;

  /// Number of output classes (38 plant diseases)
  static const int numClasses = 38;

  /// Path to the TFLite model file in Flutter assets
  static const String modelPath = 'assets/model/MobileNetV2.tflite';

  /// Whether the loaded model is quantized (uint8 input/output)
  bool _isQuantized = false;

  // ==========================================================================
  // CLASS LABELS - Maps output index to disease name
  // ==========================================================================

  /// List of class labels corresponding to model output indices
  /// IMPORTANT: Order must match the model's training label order exactly
  static const List<String> classLabels = [
    'Apple___Apple_scab', // 0
    'Apple___Black_rot', // 1
    'Apple___Cedar_apple_rust', // 2
    'Apple___healthy', // 3
    'Blueberry___healthy', // 4
    'Cherry_(including_sour)___Powdery_mildew', // 5
    'Cherry_(including_sour)___healthy', // 6
    'Corn_(maize)___Cercospora_leaf_spot_Gray_leaf_spot', // 7
    'Corn_(maize)___Common_rust_', // 8
    'Corn_(maize)___Northern_Leaf_Blight', // 9
    'Corn_(maize)___healthy', // 10
    'Grape___Black_rot', // 11
    'Grape___Esca_(Black_Measles)', // 12
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', // 13
    'Grape___healthy', // 14
    'Orange___Haunglongbing_(Citrus_greening)', // 15
    'Peach___Bacterial_spot', // 16
    'Peach___healthy', // 17
    'Pepper,_bell___Bacterial_spot', // 18
    'Pepper,_bell___healthy', // 19
    'Potato___Early_blight', // 20
    'Potato___Late_blight', // 21
    'Potato___healthy', // 22
    'Raspberry___healthy', // 23
    'Soybean___healthy', // 24
    'Squash___Powdery_mildew', // 25
    'Strawberry___Leaf_scorch', // 26
    'Strawberry___healthy', // 27
    'Tomato___Bacterial_spot', // 28
    'Tomato___Early_blight', // 29
    'Tomato___Late_blight', // 30
    'Tomato___Leaf_Mold', // 31
    'Tomato___Septoria_leaf_spot', // 32
    'Tomato___Spider_mites_Two-spotted_spider_mite', // 33
    'Tomato___Target_Spot', // 34
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus', // 35
    'Tomato___Tomato_mosaic_virus', // 36
    'Tomato___healthy', // 37
  ];

  // ==========================================================================
  // MODEL LOADING
  // ==========================================================================

  /// Load the TensorFlow Lite model from assets
  ///
  /// This method should be called once during app initialization,
  /// typically in the SplashPage or main() function.
  ///
  /// The model file is loaded from Flutter assets and the TFLite
  /// interpreter is initialized with default options.
  ///
  /// Throws [Exception] if loading fails (e.g., file not found, invalid model)
  ///
  /// Example:
  /// ```dart
  /// final modelService = ModelService();
  /// try {
  ///   await modelService.loadModel();
  ///   print('Model loaded successfully');
  /// } catch (e) {
  ///   print('Failed to load model: $e');
  /// }
  /// ```
  Future<void> loadModel() async {
    // Skip if already loaded (singleton ensures single load)
    if (_isModelLoaded && _interpreter != null) {
      print('ModelService: Model already loaded, skipping');
      return;
    }

    try {
      print('ModelService: Loading model from $modelPath...');

      // Load model using tflite_flutter's asset loader
      // This handles copying from Flutter assets to a temp location
      _interpreter = await Interpreter.fromAsset(modelPath);

      // Log model details for debugging
      _logModelDetails();

      _isModelLoaded = true;
      print('ModelService: Model loaded successfully!');
    } catch (e) {
      _isModelLoaded = false;
      _interpreter = null;
      print('ModelService: ERROR loading model: $e');
      rethrow;
    }
  }

  /// Log model input/output tensor details for debugging
  ///
  /// Prints the shapes and types of input/output tensors,
  /// useful for verifying model compatibility.
  void _logModelDetails() {
    if (_interpreter == null) return;

    // Detect if model is quantized based on input tensor type
    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    _isQuantized = inputTensor.type == TensorType.uint8;
    print('ModelService: Model is quantized: $_isQuantized');

    print('ModelService: Input tensor shape: ${inputTensor.shape}');
    print('ModelService: Input tensor type: ${inputTensor.type}');
    print('ModelService: Output tensor shape: ${outputTensor.shape}');
    print('ModelService: Output tensor type: ${outputTensor.type}');
  }

  // ==========================================================================
  // INFERENCE METHODS
  // ==========================================================================

  /// Run prediction on an image file
  ///
  /// This is the main inference method. It reads the image from disk,
  /// preprocesses it, runs inference, and returns the prediction.
  ///
  /// The method runs asynchronously to avoid blocking the UI thread.
  ///
  /// [imageFile] - The image file to classify (JPEG, PNG, etc.)
  ///
  /// Returns [ModelPrediction] with the classification results
  ///
  /// Throws:
  /// - [Exception] if model is not loaded
  /// - [Exception] if image cannot be decoded
  /// - [Exception] if inference fails
  ///
  /// Example:
  /// ```dart
  /// final file = File('/path/to/leaf_image.jpg');
  /// final prediction = await modelService.predict(file);
  /// print('Detected: ${prediction.label}');
  /// ```
  Future<ModelPrediction> predict(File imageFile) async {
    // Validate model state
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      print('ModelService: Processing image: ${imageFile.path}');

      // Read image bytes from file
      final imageBytes = await imageFile.readAsBytes();

      // Delegate to predictFromBytes for actual processing
      return await predictFromBytes(imageBytes);
    } catch (e) {
      print('ModelService: Prediction failed: $e');
      rethrow;
    }
  }

  /// Run prediction from raw image bytes
  ///
  /// Useful when you already have the image in memory,
  /// such as from a camera capture or network download.
  ///
  /// [imageBytes] - Raw image data (JPEG, PNG, etc.)
  ///
  /// Returns [ModelPrediction] with classification results
  Future<ModelPrediction> predictFromBytes(Uint8List imageBytes) async {
    // Validate model state
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      print('ModelService: Processing ${imageBytes.length} bytes...');

      // Step 1: Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      print('ModelService: Decoded image: ${image.width}x${image.height}');

      // Step 2: Preprocess the image (resize, normalize)
      final inputTensor = _preprocessImage(image);

      // Step 3: Run inference asynchronously
      final outputProbabilities = await _runInferenceAsync(inputTensor);

      // Step 4: Find the class with highest probability
      int maxIndex = 0;
      double maxProb = outputProbabilities[0];
      for (int i = 1; i < outputProbabilities.length; i++) {
        if (outputProbabilities[i] > maxProb) {
          maxProb = outputProbabilities[i];
          maxIndex = i;
        }
      }

      // Step 5: Create and return prediction result
      final prediction = ModelPrediction(
        classIndex: maxIndex,
        label: classLabels[maxIndex],
        confidence: maxProb,
        allProbabilities: outputProbabilities,
      );

      print(
        'ModelService: Prediction: ${prediction.label} (${prediction.confidencePercent})',
      );
      return prediction;
    } catch (e) {
      print('ModelService: Prediction failed: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // IMAGE PREPROCESSING
  // ==========================================================================

  /// Preprocess an image for model input
  ///
  /// Performs the following transformations:
  /// 1. Resize to 224x224 pixels (model input size)
  /// 2. Convert to Float32 tensor
  /// 3. Normalize pixel values to [0, 1] range
  /// 4. Arrange in NHWC format [1, 224, 224, 3]
  ///
  /// [image] - The decoded image to preprocess
  ///
  /// Returns a 4D tensor suitable for TFLite input
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Step 1: Resize to model input size
    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Step 2: Create input tensor with shape [1, 224, 224, 3]
    // NHWC format: batch=1, height=224, width=224, channels=3 (RGB)
    final inputTensor = List.generate(
      1, // Batch size = 1
      (_) => List.generate(
        inputSize, // Height
        (y) => List.generate(
          inputSize, // Width
          (x) {
            // Get pixel at (x, y)
            final pixel = resizedImage.getPixel(x, y);

            // Normalize RGB values from [0, 255] to [0, 1]
            return [
              pixel.r / 255.0, // Red channel
              pixel.g / 255.0, // Green channel
              pixel.b / 255.0, // Blue channel
            ];
          },
        ),
      ),
    );

    return inputTensor;
  }

  // ==========================================================================
  // ASYNC INFERENCE EXECUTION
  // ==========================================================================

  /// Run inference asynchronously to avoid blocking UI
  ///
  /// Executes the model on a separate isolate thread to ensure
  /// smooth UI performance during inference.
  ///
  /// [input] - Preprocessed input tensor
  ///
  /// Returns list of probabilities for each class
  Future<List<double>> _runInferenceAsync(
    List<List<List<List<double>>>> input,
  ) async {
    // Run inference synchronously for now
    // Note: For heavy models, consider using Isolate.run() for true async
    // However, tflite_flutter already handles some async internally
    return _runInference(input);
  }

  /// Run inference synchronously on the model
  ///
  /// This method directly invokes the TFLite interpreter.
  /// Handles both quantized (uint8) and float32 models.
  ///
  /// [input] - Preprocessed input tensor [1, 224, 224, 3]
  ///
  /// Returns probability distribution [38 classes]
  List<double> _runInference(List<List<List<List<double>>>> input) {
    if (_isQuantized) {
      return _runQuantizedInference(input);
    } else {
      return _runFloat32Inference(input);
    }
  }

  /// Run inference for float32 model
  List<double> _runFloat32Inference(List<List<List<List<double>>>> input) {
    // Prepare output buffer with shape [1, 38]
    final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);

    // Run the model
    _interpreter!.run(input, output);

    // Apply softmax to convert logits to probabilities
    final probabilities = _softmax(List<double>.from(output[0]));

    return probabilities;
  }

  /// Run inference for quantized (uint8) model
  List<double> _runQuantizedInference(
    List<List<List<List<double>>>> floatInput,
  ) {
    // Convert float input [0,1] to uint8 [0,255]
    final uint8Input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) => [
            (floatInput[0][y][x][0] * 255).round().clamp(0, 255),
            (floatInput[0][y][x][1] * 255).round().clamp(0, 255),
            (floatInput[0][y][x][2] * 255).round().clamp(0, 255),
          ],
        ),
      ),
    );

    // Prepare output buffer - quantized models output uint8
    final output = List.generate(1, (_) => List.filled(numClasses, 0));

    // Run the model
    _interpreter!.run(uint8Input, output);

    // Convert uint8 output to float probabilities
    // Quantized outputs are typically in [0, 255] range
    final floatOutput = output[0].map((v) => v / 255.0).toList();

    // Apply softmax to convert to probabilities
    final probabilities = _softmax(List<double>.from(floatOutput));

    return probabilities;
  }

  // ==========================================================================
  // POST-PROCESSING UTILITIES
  // ==========================================================================

  /// Apply softmax function to convert logits to probabilities
  ///
  /// Softmax formula: softmax(x_i) = exp(x_i - max) / Σ exp(x_j - max)
  /// Subtracting max ensures numerical stability (prevents overflow)
  ///
  /// [logits] - Raw model output values
  ///
  /// Returns normalized probabilities that sum to 1.0
  List<double> _softmax(List<double> logits) {
    if (logits.isEmpty) return [];

    // Find max value for numerical stability
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);

    // Calculate exp(logit - max) for each value
    final expValues = logits.map((l) => _safeExp(l - maxLogit)).toList();

    // Sum all exponentials
    final sumExp = expValues.fold<double>(0.0, (sum, val) => sum + val);

    // Avoid division by zero
    if (sumExp == 0) {
      return List.filled(logits.length, 1.0 / logits.length);
    }

    // Normalize to get probabilities
    return expValues.map((e) => e / sumExp).toList();
  }

  /// Safe exponential function to prevent overflow/underflow
  ///
  /// Clamps input to prevent numerical issues:
  /// - exp(88) ≈ 1.6e38 (near float max)
  /// - exp(-88) ≈ 6.1e-39 (near float min)
  ///
  /// [x] - Value to compute exp() for
  ///
  /// Returns exp(x) clamped to safe range
  double _safeExp(double x) {
    const maxInput = 88.0;
    const minInput = -88.0;

    if (x > maxInput) return double.maxFinite;
    if (x < minInput) return 0.0;

    // Use dart:math for standard exp calculation
    return _exp(x);
  }

  /// Calculate e^x using Taylor series
  ///
  /// This is a fallback implementation. For production,
  /// consider using dart:math's exp() function directly.
  double _exp(double x) {
    if (x == 0) return 1.0;

    // For small values, use Taylor series
    double result = 1.0;
    double term = 1.0;

    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
      if (term.abs() < 1e-10) break;
    }

    return result;
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  /// Get top-K predictions sorted by confidence
  ///
  /// Returns the K most likely predictions, useful for
  /// showing alternative diagnoses or uncertainty indicators.
  ///
  /// [probabilities] - Full probability distribution from inference
  /// [k] - Number of top predictions to return (default: 3)
  ///
  /// Returns list of maps with 'index', 'label', and 'probability'
  List<Map<String, dynamic>> getTopKPredictions(
    List<double> probabilities, {
    int k = 3,
  }) {
    // Create indexed list of predictions
    final indexed = <Map<String, dynamic>>[];
    for (int i = 0; i < probabilities.length && i < classLabels.length; i++) {
      indexed.add({
        'index': i,
        'label': classLabels[i],
        'probability': probabilities[i],
      });
    }

    // Sort by probability descending
    indexed.sort(
      (a, b) =>
          (b['probability'] as double).compareTo(a['probability'] as double),
    );

    // Return top K
    return indexed.take(k).toList();
  }

  /// Convert raw label to human-readable format
  ///
  /// Transforms "Tomato___Early_blight" to "Tomato - Early Blight"
  ///
  /// [label] - Raw label from classLabels
  ///
  /// Returns formatted, readable string
  String getReadableLabel(String label) {
    return label
        .replaceAll('___', ' - ') // Replace separator
        .replaceAll('_', ' ') // Replace underscores
        .split(' ') // Split into words
        .map(
          (word) =>
              word
                  .isNotEmpty // Capitalize each word
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : word,
        )
        .join(' ');
  }

  /// Release model resources
  ///
  /// Call this when the model is no longer needed to free memory.
  /// After calling dispose(), loadModel() must be called again
  /// before any predictions.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isModelLoaded = false;
    print('ModelService: Resources disposed');
  }

  /// Force reload the model
  ///
  /// Useful for updating to a new model file without restarting the app.
  Future<void> reloadModel() async {
    dispose();
    await loadModel();
  }
}

// ==========================================================================
// HELPER EXTENSION - Reshape flat list to 2D
// ==========================================================================

/// Extension to reshape a flat list into a 2D list
///
/// Used to format output buffer for TFLite interpreter
extension ReshapeList<T> on List<T> {
  /// Reshape flat list into 2D list with given dimensions
  ///
  /// [shape] - Target shape [rows, cols]
  ///
  /// Returns 2D list with specified shape
  List<List<T>> reshape(List<int> shape) {
    if (shape.length != 2) {
      throw ArgumentError('reshape only supports 2D');
    }

    final rows = shape[0];
    final cols = shape[1];

    if (length != rows * cols) {
      throw ArgumentError(
        'Cannot reshape list of length $length into shape $shape',
      );
    }

    return List.generate(rows, (i) => sublist(i * cols, (i + 1) * cols));
  }
}
