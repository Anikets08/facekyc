import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:facekyc/coordinates_calc.dart';
import 'package:facekyc/face_detection_camera.dart';
import 'package:facekyc/face_painter.dart';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

enum FaceStatus { perfect, warning, error, none }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _facePositionMessage;
  FaceStatus _faceStatus = FaceStatus.none;

  var _cameraLensDirection = CameraLensDirection.front;

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      final face = faces.first;
      final imageSize = inputImage.metadata?.size;

      if (imageSize != null) {
        // Calculate face size relative to image
        final faceWidth = face.boundingBox.width;
        final faceHeight = face.boundingBox.height;
        final imageArea = imageSize.width * imageSize.height;
        final faceArea = faceWidth * faceHeight;
        final faceRatio = faceArea / imageArea;

        bool rightEyeOpen =
            face.leftEyeOpenProbability != null &&
            face.leftEyeOpenProbability! > 0.85;
        bool leftEyeOpen =
            face.rightEyeOpenProbability != null &&
            face.rightEyeOpenProbability! > 0.85;
        final rotY = face.headEulerAngleY;

        // Calculate face position
        final faceCenterX =
            translateX(
              face.boundingBox.left,
              inputImage.metadata!.size,
              Size(faceWidth, faceHeight),
              inputImage.metadata!.rotation,
              _cameraLensDirection,
            ) +
            (faceWidth / 2);
        final faceCenterY =
            translateY(
              face.boundingBox.top,
              inputImage.metadata!.size,
              Size(faceWidth, faceHeight),
              inputImage.metadata!.rotation,
              _cameraLensDirection,
            ) +
            (faceHeight / 2);
        final imageCenter = imageSize.width / 2;
        final imageCenterY = imageSize.height / 2;
        final horizontalOffset = (faceCenterX - imageCenter) / imageSize.width;
        final verticalOffset = (faceCenterY - imageCenterY) / imageSize.height;
        bool movingHeadLeftOrRight = rotY != null && (rotY > 30 || rotY < -30);
        if (faces.length > 1) {
          _setFaceFeedback(
            '🙅🏻‍♂️ Multiple Faces Detected!',
            FaceStatus.error,
          );
        } else if (!rightEyeOpen && !leftEyeOpen && !movingHeadLeftOrRight) {
          _setFaceFeedback('🙅🏻‍♂️ both Eyes Closed!', FaceStatus.error);
        } else if (!leftEyeOpen && !movingHeadLeftOrRight) {
          _setFaceFeedback('🙅🏻‍♂️ left Eye Closed!', FaceStatus.error);
        } else if (!rightEyeOpen && !movingHeadLeftOrRight) {
          _setFaceFeedback('🙅🏻‍♂️ right Eye Closed!', FaceStatus.error);
        } else if (faceRatio > 0.4) {
          _setFaceFeedback('🙅🏻‍♂️ Too Close!', FaceStatus.error);
        } else if (faceRatio < 0.1) {
          _setFaceFeedback('🙅🏻‍♂️ Too Far!', FaceStatus.error);
        } else if (movingHeadLeftOrRight) {
          if (rotY >= 45) {
            if (rotY > 60) {
              _setFaceFeedback(
                "Head turned too much to the left",
                FaceStatus.error,
              );
            } else {
              _setFaceFeedback(
                "Head turned 45 degrees or more to the left",
                FaceStatus.perfect,
              );
            }
          } else if (rotY <= -45) {
            if (rotY < -60) {
              _setFaceFeedback(
                "Head turned too much to the right",
                FaceStatus.error,
              );
            } else {
              _setFaceFeedback(
                "Head turned 45 degrees or more to the right",
                FaceStatus.perfect,
              );
            }
          }
        } else if (horizontalOffset > 0.35) {
          _setFaceFeedback(
            '⚠️ Doable, but would be great if you could move a bit to Left',
            FaceStatus.warning,
          );
        } else if (horizontalOffset < -0.15) {
          _setFaceFeedback(
            '⚠️ Doable, but would be great if you could move a bit to right',
            FaceStatus.warning,
          );
        } else if (verticalOffset > 1.75) {
          _setFaceFeedback(
            '⚠️ Doable, but please move a bit upwards',
            FaceStatus.warning,
          );
        } else if (verticalOffset < 1.0) {
          _setFaceFeedback(
            '⚠️ Doable, but please move a bit downwards',
            FaceStatus.warning,
          );
        } else {
          _setFaceFeedback('👌🏻 Perfect Position!', FaceStatus.perfect);
        }
      }
    } else {
      _facePositionMessage = 'No Face Detected!';
      _faceStatus = FaceStatus.none;
    }

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = FaceDetectorPainter(
        faces,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      _customPaint = null;
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _setFaceFeedback(String message, FaceStatus status) {
    _facePositionMessage = message;
    _faceStatus = status;
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraView(
            customPaint: _customPaint,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged:
                (value) => _cameraLensDirection = value,
            faceStatus: _faceStatus,
          ),
          if (_facePositionMessage != null)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color:
                      _faceStatus == FaceStatus.perfect
                          ? Colors.green.withAlpha(50)
                          : _faceStatus == FaceStatus.warning
                          ? Colors.orange.withAlpha(50)
                          : _faceStatus == FaceStatus.error
                          ? Colors.red.withAlpha(50)
                          : Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _facePositionMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
