import 'package:flutter/material.dart';
import 'dart:math' as math;

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AnimatedLogo(),
            const SizedBox(height: 30),
            const Text(
              'GEARSHARE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C4B7C), 
                letterSpacing: 2,
              ),
            ),
            const Text(
              'Smart Peer-to-Peer Equipment Rental',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/signin');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE87C31), 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(); 
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // The background network/grid circle
        Opacity(
          opacity: 0.3,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi * -0.2,
                child: const Icon(
                  Icons.blur_circular,
                  size: 220,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),

        
        Container(
          width: 160,
          height: 160,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: AssetImage('lib/png/logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),

        
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: const Icon(
                Icons.build,
                color: Color(0xFFE87C31),
                size: 50,
              ),
            );
          },
        ),
      ],
    );
  }
}
