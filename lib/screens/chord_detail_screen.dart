import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';

class ChordDetailScreen extends StatefulWidget {
  final String name;
  final String imageUrl;

  const ChordDetailScreen({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<ChordDetailScreen> createState() => _ChordDetailScreenState();
}

class _ChordDetailScreenState extends State<ChordDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime _lastShakeTime = DateTime.now();
  final double _shakeThreshold = 1.5;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _listenToShake();
  }

  void _listenToShake() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      double gX = event.x / 9.81;
      double gY = event.y / 9.81;
      double gZ = event.z / 9.81;
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > _shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inMilliseconds > 800) {
          _lastShakeTime = now;
          _playChordSound();
        }
      }
    });
  }

  Future<void> _playChordSound() async {
    String chord = widget.name.toLowerCase().replaceAll(" ", "_");
    List<String> accepted = [
      "a_major", "a_minor",
      "b_major", "b_minor",
      "c_major", "c_minor"
    ];

    String fileName = accepted.contains(chord) ? chord : "all";

    try {
      setState(() => _isPlaying = true);
      await _audioPlayer.play(AssetSource("audio/$fileName.mp3"));
      await Future.delayed(const Duration(seconds: 5));
      setState(() => _isPlaying = false);
    } catch (e) {
      debugPrint("Error playing audio: $e");
      setState(() => _isPlaying = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2196F3),
                Color(0xFF0D47A1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.black.withOpacity(0.45)),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isPlaying
                              ? const Color.fromARGB(255, 46, 143, 247)
                              : Colors.white24,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (_isPlaying)
                            BoxShadow(
                              color: const Color.fromARGB(255, 46, 143, 247).withOpacity(0.55),
                              blurRadius: 40,
                              spreadRadius: 6,
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Image.network(
                        widget.imageUrl,
                        height: 250,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, loading) =>
                            loading == null
                                ? child
                                : const CircularProgressIndicator(
                                    color: Colors.lightBlueAccent,
                                  ),
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white38,
                          size: 100,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 700),
                      opacity: _isPlaying ? 1 : 0.8,
                      child: Text(
                        _isPlaying
                            ? "Playing ${widget.name}..."
                            : "Shake your phone to play the chord!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isPlaying
                              ? Colors.lightBlueAccent
                              : Colors.white70,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            if (_isPlaying)
                              const Shadow(
                                color: Colors.lightBlueAccent,
                                blurRadius: 16,
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
        ],
      ),
    );
  }
}
