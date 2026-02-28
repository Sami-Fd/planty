/// DiseaseInfoLoader - Loads disease information from local JSON
///
/// This class handles loading and parsing the disease_info.json file
/// which contains detailed information about each plant disease
/// that the model can detect.

import 'dart:convert';
import 'package:flutter/services.dart';

/// Data class representing information about a plant disease
class DiseaseInfo {
  final int index;
  final String label;
  final String plant;
  final String disease;
  final String description;
  final String treatment;
  final String guidance;
  final String irrigation;
  final String fertilization;
  final List<String> images;

  const DiseaseInfo({
    required this.index,
    required this.label,
    required this.plant,
    required this.disease,
    required this.description,
    required this.treatment,
    this.guidance = '',
    this.irrigation = '',
    this.fertilization = '',
    this.images = const [],
  });

  /// Create a DiseaseInfo from JSON map
  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    // Parse assets/images if present
    List<String> imageList = [];
    if (json['assets'] != null && json['assets']['images'] != null) {
      imageList = List<String>.from(json['assets']['images']);
    }

    return DiseaseInfo(
      index: json['index'] as int,
      label: json['label'] as String,
      plant: json['plant'] as String,
      disease: json['disease'] as String,
      description: json['description'] as String,
      treatment: json['treatment'] as String,
      guidance: json['guidance'] as String? ?? '',
      irrigation: json['irrigation'] as String? ?? '',
      fertilization: json['fertilization'] as String? ?? '',
      images: imageList,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'label': label,
      'plant': plant,
      'disease': disease,
      'description': description,
      'treatment': treatment,
      'guidance': guidance,
      'irrigation': irrigation,
      'fertilization': fertilization,
      'assets': {'images': images},
    };
  }

  /// Get display-friendly name (e.g., "Tomato - Early Blight")
  String get displayName => '$plant - $disease';

  /// Check if this is a healthy plant (no disease)
  bool get isHealthy => disease.toLowerCase() == 'healthy';

  @override
  String toString() => 'DiseaseInfo($displayName)';
}

/// Service class for loading and accessing disease information
///
/// Usage:
/// ```dart
/// final loader = DiseaseInfoLoader();
/// await loader.loadDiseaseInfo();
/// final info = loader.getDiseaseByIndex(29);
/// ```
class DiseaseInfoLoader {
  // Singleton pattern
  static final DiseaseInfoLoader _instance = DiseaseInfoLoader._internal();
  factory DiseaseInfoLoader() => _instance;
  DiseaseInfoLoader._internal();

  // Path to the JSON file
  static const String _jsonPath = 'assets/data/disease_info.json';

  // Loaded disease information
  List<DiseaseInfo> _diseases = [];

  // Map for quick lookup by label
  Map<String, DiseaseInfo> _diseasesByLabel = {};

  // Map for quick lookup by index
  Map<int, DiseaseInfo> _diseasesByIndex = {};

  // Whether data has been loaded
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // Get all diseases
  List<DiseaseInfo> get allDiseases => List.unmodifiable(_diseases);

  /// Load disease information from the JSON asset file
  ///
  /// This should be called once during app initialization.
  /// Subsequent calls will be no-ops if data is already loaded.
  ///
  /// Throws [Exception] if loading fails.
  Future<void> loadDiseaseInfo() async {
    if (_isLoaded) {
      print('DiseaseInfoLoader: Data already loaded');
      return;
    }

    try {
      print('DiseaseInfoLoader: Loading disease info from $_jsonPath');

      // Load the JSON file from assets
      final jsonString = await rootBundle.loadString(_jsonPath);

      // Parse the JSON
      final List<dynamic> jsonList = json.decode(jsonString);

      // Convert to DiseaseInfo objects
      _diseases = jsonList
          .map((json) => DiseaseInfo.fromJson(json as Map<String, dynamic>))
          .toList();

      // Build lookup maps
      _diseasesByLabel = {
        for (var disease in _diseases) disease.label: disease,
      };

      _diseasesByIndex = {
        for (var disease in _diseases) disease.index: disease,
      };

      _isLoaded = true;
      print('DiseaseInfoLoader: Loaded ${_diseases.length} diseases');
    } catch (e) {
      print('DiseaseInfoLoader: Error loading disease info: $e');
      _isLoaded = false;
      rethrow;
    }
  }

  /// Get disease information by class index (0-37)
  ///
  /// Returns null if index is out of range or data not loaded.
  DiseaseInfo? getDiseaseByIndex(int index) {
    if (!_isLoaded) {
      print('DiseaseInfoLoader: Warning - Data not loaded');
      return null;
    }
    return _diseasesByIndex[index];
  }

  /// Get disease information by label string
  ///
  /// [label] should match the model's class label exactly,
  /// e.g., "Tomato___Early_blight"
  ///
  /// Returns null if label not found or data not loaded.
  DiseaseInfo? getDiseaseByLabel(String label) {
    if (!_isLoaded) {
      print('DiseaseInfoLoader: Warning - Data not loaded');
      return null;
    }
    return _diseasesByLabel[label];
  }

  /// Get all diseases for a specific plant type
  ///
  /// [plant] - The plant name (e.g., "Tomato", "Apple")
  List<DiseaseInfo> getDiseasesForPlant(String plant) {
    return _diseases
        .where((d) => d.plant.toLowerCase() == plant.toLowerCase())
        .toList();
  }

  /// Get all healthy plant entries
  List<DiseaseInfo> getHealthyPlants() {
    return _diseases.where((d) => d.isHealthy).toList();
  }

  /// Get all disease entries (excluding healthy)
  List<DiseaseInfo> getDiseases() {
    return _diseases.where((d) => !d.isHealthy).toList();
  }

  /// Get unique plant types in the dataset
  List<String> getPlantTypes() {
    return _diseases.map((d) => d.plant).toSet().toList()..sort();
  }

  /// Search diseases by keyword in name or description
  List<DiseaseInfo> searchDiseases(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _diseases.where((d) {
      return d.plant.toLowerCase().contains(lowercaseQuery) ||
          d.disease.toLowerCase().contains(lowercaseQuery) ||
          d.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Clear loaded data (useful for testing or memory management)
  void clear() {
    _diseases = [];
    _diseasesByLabel = {};
    _diseasesByIndex = {};
    _isLoaded = false;
  }
}
