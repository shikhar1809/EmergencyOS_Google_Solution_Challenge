import '../domain/lifeline_training_levels.dart';

/// Full Lifeline curriculum as plain text for AI / LiveKit context (all incidents/topics).
abstract final class LifelineCurriculumDigest {
  static String? _cached;

  /// Builds once per isolate; curriculum is static.
  static String build() {
    return _cached ??= _compute();
  }

  static String _compute() {
    final b = StringBuffer();
    b.writeln('EmergencyOS Lifeline training curriculum (all topics).');
    b.writeln();
    for (final level in kLifelineTrainingLevels) {
      b.writeln('--- Level ${level.id}: ${level.title} ---');
      b.writeln('Subtitle: ${level.subtitle}');
      if (level.redFlags.isNotEmpty) {
        b.writeln('Red flags:');
        for (final x in level.redFlags) {
          b.writeln('- $x');
        }
      }
      if (level.cautions.isNotEmpty) {
        b.writeln('Cautions:');
        for (final x in level.cautions) {
          b.writeln('- $x');
        }
      }
      if (level.infographic.isNotEmpty) {
        b.writeln('Steps:');
        for (final step in level.infographic) {
          b.writeln('- ${step.headline}: ${step.detail}');
        }
      }
      b.writeln('Quiz: ${level.quiz.question}');
      for (var i = 0; i < level.quiz.choices.length; i++) {
        b.writeln('  ${i + 1}. ${level.quiz.choices[i]}');
      }
      b.writeln();
    }
    var s = b.toString();
    if (s.length > 26000) {
      s = '${s.substring(0, 26000)}\n...[truncated]';
    }
    return s;
  }
}
