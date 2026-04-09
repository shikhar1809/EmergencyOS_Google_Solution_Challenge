import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
// ---------------------------------------------------------------------------
// Triage Camera Screen — Gemini Vision Wound Analysis
// ---------------------------------------------------------------------------

enum TriageSeverity { green, yellow, red, black }

extension TriageSeverityExt on TriageSeverity {
  Color get color => const {
    TriageSeverity.green:  Colors.green,
    TriageSeverity.yellow: Colors.yellow,
    TriageSeverity.red:    Colors.red,
    TriageSeverity.black:  Colors.black,
  }[this]!;
  String get label => const {
    TriageSeverity.green:  'MINOR — Delayed',
    TriageSeverity.yellow: 'DELAYED — Monitor',
    TriageSeverity.red:    'IMMEDIATE — Treat Now',
    TriageSeverity.black:  'EXPECTANT — Critical',
  }[this]!;
}

class TriageResult {
  final TriageSeverity severity;
  final String analysis;
  final List<String> immediateSteps;
  final String rawResponse;

  const TriageResult({
    required this.severity,
    required this.analysis,
    required this.immediateSteps,
    required this.rawResponse,
  });
}

class TriageCameraScreen extends ConsumerStatefulWidget {
  const TriageCameraScreen({super.key});

  @override
  ConsumerState<TriageCameraScreen> createState() => _TriageCameraScreenState();
}

class _TriageCameraScreenState extends ConsumerState<TriageCameraScreen> {
  final _picker = ImagePicker();
  Uint8List? _imageBytes;
  TriageResult? _result;
  bool _loading = false;
  String? _error;

  static const _systemPrompt = '''
You are a trauma triage AI. Analyze the image and respond ONLY in this JSON format:
{
  "severity": "green|yellow|red|black",
  "analysis": "Brief clinical description of what you observe",
  "steps": ["Step 1", "Step 2", "Step 3"]
}

Triage levels:
- green: Minor, non-life-threatening
- yellow: Delayed, serious but stable
- red: Immediate, life-threatening, treat NOW
- black: Expectant, unsurvivable or requires resources beyond available

Be clinical, specific, and actionable. Steps must be numbered first-aid actions.
If the image is NOT a medical/injury image, respond with severity "green" and explain.
If the image is NOT a medical/injury image, respond with severity "green" and explain.
''';

  Future<void> _pickAndAnalyze({bool fromCamera = true}) async {
    setState(() { _loading = true; _error = null; });
    try {
      final picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) { setState(() => _loading = false); return; }

      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);

      final base64Img = base64Encode(bytes);
      
      final promptStr = '$_systemPrompt\n\nAnalyze this injury/medical image for triage.';

      final callable = FirebaseFunctions.instance.httpsCallable('analyzeTriageImage');
      final response = await callable.call({
        'base64str': base64Img,
        'mimeType': 'image/jpeg',
        'prompt': promptStr,
      }).timeout(const Duration(seconds: 30));

      final raw = response.data['result'] as String? ?? '';
      final result = _parseTriageResponse(raw);
      setState(() { _result = result; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Analysis failed: $e'; _loading = false; });
    }
  }

  TriageResult _parseTriageResponse(String raw) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(raw);
      if (jsonMatch == null) throw Exception('No JSON');
      final jsonStr = jsonMatch.group(0)!;
      
      // Manual parse (avoid dart:convert import issues with const)
      final severityMatch = RegExp(r'"severity"\s*:\s*"(\w+)"').firstMatch(jsonStr);
      final analysisMatch = RegExp(r'"analysis"\s*:\s*"([^"]+)"').firstMatch(jsonStr);
      final stepsMatch = RegExp(r'"steps"\s*:\s*\[([^\]]+)\]').firstMatch(jsonStr);

      final severityStr = severityMatch?.group(1) ?? 'yellow';
      final analysis = analysisMatch?.group(1) ?? 'See full response below.';
      
      List<String> steps = [];
      if (stepsMatch != null) {
        steps = RegExp(r'"([^"]+)"')
            .allMatches(stepsMatch.group(1)!)
            .map((m) => m.group(1)!)
            .toList();
      }

      final severity = TriageSeverity.values.firstWhere(
        (s) => s.name == severityStr, orElse: () => TriageSeverity.yellow);

      return TriageResult(
        severity: severity, analysis: analysis,
        immediateSteps: steps, rawResponse: raw,
      );
    } catch (_) {
      // Fallback: parse raw text
      return TriageResult(
        severity: TriageSeverity.yellow,
        analysis: 'Analysis complete — see details below.',
        immediateSteps: [raw],
        rawResponse: raw,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.camera_alt_rounded, color: Colors.redAccent),
          SizedBox(width: 8),
          Text('TRIAGE SCAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            if (_imageBytes == null && !_loading)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.document_scanner_rounded, color: Colors.redAccent, size: 56),
                    SizedBox(height: 12),
                    Text('AI Wound Triage', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                    SizedBox(height: 8),
                    Text('Point camera at wound or injury. Gemini Vision will classify severity (Green/Yellow/Red/Black) and give immediate field actions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),

            if (_imageBytes == null && !_loading) const SizedBox(height: 24),

            // Action Buttons
            if (!_loading && _result == null) ...[
              ElevatedButton.icon(
                onPressed: () => _pickAndAnalyze(fromCamera: true),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('CAPTURE WOUND PHOTO', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Text('Tip: Use flash or bright light for better AI accuracy', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => _pickAndAnalyze(fromCamera: false),
                icon: const Icon(Icons.photo_library_rounded, color: Colors.white70),
                label: const Text('UPLOAD FROM GALLERY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],

            // Loading
            if (_loading) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
              const SizedBox(height: 16),
              const Text('Analyzing image with Gemini Vision...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14)),
            ],

            // Image Preview
            if (_imageBytes != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(_imageBytes!, height: 200, fit: BoxFit.cover),
              ),
            ],

            // Error
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            ],

            // Result
            if (_result != null) ...[
              const SizedBox(height: 20),
              // Severity Badge
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _result!.severity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _result!.severity.color, width: 2),
                ),
                child: Column(
                  children: [
                    Text('TRIAGE LEVEL', style: TextStyle(color: _result!.severity.color, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_result!.severity.label,
                      style: TextStyle(color: _result!.severity.color, fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Analysis
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CLINICAL ASSESSMENT', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_result!.analysis, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Steps
              if (_result!.immediateSteps.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('IMMEDIATE ACTIONS', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._result!.immediateSteps.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: _result!.severity.color.withValues(alpha: 0.2)),
                              child: Center(child: Text('${e.key + 1}', style: TextStyle(color: _result!.severity.color, fontWeight: FontWeight.bold, fontSize: 11))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(e.value, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
                // AI Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.gavel_rounded, color: Colors.orangeAccent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI ADVISORY: Triage results are generated by Gemini Flash. This is an assistive tool, NOT a professional medical diagnosis. Decisions must be made by qualified personnel on-scene.',
                          style: TextStyle(color: Colors.orangeAccent, fontSize: 10, height: 1.4, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Scan Again
                OutlinedButton.icon(
                  onPressed: () => setState(() { _imageBytes = null; _result = null; }),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                  label: const Text('SCAN ANOTHER', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ],
          ),
        ),
    );
  }
}
