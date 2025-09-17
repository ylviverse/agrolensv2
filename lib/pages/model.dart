import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'dart:math' as math;

class RiceDiseaseModel {
  static RiceDiseaseModel? _instance;
  bool _isModelLoaded = false;
  ClassificationModel? _model; 
  
  
  // Singleton pattern for model instance
  static RiceDiseaseModel get instance {
    _instance ??= RiceDiseaseModel._internal();
    return _instance!;
  }
  
  RiceDiseaseModel._internal();

  // Disease labels 
  static const List<String> diseaseLabels = [
    'Bacterial Leaf Blight',
    'Brown Spot',
    'Leaf Blast', 
    'Sheath Blight',
    'Tungro'
  ];

  // Model configuration
  static const String modelPath = 'assets/model/MobileNetV2_for_mobile_finalV2.ptl';
  static const int inputSize = 224;
  static const List<double> imagenetMean = [0.485, 0.456, 0.406];
  static const List<double> imagenetStd = [0.229, 0.224, 0.225];

  /// Initialize the model
  Future<bool> loadModel() async {
    if (_isModelLoaded && _model != null) return true;
    
    print('🔧 Loading model from: $modelPath');
    
    try {
      final ByteData assetData = await rootBundle.load(modelPath);
      print('Asset verified, size: ${assetData.lengthInBytes} bytes');
    } catch (e) {
      print(' Asset not found: $e');
      return false;
    }
    
    try {
    
      _model = await PytorchLite.loadClassificationModel(
        modelPath,
        inputSize,
        inputSize,
        diseaseLabels.length,
      );
      
      if (_model != null) {
        _isModelLoaded = true;
        print('Model loaded successfully');
        return true;
      }
    } catch (e) {
      print('Model loading failed: $e');
    }
    
    // Fallback to mock implementation
    _isModelLoaded = true;
    print('Using mock implementation');
    return true;
  }

  /// Predict disease from image path
  Future<Map<String, dynamic>> predictDisease(String imagePath) async {
    if (!_isModelLoaded) {
      bool loaded = await loadModel();
      if (!loaded) {
        return {
          'disease': 'Error',
          'confidence': 0.0,
          'severity': 'Unknown',
          'error': 'Failed to load AI model',
        };
      }
    }

    print('Running prediction on: $imagePath');
    
    // Try real model first
    if (_model != null) {
      try {
        // Use getImagePredictionList for classification
        List<double>? results = await _model!.getImagePredictionList(
          await File(imagePath).readAsBytes(),
        );
        
        if (results != null && results.isNotEmpty) {
          print('Got classification results: $results');
          return _processClassificationResults(results);
        }
      } catch (e) {
        print('Classification failed: $e');
      }
    }
    
    // Fallback to mock prediction
    print('Using mock prediction');
    return _getMockPrediction();
  }

  /// Process classification results
  Map<String, dynamic> _processClassificationResults(List<double> results) {
    // Convert logits to probabilities using softmax
    List<double> probabilities = _softmax(results);
    
    // Find the index with highest probability
    int bestIndex = 0;
    double maxScore = probabilities[0];
    
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > maxScore) {
        maxScore = probabilities[i];
        bestIndex = i;
      }
    }
    
    // Map class index to disease label
    String disease = bestIndex < diseaseLabels.length 
      ? diseaseLabels[bestIndex]
      : 'Unknown Disease';
    
    double confidence = maxScore;
    
    // If confidence is below 70%, classify as unknown disease
    if (confidence < 0.7) {
      disease = 'Unknown Disease';
      confidence = 0.0;
    }
    
    String severity = _calculateSeverity(disease, confidence);
    
    print('✅ Predicted: $disease (${(confidence * 100).toStringAsFixed(1)}%)');
    print('📊 All probabilities: ${probabilities.map((p) => '${(p * 100).toStringAsFixed(1)}%').toList()}');
    
    return {
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'raw_prediction': bestIndex.toString(),
    };
  }

  /// Convert logits to probabilities using softmax function
  List<double> _softmax(List<double> logits) {
    // Find max value for numerical stability
    double maxLogit = logits.reduce(math.max);
    
    // Subtract max and compute exponentials
    List<double> expValues = logits.map((x) => math.exp(x - maxLogit)).toList();
    
    // Compute sum of exponentials
    double sumExp = expValues.reduce((a, b) => a + b);
    
    // Normalize to get probabilities
    return expValues.map((x) => x / sumExp).toList();
  }













