import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_provider.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _qualityRating = 4;
  bool _isLoading = false;

  double _calculateDuration() {
    int bedMinutes = _bedTime.hour * 60 + _bedTime.minute;
    int wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;

    if (wakeMinutes < bedMinutes) {
      wakeMinutes += 24 * 60;
    }
    return (wakeMinutes - bedMinutes) / 60.0;
  }

  void _submitSleep() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<HealthProvider>(context, listen: false);
    final duration = _calculateDuration();
    final ok = await provider.logSleep(
      duration: duration,
      qualityRating: _qualityRating,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ${duration.toStringAsFixed(1)} hours of sleep! Rest well 🌙'),
            backgroundColor: AppColors.sleep,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save sleep log.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _calculateDuration();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracking & Recovery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sleep Duration Summary Card
            Card(
              color: AppColors.sleep.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.sleep.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Icon(Icons.bedtime_rounded, size: 40, color: AppColors.sleep),
                    const SizedBox(height: 10),
                    Text(
                      '${duration.toStringAsFixed(1)} Hours',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sleep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duration >= 7.0 && duration <= 9.0
                          ? 'Optimal Restorative Duration'
                          : duration < 7.0
                              ? 'Short Sleep Window'
                              : 'Extended Recovery Window',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Time Selectors
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerCard(
                    title: 'Bedtime',
                    time: _bedTime,
                    icon: Icons.nightlight_round,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _bedTime,
                      );
                      if (picked != null) setState(() => _bedTime = picked);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTimePickerCard(
                    title: 'Wake Up',
                    time: _wakeTime,
                    icon: Icons.wb_sunny_rounded,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _wakeTime,
                      );
                      if (picked != null) setState(() => _wakeTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sleep Quality Rating
            const Text(
              'How was your sleep quality?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRatingButton(1, 'Poor', '😫'),
                _buildRatingButton(2, 'Fair', '🥱'),
                _buildRatingButton(3, 'Good', '🙂'),
                _buildRatingButton(4, 'Great', '😊'),
                _buildRatingButton(5, 'Deep', '🌟'),
              ],
            ),
            const SizedBox(height: 28),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitSleep,
              icon: const Icon(Icons.check),
              label: const Text('Save Sleep Log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sleep,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Consistency Advisory
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lightbulb_outline, color: AppColors.sleep),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Maintaining a consistent sleep and wake time within 30 minutes anchors your circadian rhythm and boosts your Daily Wellness Score.',
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

  Widget _buildTimePickerCard({
    required String title,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.sleep, size: 24),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(
              time.format(context),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingButton(int rating, String label, String emoji) {
    final isSelected = _qualityRating == rating;
    return GestureDetector(
      onTap: () => setState(() => _qualityRating = rating),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sleep.withValues(alpha: 0.15) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.sleep : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.sleep : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
