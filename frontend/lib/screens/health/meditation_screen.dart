import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_provider.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _sessions = [
    {
      'title': 'Box Breathing Focus',
      'subtitle': '4-4-4-4 rhythm for instant mental clarity',
      'duration': 5,
      'type': 'BREATHING',
      'color': AppColors.primary,
    },
    {
      'title': 'Mindful Body Scan',
      'subtitle': 'Systematic progressive relaxation and presence',
      'duration': 10,
      'type': 'MINDFULNESS',
      'color': AppColors.accent,
    },
    {
      'title': 'Sleep Wind-Down',
      'subtitle': 'Calm your nervous system before rest',
      'duration': 15,
      'type': 'SLEEP_PREP',
      'color': AppColors.sleep,
    },
    {
      'title': 'Micro Reset',
      'subtitle': '3-minute quick pause to reset cognitive overload',
      'duration': 3,
      'type': 'MICRO_BREAK',
      'color': AppColors.secondary,
    },
  ];

  int _selectedIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 300;
  bool _isRunning = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _sessions[_selectedIndex]['duration'] * 60;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _selectSession(int index) {
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _selectedIndex = index;
      _secondsRemaining = _sessions[index]['duration'] * 60;
      _isRunning = false;
    });
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _animController.stop();
      setState(() => _isRunning = false);
    } else {
      _animController.forward();
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          _animController.stop();
          setState(() => _isRunning = false);
          _completeSession();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _secondsRemaining = _sessions[_selectedIndex]['duration'] * 60;
      _isRunning = false;
    });
  }

  void _completeSession() async {
    final session = _sessions[_selectedIndex];
    final healthProvider = Provider.of<HealthProvider>(context, listen: false);
    await healthProvider.logMeditation(
      type: session['type'],
      duration: session['duration'],
      notes: 'Completed ${session['title']} session',
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session Complete ✨'),
        content: Text('You completed ${session['duration']} minutes of ${session['title']}. Mindful minutes logged!'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _resetTimer();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final session = _sessions[_selectedIndex];
    final color = session['color'] as Color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindfulness & Breathwork'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Guided Session Selector Carousel/Cards
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _sessions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final s = _sessions[index];
                  final isSelected = _selectedIndex == index;
                  final sColor = s['color'] as Color;
                  return GestureDetector(
                    onTap: () => _selectSession(index),
                    child: Container(
                      width: 170,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? sColor.withValues(alpha: 0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? sColor : AppColors.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.self_improvement, size: 18, color: sColor),
                              const SizedBox(width: 6),
                              Text(
                                '${s['duration']} min',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: sColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s['title'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            s['subtitle'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 36),

            // Animated Breathing Circle
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRunning ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: 0.25),
                          color.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.2),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_secondsRemaining),
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: color,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isRunning
                                  ? (_animController.status == AnimationStatus.forward
                                      ? 'Inhale...'
                                      : 'Exhale...')
                                  : 'Ready',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 28, color: AppColors.textSecondary),
                  onPressed: _resetTimer,
                  tooltip: 'Reset Timer',
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: _toggleTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(22),
                  ),
                  child: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 28, color: AppColors.success),
                  onPressed: _completeSession,
                  tooltip: 'Log Completed',
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Advice note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Find a quiet posture. Keep your gaze soft or eyes closed. Even 3 to 5 minutes recalibrates focus and reduces stress.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
