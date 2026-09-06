import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'lifestyle_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  final Map<String, dynamic> onboardingData;
  const PersonalInfoScreen({super.key, required this.onboardingData});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController(text: '22');
  final _heightController = TextEditingController(text: '168');
  final _weightController = TextEditingController(text: '62');

  double get _bmi {
    final h = double.tryParse(_heightController.text) ?? 170.0;
    final w = double.tryParse(_weightController.text) ?? 65.0;
    if (h <= 0) return 0.0;
    final hm = h / 100.0;
    return (w / (hm * hm));
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    final data = Map<String, dynamic>.from(widget.onboardingData);
    data['age'] = int.tryParse(_ageController.text) ?? 22;
    data['height'] = double.tryParse(_heightController.text) ?? 168.0;
    data['weight'] = double.tryParse(_weightController.text) ?? 62.0;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LifestyleScreen(onboardingData: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bmiVal = _bmi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LinearProgressIndicator(value: 1 / 6, color: AppColors.primary),
                const SizedBox(height: 24),
                const Text(
                  'About You',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'These metrics help us accurately calculate your daily hydration and calorie expenditure.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age (Years)',
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter age' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height_rounded),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter height' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Please enter weight' : null,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),

                // BMI preview card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Calculated BMI',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bmiVal.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            bmiVal < 18.5
                                ? 'Underweight'
                                : (bmiVal < 25 ? 'Normal Range' : 'Above Average'),
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _onNext,
                  child: const Text('Next: Lifestyle & Schedule'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
