import 'package:flutter/material.dart';
import '../../domain/emergency_voice_interview_questions.dart';

class CategoryChipGrid extends StatelessWidget {
  final bool isEnabled;
  final void Function(String) onCategoryChosen;

  const CategoryChipGrid({
    super.key,
    required this.isEnabled,
    required this.onCategoryChosen,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: EmergencyVoiceInterviewQuestions.situationTypeOptions.map((
        label,
      ) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? () => onCategoryChosen(label) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
