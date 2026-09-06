import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/health_provider.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _addWater(int amount) async {
    final provider = Provider.of<HealthProvider>(context, listen: false);
    final ok = await provider.logWater(amount);
    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added +$amount ml of water! Stay hydrated 💧'),
          backgroundColor: AppColors.info,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCustomWaterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Water Intake'),
        content: TextField(
          controller: _customController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Milliliters (ml)',
            hintText: 'e.g. 350',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(_customController.text.trim());
              if (val != null && val > 0) {
                Navigator.of(ctx).pop();
                _customController.clear();
                _addWater(val);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);
    final current = healthProvider.waterCurrentMl;
    final target = healthProvider.waterTargetMl;
    final pct = (current / (target > 0 ? target : 2500)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydration Tracking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Big Circular Gauge
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 170,
                          height: 170,
                          child: CircularProgressIndicator(
                            value: pct,
                            strokeWidth: 14,
                            backgroundColor: AppColors.info.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.info),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.water_drop_rounded, size: 36, color: AppColors.info),
                            const SizedBox(height: 6),
                            Text(
                              '$current',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'of $target ml',
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      pct >= 1.0
                          ? '🎉 Daily Hydration Target Reached!'
                          : '${((1.0 - pct) * target).toInt()} ml needed to reach goal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: pct >= 1.0 ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Add Buttons
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildQuickAddCard(
                  amount: 250,
                  label: 'Glass',
                  icon: Icons.local_drink_rounded,
                  onTap: () => _addWater(250),
                ),
                const SizedBox(width: 12),
                _buildQuickAddCard(
                  amount: 500,
                  label: 'Bottle',
                  icon: Icons.water_drop_rounded,
                  onTap: () => _addWater(500),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildQuickAddCard(
                  amount: 750,
                  label: 'Large Bottle',
                  icon: Icons.sports_bar_rounded,
                  onTap: () => _addWater(750),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _showCustomWaterDialog,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                          SizedBox(height: 6),
                          Text(
                            'Custom',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          Text('Enter ml', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tips Note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.tips_and_updates_outlined, color: AppColors.info),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Drinking water consistently throughout the day promotes focus, energy, and muscle recovery. HealthSync reminds you evenly across work hours.',
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

  Widget _buildQuickAddCard({
    required int amount,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.info, size: 28),
              const SizedBox(height: 6),
              Text(
                '+$amount ml',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
