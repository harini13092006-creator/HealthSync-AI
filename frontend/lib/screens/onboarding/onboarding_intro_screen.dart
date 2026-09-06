import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'personal_info_screen.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, size: 44, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Personalized Planning,\nJust for You',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'HealthSync AI designs your day around your commitments, natural sleep rhythm, and wellness targets.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.4),
              ),
              const Spacer(),

              // Prominent Medical Safety Disclaimer (Section 40)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Amber Light
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Wellness & Habit System Notice',
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This application provides general wellness and habit-management recommendations and is not a substitute for professional medical advice, diagnosis, or treatment.',
                            style: TextStyle(
                              color: Color(0xFF78350F),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PersonalInfoScreen(onboardingData: {}),
                    ),
                  );
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