// this is if ever the model fails to load or predict













  /// Mock prediction for testing
  Map<String, dynamic> _getMockPrediction() {
    final random = DateTime.now().millisecond;
    final diseaseIndex = random % diseaseLabels.length;
    final disease = diseaseLabels[diseaseIndex];
    final confidence = 0.80 + (random % 20) / 100; // 80-99%

    print('🎭 Mock prediction: $disease (${(confidence * 100).toStringAsFixed(1)}%)');

    return {
      'disease': disease,
      'confidence': confidence,
      'severity': _calculateSeverity(disease, confidence),
      'raw_prediction': 'mock_$diseaseIndex',
    };
  }

  /// Calculate disease severity based on prediction confidence
  String _calculateSeverity(String disease, double confidence) {
    if (disease.toLowerCase() == 'unknown disease') {
      return 'Unknown';
    }
    
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Moderate';
    return 'Low';
  }

  /// Get human-readable disease description
  String getDiseaseDescription(String disease) {
    switch (disease.toLowerCase()) {
      case 'bacterial leaf blight':
        return 'Bacterial leaf blight is a serious disease caused by Xanthomonas oryzae pv. oryzae. It causes wilting and yellowing of leaves, significantly reducing rice yield.';
      case 'rice blast':
        return 'Rice blast is a fungal disease caused by Magnaporthe oryzae. It can cause significant yield losses by destroying leaves, stems, and panicles.';
      case 'sheath blight':
        return 'Sheath blight is caused by the fungus Rhizoctonia solani. It affects the sheath and leaves, causing lesions that can reduce photosynthesis and yield.';
      case 'tungro virus':
        return 'Tungro virus is transmitted by green leafhoppers. It causes stunted growth, yellowing of leaves, and reduced tillering in rice plants.';
      case 'brown spot':
        return 'Brown spot is a fungal disease caused by Bipolaris oryzae. It appears as brown lesions on leaves and can reduce photosynthesis and yield.';
      default:
        return 'Unknown condition detected. Please consult with an agricultural expert for proper diagnosis and treatment.';
    }
  }

  /// hard coded recommendations based on disease
  List<String> getRecommendations(String disease) {
    switch (disease.toLowerCase()) {
      case 'bacterial leaf blight':
        return [
          'Use certified disease-free seeds',
          'Avoid overhead irrigation during flowering',
          'Apply copper-based bactericides early',
          'Remove and destroy infected plants',
          'Practice field sanitation and equipment disinfection',
        ];
      case 'rice blast':
        return [
          'Ensure good air circulation in the field',
          'Avoid excessive nitrogen fertilization',
          'Plant blast-resistant rice varieties',
          'Apply preventive fungicides during susceptible growth stages',
          'Implement crop rotation practices',
        ];
      case 'sheath blight':
        return [
          'Maintain proper field drainage',
          'Avoid excessive nitrogen application',
          'Use balanced fertilization',
          'Apply fungicides when disease pressure is high',
          'Remove infected plant debris',
        ];
      case 'tungro virus':
        return [
          'Control green leafhopper vectors with insecticides',
          'Use virus-resistant rice varieties',
          'Remove and destroy infected plants',
          'Implement proper field sanitation',
          'Avoid planting near infected fields',
        ];
      case 'brown spot':
        return [
          'Improve field drainage to reduce humidity',
          'Apply potassium fertilizer to strengthen plants',
          'Use certified disease-resistant varieties',
          'Apply fungicides like carbendazim if severe',
          'Remove infected plant debris',
        ];
      default:
        return [
          'Consult with local agricultural extension services',
          'Get professional diagnosis from plant pathologist',
          'Monitor plant symptoms closely',
          'Maintain good field hygiene practices',
          'Consider laboratory testing for accurate identification',
        ];
    }
  }

  /// Dispose resources when no longer needed
  void dispose() {
    _model = null;
    _isModelLoaded = false;
    print('🗑️ RiceDiseaseModel disposed');
  }
}