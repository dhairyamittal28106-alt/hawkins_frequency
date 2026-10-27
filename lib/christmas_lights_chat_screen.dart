import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart'; 
import 'package:hawkins_frequency/ui_components.dart';


const String _kAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

class ChristmasLightsChatScreen extends StatefulWidget {
  const ChristmasLightsChatScreen({super.key});

  @override
  State<ChristmasLightsChatScreen> createState() => _ChristmasLightsChatScreenState();
}

class _ChristmasLightsChatScreenState extends State<ChristmasLightsChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _chatHistory = []; 
  
  String _currentSpellingMessage = ""; 
  bool _isWillCommunicating = false;
  int? _activeLightIndex; 
  
  
  final AudioPlayer _lightOnPlayer = AudioPlayer();
  final AudioPlayer _lightOffPlayer = AudioPlayer();
  final Random _random = Random();

  final List<Color> _bulbColors = [
    const Color(0xFFFF0000), 
    const Color(0xFF00FF00), 
    const Color(0xFF0000FF), 
    const Color(0xFFFFD700), 
    const Color(0xFF800080), 
  ];

  @override
  void initState() {
    super.initState();
    _setupSounds();
    _startWillLoop();
  }

  Future<void> _setupSounds() async {
    
    try {
      await _lightOnPlayer.setAsset('assets/audio/light_on.mp3');
      await _lightOffPlayer.setAsset('assets/audio/light_off.mp3');
      await _lightOnPlayer.setVolume(1.0);
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  
  void _playSound(bool isOn) async {
    try {
      if (isOn) {
        await _lightOnPlayer.seek(Duration.zero);
        _lightOnPlayer.play();
      } else {
        await _lightOffPlayer.seek(Duration.zero);
        _lightOffPlayer.play();
      }
    } catch (_) {}
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _isWillCommunicating) return;
    
    setState(() {
      _chatHistory.add('YOU: $text');
    });
    _scrollToBottom();
    _flashAllLights();
    _controller.clear();
  }

  void _startWillLoop() {
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (_isWillCommunicating || !mounted) return;

      final possibleMessages = ['RUN', 'HERE', 'CLOSE GATE', 'COLD', 'HIDE', 'DEMOGORGON'];
      final message = possibleMessages[_random.nextInt(possibleMessages.length)];
      await _spellMessageFromWill(message);
    });
  }

  Future<void> _spellMessageFromWill(String message) async {
    setState(() {
      _isWillCommunicating = true;
      _currentSpellingMessage = ""; 
    });

    await Future.delayed(const Duration(seconds: 2));

    for (int i = 0; i < message.length; i++) {
      final char = message[i];
      final index = _kAlphabet.indexOf(char);

      if (index != -1) {
        
        if(mounted) {
          setState(() {
            _activeLightIndex = index;
            _currentSpellingMessage += char; 
          });
          _playSound(true);
        }
        
        await Future.delayed(const Duration(milliseconds: 800));

        
        if(mounted) {
          setState(() {
            _activeLightIndex = null;
          });
          _playSound(false);
        }
        
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if(mounted) {
      setState(() {
        _chatHistory.add('WILL: $message'); 
        _currentSpellingMessage = ""; 
        _isWillCommunicating = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _flashAllLights() async {
    for(int i=0; i<3; i++) {
       if(!mounted) return;
       setState(() => _activeLightIndex = -1);
       _playSound(true);
       await Future.delayed(const Duration(milliseconds: 100));
       setState(() => _activeLightIndex = null);
       await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _lightOnPlayer.dispose();
    _lightOffPlayer.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E2723), 
      appBar: AppBar(
        title: const Text("WILL'S WALL", style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          
          Positioned.fill(
            child: CustomPaint(
              painter: WallAndLightsPainter(
                activeLightIndex: _activeLightIndex,
                bulbColors: _bulbColors,
              ),
            ),
          ),

          
          SafeArea(
            child: Column(
              children: [
                
                Expanded(
                  flex: 5,
                  child: Center(
                    child: _isWillCommunicating
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentSpellingMessage,
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 8,
                                shadows: [Shadow(color: Colors.black, blurRadius: 40)],
                              ),
                            ),
                            const Text("RECEIVING SIGNAL...", style: TextStyle(color: Colors.redAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const SizedBox(),
                  ),
                ),

                
                Container(
                  height: 120,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    border: Border.all(color: Colors.white12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _chatHistory.length,
                    itemBuilder: (context, index) {
                      final msg = _chatHistory[index];
                      final isWill = msg.startsWith('WILL');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          msg,
                          style: TextStyle(
                            color: isWill ? Colors.redAccent : Colors.cyanAccent,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                          ),
                        ),
                      );
                    },
                  ),
                ),

                
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          enabled: !_isWillCommunicating,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: _isWillCommunicating ? 'PLEASE WAIT...' : 'ASK THE VOID...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.black87,
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      Container(
                        decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.cyanAccent),
                          onPressed: () => _sendMessage(_controller.text),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          
          const Positioned.fill(child: CRTScreenEffect(child: SizedBox())),
        ],
      ),
    );
  }
}


class WallAndLightsPainter extends CustomPainter {
  final int? activeLightIndex;
  final List<Color> bulbColors;

  WallAndLightsPainter({required this.activeLightIndex, required this.bulbColors});

  @override
  void paint(Canvas canvas, Size size) {
    
    final wirePaint = Paint()..color = const Color(0xFF1B5E20)..style = PaintingStyle.stroke..strokeWidth = 3;
    
    
    final lettersPerRow = 9;
    final hSpacing = size.width / (lettersPerRow + 1);
    final vSpacing = size.height * 0.12; 
    final startY = size.height * 0.15; 

    List<Offset> positions = [];
    for (int i = 0; i < _kAlphabet.length; i++) {
      int row = i ~/ lettersPerRow;
      int col = i % lettersPerRow;
      
      double dx = hSpacing * (col + 1) + (col % 2 == 0 ? 5 : -5);
      double dy = startY + (row * vSpacing) + (col % 2 == 0 ? 20 : -10);
      positions.add(Offset(dx, dy));
    }

    
    Path wirePath = Path();
    wirePath.moveTo(0, startY - 20);
    for (var pos in positions) {
      wirePath.quadraticBezierTo(pos.dx - 20, pos.dy - 30, pos.dx, pos.dy - 15);
    }
    wirePath.lineTo(size.width, positions.last.dy - 50);
    canvas.drawPath(wirePath, wirePaint);

    
    for (int i = 0; i < _kAlphabet.length; i++) {
      final pos = positions[i];
      final color = bulbColors[i % bulbColors.length];
      bool isOn = (activeLightIndex == -1) || (activeLightIndex == i);

      
      final textPainter = TextPainter(
        text: TextSpan(
          text: _kAlphabet[i], 
          style: TextStyle(
            color: Colors.black.withOpacity(0.8), 
            fontSize: 28, 
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace' 
          )
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(pos.dx - textPainter.width/2, pos.dy + 20));

      
      canvas.drawRect(Rect.fromCenter(center: Offset(pos.dx, pos.dy - 12), width: 8, height: 12), Paint()..color = Colors.green.shade900);

      
      final bulbPaint = Paint()..color = isOn ? color : color.withOpacity(0.3);
      
      
      if (isOn) {
        canvas.drawCircle(pos, 40, Paint()..color = color.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
        canvas.drawCircle(pos, 8, Paint()..color = Colors.white.withOpacity(0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
      
      
      canvas.drawOval(Rect.fromCenter(center: pos, width: 18, height: 28), bulbPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WallAndLightsPainter old) => old.activeLightIndex != activeLightIndex;
}