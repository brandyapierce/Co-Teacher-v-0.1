import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Utilities for preprocessing images for CV models
class ImagePreprocessing {
  /// Convert Flutter Image to Uint8List
  static Future<Uint8List> imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
  
  /// Resize image to specified dimensions
  static img.Image resizeImage(img.Image image, int width, int height) {
    return img.copyResize(
      image,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
  }
  
  /// Crop image to specified rectangle
  static img.Image cropImage(img.Image image, Rect rect) {
    return img.copyCrop(
      image,
      x: rect.left.toInt(),
      y: rect.top.toInt(),
      width: rect.width.toInt(),
      height: rect.height.toInt(),
    );
  }
  
  /// Normalize pixel values to [0, 1] range
  static List<double> normalizePixels(Uint8List pixels) {
    return pixels.map((pixel) => pixel / 255.0).toList();
  }
  
  /// Normalize pixel values to [-1, 1] range
  static List<double> normalizePixelsMinus1To1(Uint8List pixels) {
    return pixels.map((pixel) => (pixel / 127.5) - 1.0).toList();
  }
  
  /// Convert Uint8List to img.Image for processing
  static img.Image? bytesToImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }
  
  /// Convert img.Image back to Uint8List
  static Uint8List imageToUint8List(img.Image image) {
    return Uint8List.fromList(img.encodePng(image));
  }
  
  /// Prepare image for TFLite face detection (128x128, normalized)
  static Future<List<List<List<List<double>>>>> preprocessForFaceDetection(
    Uint8List imageBytes,
  ) async {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    // Resize to 128x128 for MediaPipe BlazeFace
    final resized = resizeImage(image, 128, 128);
    
    // Convert to normalized float array [1, 128, 128, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        128,
        (y) => List.generate(
          128,
          (x) {
            final pixel = resized.getPixel(x, y);
            // Extract RGB values and normalize to [0, 1]
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    
    return input;
  }
  
  /// Prepare cropped face for embedding extraction (112x112, normalized)
  static Future<List<List<List<List<double>>>>> preprocessForEmbedding(
    Uint8List imageBytes,
    Rect faceRect,
  ) async {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }
    
    // Crop to face region with some padding
    final padding = 20;
    final paddedRect = Rect.fromLTRB(
      (faceRect.left - padding).clamp(0, image.width.toDouble()),
      (faceRect.top - padding).clamp(0, image.height.toDouble()),
      (faceRect.right + padding).clamp(0, image.width.toDouble()),
      (faceRect.bottom + padding).clamp(0, image.height.toDouble()),
    );
    
    final cropped = cropImage(image, paddedRect);
    
    // Resize to 112x112 for face embedding models
    final resized = resizeImage(cropped, 112, 112);
    
    // Convert to normalized float array [1, 112, 112, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        112,
        (y) => List.generate(
          112,
          (x) {
            final pixel = resized.getPixel(x, y);
            // Normalize to [0, 1]
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    
    return input;
  }
  
  /// Calculate cosine similarity between two embedding vectors
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw ArgumentError('Vectors must have same length');
    }
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }
    
    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
  }
  
  /// L2 normalize embedding vector
  static List<double> l2Normalize(List<double> vector) {
    double sum = 0.0;
    for (final value in vector) {
      sum += value * value;
    }
    
    final norm = Math.sqrt(sum);
    if (norm == 0.0) {
      return vector;
    }
    
    return vector.map((v) => v / norm).toList();
  }
  
  /// Convert image bytes to grayscale
  static img.Image toGrayscale(img.Image image) {
    return img.grayscale(image);
  }
  
  /// Rotate image by specified angle
  static img.Image rotateImage(img.Image image, double angleDegrees) {
    return img.copyRotate(image, angle: angleDegrees);
  }
  
  /// Flip image horizontally (mirror)
  static img.Image flipHorizontal(img.Image image) {
    return img.flipHorizontal(image);
  }
  
  /// Adjust image brightness
  static img.Image adjustBrightness(img.Image image, int amount) {
    return img.adjustColor(image, brightness: amount.toDouble());
  }
  
  /// Adjust image contrast
  static img.Image adjustContrast(img.Image image, double contrast) {
    return img.contrast(image, contrast: contrast);
  }
}

/// Extension for easy access to math functions
extension Math on num {
  static double sqrt(num value) => value < 0 ? 0.0 : value.toDouble().abs().sqrt();
}

extension on double {
  double sqrt() {
    if (this < 0) return 0.0;
    // Use Newton's method for square root
    if (this == 0) return 0;
    double x = this;
    double y = 1;
    double e = 0.000001;
    while (x - y > e) {
      x = (x + y) / 2;
      y = this / x;
    }
    return x;
  }
}

