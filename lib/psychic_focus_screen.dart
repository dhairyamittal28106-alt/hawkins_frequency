import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hawkins_frequency/ui_components.dart';
import 'energy_manager.dart';

class PsychicFocusScreen extends StatefulWidget {
  const PsychicFocusScreen({super.key});

  @override
  State<PsychicFocusScreen> createState() => _PsychicFocusScreenState();
}

class _PsychicFocusScreenState extends State<PsychicFocusScreen> with TickerProviderStateMixin {
  CameraController? _controller;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
      enableTracking: true,
    ),
  );
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isDetecting = false;
  double _focusProgress = 0.0;
  Point<int>? _lastNosePos;
  bool _faceFound = false;
  bool _isShaky = false;
  bool _hasNosebleed = false; // State to track if effect is active
  
  late AnimationController _shakeController;
  late AnimationController _recordBlinker;
  
  // New Blood Logic: Single Stream
  Offset? _nosePosition;
  double _dripLength = 0.0;

  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _recordBlinker = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _requestPermissionsAndInit();
    _setupAudio();
  }

  Future<void> _requestPermissionsAndInit() async {
    final cameraStatus = await Permission.camera.request();
    if (cameraStatus.isGranted) {
      await _initCamera();
      setState(() => _hasPermission = true);
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    if (mounted) {
      _controller!.startImageStream(_processCameraImage);
      setState(() {});
    }
  }

  Future<void> _setupAudio() async {
    try {
        await _audioPlayer.setAsset('assets/audio/psychic_hum.mp3');
        _audioPlayer.setLoopMode(LoopMode.all);
        _audioPlayer.setVolume(0.0);
        _audioPlayer.play();
    } catch(e) {}
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting || !mounted) return;
    _isDetecting = true;

    if (EnergyManager.energy <= 10) {
      if (_focusProgress > 0) setState(() { _focusProgress = 0.0; _audioPlayer.setVolume(0.0); });
      _isDetecting = false;
      return; 
    }

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      _isDetecting = false;
      return;
    }

    final faces = await _faceDetector.processImage(inputImage);
    
    if (faces.isNotEmpty) {
      final face = faces.first;
      final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;

      if (noseBase != null) {
        if (_lastNosePos != null) {
          double dx = (noseBase.x - _lastNosePos!.x).abs().toDouble();
          double dy = (noseBase.y - _lastNosePos!.y).abs().toDouble();
          double movement = sqrt(dx*dx + dy*dy);

          if (movement < 20.0) {
             _focusProgress += 0.02; 
             _isShaky = false;
          } else {
             _focusProgress -= 0.04; 
             _isShaky = true;
          }
        }
        _lastNosePos = noseBase;
        _focusProgress = _focusProgress.clamp(0.0, 1.0);

        // Update Coordinates for painting
        _updateNoseCoordinates(noseBase);

        if (mounted) {
          setState(() {
            _faceFound = true;
            _audioPlayer.setVolume(_focusProgress); 
            _audioPlayer.setPitch(1.0 + (_focusProgress * 1.5)); 
            
            // Trigger logic
            if (_focusProgress >= 0.95) {
              if (!_hasNosebleed && EnergyManager.energy > 10) {
                 EnergyManager.consume(10);
                 _hasNosebleed = true;
                 _shakeController.repeat(reverse: true);
              }
              // Grow the drip if active
              if (_hasNosebleed) {
                _dripLength = (_dripLength + 2.0).clamp(0.0, 60.0); // Max length 60px (short)
              }
            } else {
               // If focus lost, reset slowly
               _hasNosebleed = false;
               _dripLength = 0.0;
               _shakeController.stop();
            }
          });
        }
      }
    } else {
      setState(() {
        _faceFound = false;
        _focusProgress = 0.0;
        _hasNosebleed = false;
        _dripLength = 0.0;
        _audioPlayer.setVolume(0.0);
      });
      _shakeController.stop();
    }

    _isDetecting = false;
  }

  void _updateNoseCoordinates(Point<int> nose) {
    if(_controller == null) return;
    final size = MediaQuery.of(context).size;
    final double scaleX = size.width / _controller!.value.previewSize!.height;
    final double scaleY = size.height / _controller!.value.previewSize!.width;
    
    final double noseX = size.width - (nose.x * scaleX); 
    final double noseY = nose.y * scaleY;
    
    // Shift slightly to the RIGHT nostril (user's left) for authenticity
    _nosePosition = Offset(noseX - 10, noseY); 
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final int totalBytes = image.planes.fold<int>(0, (sum, plane) => sum + plane.bytes.length);
    final Uint8List allBytes = Uint8List(totalBytes);
    int offset = 0;
    for (final plane in image.planes) {
      allBytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
      offset += plane.bytes.length;
    }
    final bytes = allBytes;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final rotation = InputImageRotationValue.fromRawValue(_controller!.description.sensorOrientation) ?? InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
    return InputImage.fromBytes(bytes: bytes, metadata: InputImageMetadata(size: size, rotation: rotation, format: format, bytesPerRow: image.planes.first.bytesPerRow));
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    _audioPlayer.dispose();
    _shakeController.dispose();
    _recordBlinker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) return const SizedBox();

    return CRTScreenEffect(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: CameraPreview(_controller!),
              ),

            // UI OVERLAY
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         AnimatedBuilder(
                            animation: _recordBlinker,
                            builder: (_,__) => Opacity(
                              opacity: _recordBlinker.value,
                              child: const Text("REC", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 24)),
                            ),
                          ),
                          Text(
                            EnergyManager.energy <= 10 ? "LOW ENERGY" : "READY", 
                            style: TextStyle(
                              color: EnergyManager.energy <= 10 ? Colors.red : Colors.green, 
                              fontFamily: 'monospace', 
                              fontSize: 20
                            )
                          ),
                      ],
                    ),

                    // RETICLE (Disappears when nosebleed starts)
                    // This fixes your request: "Circle should go away"
                    if (_faceFound && EnergyManager.energy > 10 && !_hasNosebleed)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 200, height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color.lerp(Colors.white30, Colors.red, _focusProgress)!,
                                width: 2 + (_focusProgress * 8)
                              )
                            ),
                            child: Center(
                              child: _focusProgress > 0.8 
                                ? const Icon(Icons.psychology, color: Colors.red, size: 50)
                                : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_isShaky)
                            Text("TOO SHAKY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20, shadows: [Shadow(color: Colors.black, blurRadius: 4)]))
                          else if (_focusProgress > 0.1)
                            Text("HOLD STILL...", style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 5))
                        ],
                      ),
                    ),

                    // Bottom Text always visible
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("SUBJ: 011", style: Theme.of(context).textTheme.bodyLarge),
                        Text(
                          "ENERGY: ${EnergyManager.energy}%", 
                          style: TextStyle(
                            color: EnergyManager.energy <= 10 ? Colors.red : Colors.cyanAccent, 
                            fontFamily: 'monospace',
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            
            // THE NEW BLOOD PAINTER
            if (_nosePosition != null)
              CustomPaint(
                painter: ElevenNosebleedPainter(
                  startPos: _nosePosition!, 
                  length: _dripLength
                ),
                size: MediaQuery.of(context).size,
              ),
          ],
        ),
      ),
    );
  }
}

