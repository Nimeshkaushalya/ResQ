import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:resq_flutter/data/first_aid_guide_data.dart';
import 'package:url_launcher/url_launcher.dart';

class FirstAidDetailScreen extends StatefulWidget {
  final FirstAidCategory category;

  const FirstAidDetailScreen({super.key, required this.category});

  @override
  State<FirstAidDetailScreen> createState() => _FirstAidDetailScreenState();
}

class _FirstAidDetailScreenState extends State<FirstAidDetailScreen> {
  int _currentStep = 0;

  void _nextStep() {
    if (_currentStep < widget.category.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _callEmergency() async {
    final Uri url =
        Uri(scheme: 'tel', path: '1990'); // 1990 is Suwa Seriya in Sri Lanka
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.category.steps[_currentStep];
    final bool isLastStep = _currentStep == widget.category.steps.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.category.title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Emergency Warning Strip
          if (widget.category.requiresEmergency)
            Container(
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertTriangle,
                      color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a severe medical emergency. Call for an ambulance immediately.',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  )
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step Indicator
                  Text(
                    'STEP ${_currentStep + 1} OF ${widget.category.steps.length}',
                    style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),

                  // Text Instruction
                  Text(
                    step.instruction,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                        height: 1.4),
                  ),
                  const SizedBox(height: 32),

                  // Image Viewer
                  if (step.imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        step.imagePath!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder('Image file missing in assets'),
                      ),
                    )
                  else
                    _buildPlaceholder('No illustration available'),
                  const SizedBox(height: 32),

                  // Render Dos and Don'ts only on last step
                  if (isLastStep) ...[
                    if (widget.category.dos.isNotEmpty)
                      _buildListSection(
                          'DO', widget.category.dos, Colors.green),
                    const SizedBox(height: 16),
                    if (widget.category.donts.isNotEmpty)
                      _buildListSection(
                          'DON\'T', widget.category.donts, Colors.red),
                  ]
                ],
              ),
            ),
          ),

          // Bottom Navigation Controls
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _currentStep > 0
                    ? TextButton.icon(
                        onPressed: _prevStep,
                        icon: const Icon(LucideIcons.arrowLeft),
                        label: const Text('Previous'),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700),
                      )
                    : const SizedBox(width: 100), // empty spacer

                if (isLastStep && widget.category.requiresEmergency)
                  ElevatedButton.icon(
                    onPressed: _callEmergency,
                    icon: const Icon(LucideIcons.phone),
                    label: const Text('Call 1990'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  )
                else if (!isLastStep)
                  ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Next Step'),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrowRight, size: 18)
                      ],
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  title == 'DO'
                      ? LucideIcons.checkCircle2
                      : LucideIcons.xCircle,
                  color: color,
                  size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 28),
                child: Text('• $item', style: const TextStyle(height: 1.4)),
              ))
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
