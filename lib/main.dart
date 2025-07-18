import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vector_math/vector_math_64.dart' as vmath;

void main() => runApp(LuxRunAIApp());

class LuxRunAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LuxRun AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF101010),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFFFC107),
          secondary: Colors.amber,
        ),
        textTheme: const TextTheme(
          headline1: TextStyle(
              fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
          subtitle1: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ),
      home: RunScreen(),
    );
  }
}

class RunScreen extends StatefulWidget {
  @override
  _RunScreenState createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen>
    with SingleTickerProviderStateMixin {
  bool running = false;
  double distance = 0.0;
  Position? lastPos;
  Timer? timer;
  late FlutterTts tts;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    tts = FlutterTts()
      ..setLanguage("en-US")
      ..setSpeechRate(0.45)
      ..setPitch(1.1);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scaleAnim = Tween(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  void startRun() async {
    bool ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) return;
    LocationPermission perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) return;

    setState(() {
      running = true;
      distance = 0;
      lastPos = null;
    });

    tts.speak("Let’s go! I’m your AI buddy running with you.");

    timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      Position p =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (lastPos != null) {
        double d = Geolocator.distanceBetween(
          lastPos!.latitude,
          lastPos!.longitude,
          p.latitude,
          p.longitude,
        );
        setState(() => distance += d);
        if (distance > 0 && distance % 1000 < 10) {
          tts.speak("Nice! You've hit ${(distance / 1000).toStringAsFixed(1)} kilometers.");
        }
      }
      lastPos = p;
    });
  }

  void stopRun() {
    tts.speak("Run complete! Great work today!");
    timer?.cancel();
    setState(() => running = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: running ? stopRun : startRun,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: BackgroundPainter()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(distance / 1000).toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.headline1,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    running ? 'Running with AI Buddy...' : 'Tap to Start Your Run',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _scaleAnim,
                    builder: (ctx, child) {
                      return Transform.scale(
                        scale: _scaleAnim.value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFFFC107),
                            Color(0xFFFF9800),
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 30,
                            offset: Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        running ? Icons.stop : Icons.play_arrow,
                        size: 64,
                        color: Colors.grey[900],
                      ),
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

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 20; i++) {
      paint.color = Colors.grey.withOpacity(0.05 + (i * 0.02));
      double radius = size.width * (0.3 + i * 0.02);
      canvas.drawCircle(size.center(Offset.zero), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
