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
  static const String modelPath = 'assets/model/MobileNetV2_mobile_finalV1.ptl';
  static const int inputSize = 224;
  static const List<double> imagenetMean = [0.485, 0.456, 0.406];
  static const List<double> imagenetStd = [0.229, 0.224, 0.225];

  /// Initialize the model
  Future<bool> loadModel() async {
    if (_isModelLoaded && _model != null) return true;
    
    print('Loading model from: $modelPath');
    
    try {
      final ByteData assetData = await rootBundle.load(modelPath);
      print('Asset verified, size: ${assetData.lengthInBytes} bytes');
    } catch (e) {
      print('Asset not found: $e');
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
      return false;
    }
    
    return false;
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
          'top3_predictions': [],
        };
      }
    }

    print('Running prediction on: $imagePath');
    
    if (_model != null) {
      try {
        List<double>? results = await _model!.getImagePredictionList(
          await File(imagePath).readAsBytes(),
        );
        
        if (results != null && results.isNotEmpty) {
          print('Got classification results: $results');
          return _processClassificationResults(results);
        }
      } catch (e) {
        print('Classification failed: $e');
        return {
          'disease': 'Error',
          'confidence': 0.0,
          'severity': 'Unknown',
          'error': 'Prediction failed: $e',
          'top3_predictions': [],
        };
      }
    }
    
    return {
      'disease': 'Error',
      'confidence': 0.0,
      'severity': 'Unknown',
      'error': 'Model not available',
      'top3_predictions': [],
    };
  }

  /// Process classification results
  Map<String, dynamic> _processClassificationResults(List<double> results) {
    // Convert logits to probabilities using softmax
    List<double> probabilities = _softmax(results);
    
    // Create list of disease-probability pairs
    List<Map<String, dynamic>> diseaseProbs = [];
    for (int i = 0; i < probabilities.length && i < diseaseLabels.length; i++) {
      diseaseProbs.add({
        'disease': diseaseLabels[i],
        'confidence': probabilities[i],
        'index': i,
      });
    }
    
    // Sort by confidence (highest first)
    diseaseProbs.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    
    // Get top 3
    List<Map<String, dynamic>> top3 = diseaseProbs.take(3).toList();
    
    String primaryDisease = top3[0]['disease'];
    double primaryConfidence = top3[0]['confidence'];
    
    // If confidence is below 70%, classify as unknown disease
    if (primaryConfidence < 0.7) {
      primaryDisease = 'Unknown Disease';
      primaryConfidence = 0.0;
    }
    
    String severity = _calculateSeverity(primaryDisease, primaryConfidence);
    
    print('Top 3 predictions:');
    for (var pred in top3) {
      print('${pred['disease']}: ${(pred['confidence'] * 100).toStringAsFixed(1)}%');
    }
    
    return {
      'disease': primaryDisease,
      'confidence': primaryConfidence,
      'severity': severity,
      'top3_predictions': top3,
      'raw_prediction': top3[0]['index'].toString(),
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
      case 'leaf blast':
      case 'rice blast':
        return 'Rice blast is a fungal disease caused by Magnaporthe oryzae. It can cause significant yield losses by destroying leaves, stems, and panicles.';
      case 'sheath blight':
        return 'Sheath blight is caused by the fungus Rhizoctonia solani. It affects the sheath and leaves, causing lesions that can reduce photosynthesis and yield.';
      case 'tungro':
      case 'tungro virus':
        return 'Tungro virus is transmitted by green leafhoppers. It causes stunted growth, yellowing of leaves, and reduced tillering in rice plants.';
      case 'brown spot':
        return 'Brown spot is a fungal disease caused by Bipolaris oryzae. It appears as brown lesions on leaves and can reduce photosynthesis and yield.';
      case 'unknown disease':
        return 'Unable to identify the specific condition. The symptoms may be unclear or the disease may not be in our database.';
      case 'error':
        return 'An error occurred during analysis. Please try again or consult with an agricultural expert.';
      default:
        return 'Unknown condition detected. Please consult with an agricultural expert for proper diagnosis and treatment.';
    }
  }



  /// Dispose resources when no longer needed
  void dispose() {
    _model = null;
    _isModelLoaded = false;
    print('RiceDiseaseModel disposed');
  }
}