// 🎨 NEW PAINTER: Looks like a single thick dark stream
class ElevenNosebleedPainter extends CustomPainter {
  final Offset startPos;
  final double length;

  ElevenNosebleedPainter({required this.startPos, required this.length});

  @override
  void paint(Canvas canvas, Size size) {
    if (length <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // 1. Dark Coagulated Blood Color (Realism)
    final bloodColor = const Color(0xFF4A0000); // Deep Dark Red
    final highlightColor = const Color(0xFF800000); // Lighter red for shine

    final path = Path();
    
    // Create a tapered trickle shape
    path.moveTo(startPos.dx, startPos.dy);
    // Left side of stream
    path.lineTo(startPos.dx - 3, startPos.dy + length * 0.5);
    path.lineTo(startPos.dx - 2, startPos.dy + length);
    // Bottom rounded tip
    path.quadraticBezierTo(startPos.dx, startPos.dy + length + 5, startPos.dx + 2, startPos.dy + length);
    // Right side of stream
    path.lineTo(startPos.dx + 3, startPos.dy + length * 0.5);
    path.lineTo(startPos.dx + 4, startPos.dy); // Slightly wider at base (nostril)
    path.close();

    // Draw Main Blood
    canvas.drawPath(path, paint..color = bloodColor);

    // Draw Shine (Wet look)
    final shinePath = Path();
    shinePath.moveTo(startPos.dx + 1, startPos.dy + 5);
    shinePath.lineTo(startPos.dx + 1, startPos.dy + length - 5);
    canvas.drawPath(shinePath, paint..color = highlightColor..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant ElevenNosebleedPainter old) => 
      old.length != length || old.startPos != startPos;
}