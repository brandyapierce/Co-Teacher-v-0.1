import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../data/services/camera_service.dart';

/// Widget for displaying camera preview with overlays and controls
class CameraPreviewWidget extends StatefulWidget {
  final CameraService cameraService;
  final VoidCallback? onCapture;
  final Widget? overlay;
  final bool showControls;
  
  const CameraPreviewWidget({
    super.key,
    required this.cameraService,
    this.onCapture,
    this.overlay,
    this.showControls = true,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  bool _isInitializing = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }
  
  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    
    try {
      await widget.cameraService.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = e.toString();
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Camera Error', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final controller = widget.cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: Text('Camera not available'));
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        
        // Custom overlay (e.g., face detection boxes)
        if (widget.overlay != null) widget.overlay!,
        
        // Controls
        if (widget.showControls)
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Capture button
                FloatingActionButton.large(
                  onPressed: widget.onCapture,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.camera, color: Colors.black, size: 36),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  @override
  void dispose() {
    // Don't dispose the camera service here - it's managed externally
    super.dispose();
  }
}

/// Widget for drawing face detection bounding boxes on camera preview
class FaceDetectionOverlay extends StatelessWidget {
  final List<Rect> faces;
  final Size previewSize;
  final Color boxColor;
  final double strokeWidth;
  
  const FaceDetectionOverlay({
    super.key,
    required this.faces,
    required this.previewSize,
    this.boxColor = Colors.green,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FaceBoxPainter(
        faces: faces,
        previewSize: previewSize,
        boxColor: boxColor,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _FaceBoxPainter extends CustomPainter {
  final List<Rect> faces;
  final Size previewSize;
  final Color boxColor;
  final double strokeWidth;
  
  _FaceBoxPainter({
    required this.faces,
    required this.previewSize,
    required this.boxColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    // Scale factor to convert from model coordinates to screen coordinates
    final scaleX = size.width / previewSize.width;
    final scaleY = size.height / previewSize.height;
    
    for (final face in faces) {
      final scaledRect = Rect.fromLTRB(
        face.left * scaleX,
        face.top * scaleY,
        face.right * scaleX,
        face.bottom * scaleY,
      );
      
      canvas.drawRect(scaledRect, paint);
      
      // Draw corner brackets for a more modern look
      _drawCornerBrackets(canvas, scaledRect, paint);
    }
  }
  
  void _drawCornerBrackets(Canvas canvas, Rect rect, Paint paint) {
    const bracketLength = 20.0;
    
    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(bracketLength, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, bracketLength), paint);
    
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-bracketLength, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, bracketLength), paint);
    
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(bracketLength, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -bracketLength), paint);
    
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-bracketLength, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -bracketLength), paint);
  }

  @override
  bool shouldRepaint(covariant _FaceBoxPainter oldDelegate) {
    return faces != oldDelegate.faces || 
           previewSize != oldDelegate.previewSize ||
           boxColor != oldDelegate.boxColor;
  }
}

