// same imports...
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:facetrust/pages/success_page.dart';
import 'package:facetrust/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with SingleTickerProviderStateMixin {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.3,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  late CameraController cameraController;
  bool isCameraInitialized = false;
  bool isDetecting = false;
  bool isFrontCamera = true;
  List<String> challengeActions = ['smile', 'blink', 'lookRight', 'lookLeft'];
  int currentActionIndex = 0;
  bool waitingForNeutral = false;
  String? smileImagePath;

  double? smilingProbability;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? headEulerAngleY;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    challengeActions.shuffle();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeController.forward();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front);
    cameraController = CameraController(frontCamera, ResolutionPreset.high,
        enableAudio: false);
    await cameraController.initialize();
    if (mounted) {
      setState(() {
        isCameraInitialized = true;
      });
      startFaceDetection();
    }
  }

  void startFaceDetection() {
    if (isCameraInitialized) {
      cameraController.startImageStream((CameraImage image) {
        if (!isDetecting) {
          isDetecting = true;
          detectFaces(image).then((_) => isDetecting = false);
        }
      });
    }
  }

  Future<void> detectFaces(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      if (!mounted || faces.isEmpty) return;

      final face = faces.first;
      setState(() {
        smilingProbability = face.smilingProbability;
        leftEyeOpenProbability = face.leftEyeOpenProbability;
        rightEyeOpenProbability = face.rightEyeOpenProbability;
        headEulerAngleY = face.headEulerAngleY;
      });

      checkChallenge(face);
    } catch (e) {
      debugPrint('Error in face detection: $e');
    }
  }

  void checkChallenge(Face face) async {
    if (waitingForNeutral && !isNeutralPosition(face)) return;
    if (waitingForNeutral && isNeutralPosition(face)) {
      waitingForNeutral = false;
    }

    final currentAction = challengeActions[currentActionIndex];
    bool actionCompleted = false;

    switch (currentAction) {
      case 'smile':
        actionCompleted =
            face.smilingProbability != null && face.smilingProbability! > 0.5;
        break;
      case 'blink':
        actionCompleted = (face.leftEyeOpenProbability != null &&
                face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null &&
                face.rightEyeOpenProbability! < 0.3);
        break;
      case 'lookRight':
        actionCompleted =
            face.headEulerAngleY != null && face.headEulerAngleY! < -10;
        break;
      case 'lookLeft':
        actionCompleted =
            face.headEulerAngleY != null && face.headEulerAngleY! > 10;
        break;
    }

    if (actionCompleted) {
      // ✅ Capture image only once when smiling
      if (currentAction == 'smile' && smileImagePath == null) {
        await cameraController.stopImageStream();
        final picture = await cameraController.takePicture();
        final originalImage = File(picture.path).readAsBytesSync();
        img.Image decodedImage = img.decodeImage(originalImage)!;

// Flip the image horizontally
        img.Image flippedImage = img.flipHorizontal(decodedImage);

// Save the flipped image back
        final flippedImageFile = File(picture.path)
          ..writeAsBytesSync(img.encodeJpg(flippedImage));
        smileImagePath = flippedImageFile.path;
        await cameraController.startImageStream((CameraImage image) {
          if (!isDetecting) {
            isDetecting = true;
            detectFaces(image).then((_) => isDetecting = false);
          }
        });
      }

      currentActionIndex++;
      _fadeController.forward(from: 0);

      if (currentActionIndex >= challengeActions.length) {
        currentActionIndex = 0;
        await cameraController.stopImageStream();

        if (mounted && smileImagePath != null) {
          displaySnackBar(
              context,
              "Verification successful..!!!",
              Icons.check_circle,
              const Color(0xFFE6F4EA),
              const Color(0xFF2E7D32));

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SuccessPage(imagePath: smileImagePath!)),
          );

          if (mounted && result != null) {
            Navigator.pop(context, result);
          }
        }
      } else {
        waitingForNeutral = true;
      }
    }
  }

  bool isNeutralPosition(Face face) {
    return (face.smilingProbability == null ||
            face.smilingProbability! < 0.1) &&
        (face.leftEyeOpenProbability == null ||
            face.leftEyeOpenProbability! > 0.7) &&
        (face.rightEyeOpenProbability == null ||
            face.rightEyeOpenProbability! > 0.7) &&
        (face.headEulerAngleY == null ||
            (face.headEulerAngleY! > -10 && face.headEulerAngleY! < 10));
  }

  @override
  void dispose() {
    cameraController.stopImageStream();
    faceDetector.close();
    cameraController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(isFrontCamera ? math.pi : 0),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: cameraController.value.previewSize!.height,
                        height: cameraController.value.previewSize!.width,
                        child: CameraPreview(cameraController),
                      ),
                    ),
                  ),
                ),
                CustomPaint(painter: HeadMaskPainter(), child: Container()),

                // Challenge Card
                Positioned(
                  top: 85,
                  left: 44,
                  right: 44,
                  child: FadeTransition(
                    opacity: _fadeController
                        .drive(CurveTween(curve: Curves.easeInOut)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 1),
                        boxShadow: [
                          const BoxShadow(
                              color: Colors.black87,
                              blurRadius: 14,
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Please',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            getActionDescription(
                                    challengeActions[currentActionIndex])
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.amberAccent.shade400,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                    blurRadius: 5,
                                    color: Colors.amberAccent.shade700)
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Step ${currentActionIndex + 1} of ${challengeActions.length}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Stat Display
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                            'Smile',
                            smilingProbability != null
                                ? '${(smilingProbability! * 100).toStringAsFixed(0)}%'
                                : 'N/A',
                            Icons.tag_faces,
                            Colors.amberAccent),
                        _buildStatItem(
                            'Blink',
                            (leftEyeOpenProbability != null &&
                                    rightEyeOpenProbability != null)
                                ? '${(((leftEyeOpenProbability! + rightEyeOpenProbability!) / 2) * 100).toStringAsFixed(0)}%'
                                : 'N/A',
                            Icons.remove_red_eye,
                            Colors.cyanAccent),
                        _buildStatItem(
                            'Look',
                            headEulerAngleY != null
                                ? '${headEulerAngleY!.toStringAsFixed(0)}°'
                                : 'N/A',
                            Icons.screen_rotation,
                            Colors.lightGreenAccent),
                      ],
                    ),
                  ),
                ),

                // App Title
                const Positioned(
                  top: 45,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text("Verify Your Identity",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                                blurRadius: 14,
                                color: Colors.black87,
                                offset: Offset(0, 3))
                          ],
                        )),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.amberAccent)),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  String getActionDescription(String action) {
    switch (action) {
      case 'smile':
        return 'smile';
      case 'blink':
        return 'blink';
      case 'lookRight':
        return 'look right';
      case 'lookLeft':
        return 'look left';
      default:
        return '';
    }
  }
}

class HeadMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
