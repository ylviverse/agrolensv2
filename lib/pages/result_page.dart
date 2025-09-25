import 'dart:io';
import 'package:agrolens_version2/colors/colors.dart';
import 'package:agrolens_version2/pages/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:lottie/lottie.dart';

class ResultPage extends StatefulWidget {
  final XFile capturedImage;

  const ResultPage({
    super.key,
    required this.capturedImage,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> with TickerProviderStateMixin {
  bool _isAnalyzing = true;
  String? _prediction;
  double? _confidence;
  Map<String, dynamic>? _analysisResults;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final RiceDiseaseModel _model = RiceDiseaseModel.instance;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _analyzeImage();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Analyze the captured image using the AI model
  Future<void> _analyzeImage() async {
    setState(() => _isAnalyzing = true);

    try {
      // Check if image file exists
      final imageFile = File(widget.capturedImage.path);
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Load model and get prediction
      bool modelLoaded = await _model.loadModel();
      if (!modelLoaded) {
        throw Exception('Failed to load AI model');
      }

      await Future.delayed(const Duration(seconds: 1)); // UX delay

      final results = await _model.predictDisease(widget.capturedImage.path);

      if (results.isEmpty) {
        throw Exception('Model returned empty results');
      }

      setState(() {
        _prediction = results['disease'] ?? 'Unknown';
        _confidence = results['confidence'] ?? 0.0;
        _analysisResults = results;
        _isAnalyzing = false;
      });

      _pulseController.stop();
    } catch (e) {
      print('Analysis error: $e');

      setState(() {
        _prediction = 'Error analyzing image';
        _confidence = 0.0;
        _analysisResults = {
          'error': e.toString(),
          'disease': 'Error',
          'confidence': 0.0,
          'severity': 'Unknown'
        };
        _isAnalyzing = false;
      });
      _pulseController.stop();

      _showErrorDialog(e.toString());
    }
  }

  /// Show error dialog to user
  void _showErrorDialog(String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Analysis Error'),
        content: Text('Failed to analyze image: $error'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('Retry'),
            onPressed: () {
              Navigator.of(context).pop();
              _analyzeImage();
            },
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(String disease) {
    switch (disease.toLowerCase()) {
      case 'brown spot':
      case 'leaf blast':
      case 'bacterial leaf blight':
      case 'sheath blight':
      case 'tungro':
        return CupertinoColors.systemYellow;
      case 'unknown disease':
        return CupertinoColors.systemOrange;
      case 'error':
        return CupertinoColors.systemOrange;
      default:
        return CupertinoColors.systemYellow;
    }
  }

  IconData _getHealthIcon(String disease) {
    switch (disease.toLowerCase()) {
      case 'brown spot':
      case 'leaf blast':
      case 'bacterial leaf blight':
      case 'sheath blight':
      case 'tungro':
        return CupertinoIcons.exclamationmark_triangle;
      case 'unknown disease':
        return CupertinoIcons.question_circle;
      case 'error':
        return CupertinoIcons.xmark_circle_fill;
      default:
        return CupertinoIcons.question_circle_fill;
    }
  }

  Widget _buildLoadingAnimation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Lottie.asset(
            'assets/animations/Loading.json',
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Analyzing your rice...',
          style: TextStyle(
            fontSize: 24,
            color: CupertinoColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please wait while our AI examines the image',
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.white,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        const CupertinoActivityIndicator(
          color: CupertinoColors.white,
          radius: 15,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CupertinoNavigationBarBackButton(
          color: CupertinoColors.white,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Analysis Result',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: MyColor.greenish,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Captured Image Display
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.capturedImage.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 60),


              // Loading Animation or Results
              if (_isAnalyzing) ...[
                _buildLoadingAnimation(),
              ] else ...[
                // Top 3 Predictions
                if (_analysisResults != null &&
                    _prediction != null &&
                    _prediction != 'Error') ...[
                  // This block will now build the list of results
                  () {
                    // Get top 3 predictions from the model's output
                    List<Map<String, dynamic>> top3 =
                        _analysisResults!['top3_predictions'] ?? [];

                    // Fallback if top3 is still empty for some reason
                    if (top3.isEmpty &&
                        _prediction != null &&
                        _confidence != null) {
                      top3 = [
                        {
                          'disease': _prediction!,
                          'confidence': _confidence!,
                        }
                      ];
                    }

                    // ...existing code...
                    // Build the UI widgets from the top3 list
                    return Column(
                      children: List.generate(top3.length, (i) {
                        final prediction = top3[i];
                        final diseaseName = prediction['disease'] as String;
                        final confidence = (prediction['confidence'] as double) * 100;

                        // This is the widget for a single result item, using your original design style
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: i == 0
                                ? Colors.white.withOpacity(0.25) 
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: i == 0
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Use your icon helper
                                  Icon(
                                    _getHealthIcon(diseaseName),
                                    color: _getHealthColor(diseaseName),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      diseaseName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                
                                ],
                              ),
                              const SizedBox(height: 12),


                              
                              // Divider using your health color
                              Divider(
                                color: _getHealthColor(diseaseName).withOpacity(0.5),
                                thickness: 1,
                              ),
                              const SizedBox(height: 12),
                              // Description text
                              Text(
                                _model.getDiseaseDescription(diseaseName),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  }(),
                ],

                const SizedBox(height: 20),

              ],
            ],
          ),
        ),
      ),
    );
  }
}
