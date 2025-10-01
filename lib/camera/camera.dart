import 'dart:io';
import 'package:agrolens_version2/pages/result_page.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _capturedImage;
  List<CameraDescription>? cameras;

  bool _isLoading = false;

  late AnimationController _captureAnimationController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() => _isLoading = true);

    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        _showErrorSnackBar("No camera found");
        setState(() => _isLoading = false);
        return;
      }

      _controller = CameraController(
        cameras![0], 
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;

      // Ensure controller is ready before updating UI
      if (mounted && _controller.value.isInitialized) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("Camera initialization failed");
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _takePicture() async {
    await _initializeControllerFuture;
    

    
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {
        setState(() => _capturedImage = pickedFile);
        HapticFeedback.mediumImpact();
        _showSuccessSnackBar("Image selected from gallery");
      }
    } catch (e) {
      _showErrorSnackBar("Failed to pick image from gallery");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF9bc03f),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_isLoading || !_controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.previewSize?.height ?? 0,
              height: _controller.value.previewSize?.width ?? 0,
              child: CameraPreview(_controller),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _captureAnimationController,
          builder: (context, child) {
            return _captureAnimationController.value > 0
                ? Container(
                    color: Colors.white.withOpacity(
                      _captureAnimationController.value * 0.8,
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              "Find a rice leaf",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 48), // Balance the layout
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 70,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          GestureDetector(
            onTap: _pickImageFromGallery,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                CupertinoIcons.photo,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          // Camera capture button (main)
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                
              ),
              child: const Icon(
                CupertinoIcons.camera,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          
          // Spacer to balance layout (or add flip camera button if needed)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedImagePreview() {
    if (_capturedImage == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned.fill(
          child: Image.file(
            File(_capturedImage!.path),
            fit: BoxFit.cover,
          ),
        ),
        // Top controls container
        Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Photo captured",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 48), 
              ],
            ),
          ),
        ),
        
        // Bottom controls for captured image
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Retake button
              ElevatedButton.icon(
                onPressed: () {
                  _captureAnimationController.reset();
                  setState(() => _capturedImage = null);
                },
                icon: const Icon(CupertinoIcons.refresh),
                label: const Text("Retake"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              
              // Analyze button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ResultPage(capturedImage: _capturedImage!),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.wand_stars),
                label: const Text("Analyze"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9bc03f),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _captureAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? Container(
              color: Colors.black, 
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            )
          : Stack(
              children: [
                _capturedImage == null
                    ? _buildCameraPreview()
                    : _buildCapturedImagePreview(),
                if (_capturedImage == null) _buildTopControls(),
                if (_capturedImage == null) _buildBottomControls(),
              ],
            ),
    );
  }
}