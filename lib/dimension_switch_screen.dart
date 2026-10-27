import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart'; 
import 'package:hawkins_frequency/energy_manager.dart';
import 'package:hawkins_frequency/psychic_focus_screen.dart';
import 'package:hawkins_frequency/rift_detector_screen.dart';
import 'package:hawkins_frequency/christmas_lights_chat_screen.dart';
import 'package:hawkins_frequency/ui_components.dart';

class DimensionSwitchScreen extends StatefulWidget {
  const DimensionSwitchScreen({super.key});

  @override
  State<DimensionSwitchScreen> createState() => _DimensionSwitchScreenState();
}

class _DimensionSwitchScreenState extends State<DimensionSwitchScreen> with TickerProviderStateMixin {
  bool isUpsideDown = false;
  
  late AnimationController _flickerController;
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late AnimationController _bikeController;
  late AnimationController _hopperController;
  late AnimationController _borderController; 

  final List<Spore> _spores = [];
  Timer? _toxicityTimer;
  double _toxicityLevel = 0.0;
  double _parallaxX = 0.0;
  StreamSubscription? _gyroSubscription;

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 50));
    _bikeController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _hopperController = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    
    
    _borderController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    Timer.periodic(const Duration(seconds: 20), (_) {
      if (!isUpsideDown && mounted && Random().nextBool()) {
        _hopperController.forward().then((_) => _hopperController.reset());
      }
    });

    _startGyroscope();
  }

  void _startGyroscope() {
    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        _parallaxX += event.y * 2; 
        _parallaxX = _parallaxX.clamp(-50.0, 50.0);
      });
    });
  }

  void _generateSpores() {
    if (_spores.length > 60) return;
    final random = Random();
    int count = _toxicityLevel > 0.5 ? 8 : 2;
    for (int i = 0; i < count; i++) _spores.add(Spore(random: random));
  }

  void _toggleDimension() {
    if (!isUpsideDown && EnergyManager.energy <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ ENERGY DEPLETED. EAT AN EGGO.", style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)), backgroundColor: Colors.red)
      );
      _shakeController.forward().then((_) => _shakeController.reset());
      return; 
    }

    setState(() => isUpsideDown = !isUpsideDown);

    if (isUpsideDown) {
      _flickerController.repeat(reverse: true);
      
      _borderController.duration = const Duration(milliseconds: 300);
      _borderController.repeat(reverse: true);
      _startToxicity();
    } else {
      _flickerController.stop();
      _flickerController.value = 1.0;
      
      _borderController.duration = const Duration(seconds: 3);
      _borderController.repeat(reverse: true);
      _stopToxicity();
    }
  }

  void _startToxicity() {
    _toxicityLevel = 0.0;
    _toxicityTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _toxicityLevel += 0.005; 
        if (timer.tick % 10 == 0) EnergyManager.consume(1);
        if (_toxicityLevel > 0.7 && !_shakeController.isAnimating) _shakeController.repeat(reverse: true);
        if (_toxicityLevel >= 1.0 || EnergyManager.energy <= 0) _emergencyExit();
      });
    });
  }

  void _stopToxicity() {
    _toxicityTimer?.cancel();
    setState(() { _toxicityLevel = 0.0; _shakeController.stop(); });
  }

  void _emergencyExit() {
    _stopToxicity();
    setState(() {
      isUpsideDown = false;
      
      _borderController.duration = const Duration(seconds: 3);
      _borderController.repeat(reverse: true);
    });
    showDialog(context: context, barrierColor: Colors.transparent, builder: (_) => Container(color: Colors.red.withOpacity(0.8)));
    Future.delayed(const Duration(milliseconds: 200), () => Navigator.pop(context));
  }

  void _eatEggo() async {
    await EnergyManager.recharge(100);
    setState(() {});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🧇 EGGO EATEN! POWER RESTORED.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)), backgroundColor: Colors.amber));
  }

  @override
  void dispose() {
    _flickerController.dispose(); _pulseController.dispose(); _shakeController.dispose();
    _bikeController.dispose(); _hopperController.dispose(); _borderController.dispose();
    _toxicityTimer?.cancel(); _gyroSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isUpsideDown) _generateSpores();
    final size = MediaQuery.of(context).size;
    final bool hasEnergy = EnergyManager.energy > 0;

    return CRTScreenEffect(
      
      child: AnimatedBuilder(
        animation: _borderController,
        builder: (context, child) {
          Color borderColor = isUpsideDown ? const Color(0xFF800000) : const Color(0xFF00FFC5);
          double width = isUpsideDown ? 12.0 : 8.0; 
          
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor.withOpacity(0.4 + (_borderController.value * 0.6)),
                width: width
              )
            ),
            child: child,
          );
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              double offset = (isUpsideDown && _toxicityLevel > 0.7) || (!isUpsideDown && _shakeController.isAnimating) ? sin(_shakeController.value * pi * 3) * 10 : 0;
              return Transform.translate(offset: Offset(offset, 0), child: child);
            },
            child: Stack(
              children: [
                AnimatedContainer(duration: const Duration(seconds: 1), decoration: BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.2, colors: isUpsideDown ? [Color.lerp(const Color(0xFF1a1a2e), const Color(0xFF800000), _toxicityLevel)!, Colors.black] : [const Color(0xFF0D1b2a), Colors.black]))),
                
                if (!isUpsideDown) ...[
                  Positioned(bottom: 0, left: _parallaxX, child: CustomPaint(size: Size(size.width + 100, 250), painter: ForestSilhouettePainter())),
                  
                  
                  AnimatedBuilder(
                    animation: _bikeController, 
                    builder: (context, child) { 
                      final dx = size.width + 200 - (_bikeController.value * (size.width + 400)); 
                      return Positioned(
                        top: size.height * 0.20, 
                        left: dx, 
                        child: CustomPaint(painter: KidsOnBikesPainter(), size: const Size(130, 60))
                      ); 
                    }
                  ),
                  
                  
                  AnimatedBuilder(
                    animation: _hopperController, 
                    builder: (context, child) { 
                      final dx = -200 + (_hopperController.value * (size.width + 400)); 
                      return Positioned(
                        bottom: 360, 
                        left: dx, 
                        child: HopperCruiserWidget()
                      ); 
                    }
                  ),
                ],

                if (isUpsideDown) ...[
                  CustomPaint(painter: SporePainter(_spores), size: size),
                  CustomPaint(painter: VeinsPainter(toxicity: _toxicityLevel), size: size),
                  IgnorePointer(child: AnimatedContainer(duration: const Duration(milliseconds: 500), decoration: BoxDecoration(gradient: RadialGradient(radius: 1.5 - (_toxicityLevel * 0.5), colors: [Colors.transparent, Colors.red.withOpacity(_toxicityLevel * 0.6)], stops: const [0.5, 1.0])))),
                ],

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            AnimatedBuilder(animation: _flickerController, builder: (context, child) => Opacity(opacity: isUpsideDown ? (0.7 + Random().nextDouble() * 0.3) : 1.0, child: Text(isUpsideDown ? 'THE UPSIDE DOWN' : 'HAWKINS, 1985', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 46, height: 1.0, color: isUpsideDown ? const Color(0xFFE71D36) : const Color(0xFF00FFC5), shadows: [Shadow(color: isUpsideDown ? Colors.red : Colors.cyan, blurRadius: 20)])))),
                            Padding(padding: const EdgeInsets.only(top: 8), child: Text(isUpsideDown ? (_toxicityLevel > 0.8 ? "RUN! IT'S HERE!" : "AIR TOXICITY: ${(_toxicityLevel * 100).toInt()}%") : "STATUS: PEACEFUL NIGHT", style: TextStyle(color: isUpsideDown ? (_toxicityLevel > 0.8 ? Colors.red : Colors.grey) : Colors.cyanAccent, letterSpacing: 3, fontWeight: FontWeight.bold, fontSize: 14))),
                          ],
                        ),
                        
                        Expanded(
                          child: Center(
                            child: GestureDetector(
                              onTap: _toggleDimension,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: 170, height: 170,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withOpacity(0.5), border: Border.all(color: isUpsideDown ? const Color(0xFF880000) : (hasEnergy ? const Color(0xFF004455) : Colors.grey.shade900), width: 4), boxShadow: [BoxShadow(color: isUpsideDown ? Colors.red.withOpacity(0.6) : (hasEnergy ? Colors.cyan.withOpacity(0.4) : Colors.transparent), blurRadius: 40, spreadRadius: 5)]),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if(isUpsideDown) CircularProgressIndicator(color: Colors.red, strokeWidth: 3, value: _toxicityLevel),
                                    Icon(isUpsideDown ? Icons.sick : Icons.public, size: 80, color: isUpsideDown ? Colors.red : (hasEnergy ? Colors.cyan : Colors.grey.shade800)),
                                    Positioned(bottom: 30, child: Text(isUpsideDown ? "CLOSE GATE" : (hasEnergy ? "OPEN GATE" : "LOW ENERGY"), style: TextStyle(fontWeight: FontWeight.bold, color: isUpsideDown ? Colors.red : (hasEnergy ? Colors.cyan : Colors.red), letterSpacing: 2, fontSize: 12)))
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        Column(
                          children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), decoration: BoxDecoration(border: Border.all(color: Colors.white24), color: Colors.black54, borderRadius: BorderRadius.circular(30)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.bolt, color: Colors.yellow), const SizedBox(width: 10), Text('ENERGY: ${EnergyManager.energy}%', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: EnergyManager.energy < 30 ? Colors.red : Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5))])),
                            const SizedBox(height: 20),
                            NeonButton(text: 'TELEKINESIS TEST', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PsychicFocusScreen())), isDestructive: true),
                            const SizedBox(height: 10),
                            NeonButton(text: 'EMF DETECTOR', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RiftDetectorScreen()))),
                            const SizedBox(height: 10),
                            NeonButton(text: 'WALL COMMUNICATOR', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChristmasLightsChatScreen()))),
                            const SizedBox(height: 15),
                            NeonButton(text: 'EAT EGGO (RECHARGE)', onPressed: _eatEggo),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class HopperCruiserWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [Row(mainAxisSize: MainAxisSize.min, children: [_FlashLight(color: Colors.red), const SizedBox(width: 20), _FlashLight(color: Colors.blue)]), Container(width: 120, height: 40, decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))), child: const Center(child: Text("HAWKINS POLICE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown)))), Row(children: [const SizedBox(width: 15), Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)), const SizedBox(width: 50), Container(width: 20, height: 20, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))])]);
  }
}
class _FlashLight extends StatefulWidget { final Color color; const _FlashLight({required this.color}); @override State<_FlashLight> createState() => _FlashLightState(); }
class _FlashLightState extends State<_FlashLight> with SingleTickerProviderStateMixin { late AnimationController _c; @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 200))..repeat(reverse: true); } @override void dispose() { _c.dispose(); super.dispose(); } @override Widget build(BuildContext context) { return AnimatedBuilder(animation: _c, builder: (_,__) => Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.color.withOpacity(_c.value), shape: BoxShape.circle, boxShadow: [BoxShadow(color: widget.color, blurRadius: 10 * _c.value)]))); } }

class KidsOnBikesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    _drawBike(canvas, paint, const Offset(0, 50), true);
    _drawBike(canvas, paint, const Offset(50, 60), false);
    _drawBike(canvas, paint, const Offset(100, 40), true);
  }
  void _drawBike(Canvas canvas, Paint paint, Offset pos, bool hasCape) {
    canvas.drawCircle(Offset(pos.dx, pos.dy), 6, paint); canvas.drawCircle(Offset(pos.dx + 16, pos.dy), 6, paint);
    paint.strokeWidth = 2; paint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(pos.dx, pos.dy), Offset(pos.dx + 8, pos.dy - 10), paint); canvas.drawLine(Offset(pos.dx + 16, pos.dy), Offset(pos.dx + 8, pos.dy - 10), paint); canvas.drawLine(Offset(pos.dx + 8, pos.dy - 10), Offset(pos.dx + 16, pos.dy - 16), paint);
    paint.style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset(pos.dx + 8, pos.dy - 12), width: 8, height: 12), paint); canvas.drawCircle(Offset(pos.dx + 10, pos.dy - 20), 4, paint);
    if (hasCape) { final path = Path(); path.moveTo(pos.dx + 6, pos.dy - 16); path.lineTo(pos.dx - 10, pos.dy - 20); path.lineTo(pos.dx - 6, pos.dy - 12); path.close(); canvas.drawPath(path, paint); }
  }
  @override bool shouldRepaint(old) => false;
}

class ForestSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF050505);
    final path = Path()..moveTo(0, size.height)..lineTo(0, size.height - 50);
    for(double i=0; i<=size.width; i+=10) { path.lineTo(i, size.height - (30 + Random(i.toInt()).nextDouble() * 60)); }
    path.lineTo(size.width, size.height); path.close(); canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(old) => false;
}

class VeinsPainter extends CustomPainter {
  final double toxicity; VeinsPainter({required this.toxicity});
  @override void paint(Canvas canvas, Size size) {
    if (toxicity <= 0.1) return;
    final paint = Paint()..color = const Color(0xFF4A0000).withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    final r = Random(42);
    for (var start in [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)]) {
      int branches = (toxicity * 10).toInt();
      for (int i = 0; i < branches; i++) {
        final path = Path()..moveTo(start.dx, start.dy);
        double angle = atan2((size.height/2) - start.dy, (size.width/2) - start.dx) + (r.nextDouble() - 0.5);
        double cur = 0, max = (size.width * 0.6) * toxicity, x = start.dx, y = start.dy;
        while (cur < max) { double l = r.nextDouble()*20+10, a = angle + (r.nextDouble()-0.5); x += cos(a)*l; y += sin(a)*l; path.lineTo(x, y); cur += l; }
        canvas.drawPath(path, paint..strokeWidth = 4 * (1 - (cur / (size.width * 0.8))));
      }
    }
  }
  @override bool shouldRepaint(covariant VeinsPainter old) => old.toxicity != toxicity;
}

class Spore {
  late double x, y, size, speed, opacity, drift;
  Spore({required Random random}) { x = random.nextDouble()*2-1; y = 1.2; size = random.nextDouble()*4+1; speed = random.nextDouble()*0.2+0.05; opacity = random.nextDouble()*0.5+0.2; drift = (random.nextDouble()-0.5)*0.002; }
  void update(double height) { y -= speed * 0.01; x += drift; if (y < -0.2) y = 1.2; }
}
class SporePainter extends CustomPainter {
  final List<Spore> spores; SporePainter(this.spores);
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var s in spores) { s.update(size.height); paint.color = Colors.white.withOpacity(s.opacity); paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); canvas.drawCircle(Offset((s.x+1)/2*size.width, (1-s.y)*size.height), s.size, paint); }
  }
  @override bool shouldRepaint(old) => true;
}