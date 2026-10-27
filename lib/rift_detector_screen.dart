import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hawkins_frequency/ui_components.dart';

class RiftDetectorScreen extends StatefulWidget {
  const RiftDetectorScreen({super.key});

  @override
  State<RiftDetectorScreen> createState() => _RiftDetectorScreenState();
}

class _RiftDetectorScreenState extends State<RiftDetectorScreen> with TickerProviderStateMixin {
  final AudioPlayer _beepPlayer = AudioPlayer();
  StreamSubscription<MagnetometerEvent>? _magSubscription;

  
  double _currentMagnitude = 0.0;
  double _baseline = 0.0;
  bool _isCalibrating = true;
  List<double> _calibrationBuffer = [];
  
  
  double _needleAngle = 0.0;
  
  
  double _anomalyStrength = 0.0; 
  List<Offset> _distortions = [];
  late AnimationController _pulseController;
  Size _screenSize = const Size(400, 800);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _setupBeep();
    _startListening();
  }

  Future<void> _setupBeep() async {
    try {
      await _beepPlayer.setAsset('assets/audio/beep.mp3');
      await _beepPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  void _startListening() {
    _magSubscription = magnetometerEvents.listen((event) {
      if (!mounted) return;

      
      final rawMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      
      
      
      double heading = atan2(event.y, event.x) - pi/2; 

      if (_isCalibrating) {
        _calibrationBuffer.add(rawMagnitude);
        if (_calibrationBuffer.length > 50) {
          _baseline = _calibrationBuffer.reduce((a, b) => a + b) / _calibrationBuffer.length;
          setState(() => _isCalibrating = false);
        }
        return;
      }

      
      _currentMagnitude = (rawMagnitude * 0.1) + (_currentMagnitude * 0.9);
      
      
      
      _needleAngle = heading; 

      double deviation = (_currentMagnitude - _baseline).abs();
      double normalizedStrength = (deviation / 15.0).clamp(0.0, 1.0);

      setState(() {
        _anomalyStrength = normalizedStrength;
        if (_anomalyStrength > 0.3) {
           _handleDetection();
        }
      });
    });
  }

  void _handleDetection() {
    if (!_pulseController.isAnimating) {
      _pulseController.forward().then((_) => _pulseController.reset());
    }

    if (_beepPlayer.playerState.processingState == ProcessingState.ready || 
        _beepPlayer.playerState.processingState == ProcessingState.completed) {
       _beepPlayer.setSpeed(0.5 + (_anomalyStrength * 1.5)); 
       _beepPlayer.seek(Duration.zero);
       _beepPlayer.play();
    }

    _distortions.add(Offset(
      Random().nextDouble() * _screenSize.width, 
      Random().nextDouble() * _screenSize.height
    ));
    if (_distortions.length > 15) _distortions.removeAt(0);
  }

  @override
  void dispose() {
    _magSubscription?.cancel();
    _beepPlayer.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    
    Color statusColor;
    String statusText;

    if (_isCalibrating) {
      statusColor = Colors.yellow;
      statusText = "CALIBRATING...";
    } else if (_anomalyStrength > 0.7) {
      statusColor = Colors.red;
      statusText = "GATE FOUND!";
    } else if (_anomalyStrength > 0.3) {
      statusColor = Colors.orange;
      statusText = "SIGNAL DETECTED";
    } else {
      statusColor = Colors.green;
      statusText = "SCANNING...";
    }

    return CRTScreenEffect(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text('COMPASS TRACKER', style: Theme.of(context).textTheme.bodyLarge?.copyWith(letterSpacing: 2)), 
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: statusColor),
        ),
        body: Stack(
          children: [
            
            CustomPaint(painter: RadarGridPainter(), size: Size.infinite),

            
            ..._distortions.map((offset) => Positioned(
              left: offset.dx,
              top: offset.dy,
              child: Opacity(
                opacity: 0.6,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    boxShadow: [BoxShadow(color: statusColor, blurRadius: 10)],
                  ),
                ),
              ),
            )),

            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                  Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black,
                      border: Border.all(color: Colors.grey.shade800, width: 8),
                      boxShadow: [
                        BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 5),
                        const BoxShadow(color: Colors.black54, blurRadius: 10),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        
                        const Text("N", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)),
                        const Positioned(bottom: 10, child: Text("S", style: TextStyle(color: Colors.grey, fontSize: 14))),
                        const Positioned(left: 10, child: Text("W", style: TextStyle(color: Colors.grey, fontSize: 14))),
                        const Positioned(right: 10, child: Text("E", style: TextStyle(color: Colors.grey, fontSize: 14))),

                        
                        if (_isCalibrating)
                          const SizedBox(
                            width: 280, height: 280,
                            child: CircularProgressIndicator(color: Colors.yellow, strokeWidth: 1),
                          ),

                        
                        if (!_isCalibrating)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Container(
                            width: 100 + (200 * _anomalyStrength) + (50 * _pulseController.value),
                            height: 100 + (200 * _anomalyStrength) + (50 * _pulseController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: statusColor.withOpacity((1 - _pulseController.value).clamp(0.0, 1.0)),
                                width: 2
                              ),
                            ),
                          ),
                        ),

                        
                        if (!_isCalibrating)
                          Transform.rotate(
                            angle: _needleAngle,
                            alignment: Alignment.center,
                            child: CustomPaint(
                              size: const Size(40, 240),
                              painter: RetroNeedlePainter(color: statusColor),
                            ),
                          ),
                          
                        
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                            border: Border.all(color: Colors.black, width: 1)
                          ),
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      color: statusColor,
                      shadows: [Shadow(color: statusColor, blurRadius: 15)]
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  
                  Container(
                    width: 300,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700, width: 2),
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4)
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 296 * _anomalyStrength,
                          height: 20,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class RetroNeedlePainter extends CustomPainter {
  final Color color;
  RetroNeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    
    paint.color = Colors.red;
    final northPath = Path();
    northPath.moveTo(centerX, 0); 
    northPath.lineTo(centerX + 8, centerY); 
    northPath.lineTo(centerX - 8, centerY); 
    northPath.close();
    canvas.drawPath(northPath, paint);

    
    paint.color = Colors.white70;
    final southPath = Path();
    southPath.moveTo(centerX, size.height); 
    southPath.lineTo(centerX + 8, centerY); 
    southPath.lineTo(centerX - 8, centerY); 
    southPath.close();
    canvas.drawPath(southPath, paint);
    
    
    paint.color = Colors.black26;
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), paint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(old) => false;
}