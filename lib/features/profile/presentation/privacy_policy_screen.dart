import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Privacy policy & terms of use'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Data Collection',
              content:
                  'We collect minimal data necessary to provide emergency services. This includes your location when SOS is triggered, emergency contacts you provide, and basic device information for security purposes. Location data is only collected when you actively use SOS features or volunteer mode.',
            ),
            _buildSection(
              title: 'Data Usage',
              content:
                  'Your data is used exclusively for emergency response coordination. Location data helps route your SOS alerts to nearby volunteers and emergency services. We use device information to ensure app stability and security. No data is used for advertising or sold to third parties.',
            ),
            _buildSection(
              title: 'Data Sharing',
              content:
                  'In emergency situations, your location and emergency contact information may be shared with nearby volunteers and emergency responders. We may share anonymized, aggregated data for improving emergency response systems. We never share personal data with advertisers or data brokers.',
            ),
            _buildSection(
              title: 'Security',
              content:
                  'All data is encrypted in transit and at rest using industry-standard encryption. We implement strict access controls and regular security audits. SOS alerts are transmitted through secure channels to prevent interception. Your emergency contacts are stored encrypted on your device.',
            ),
            _buildSection(
              title: 'Your Rights',
              content:
                  'You have the right to access, modify, or delete your personal data at any time. You can disable location services for the app while retaining core functionality. You may request a complete data export or deletion through the app settings. You can withdraw consent for data processing at any time.',
            ),
            _buildSection(
              title: 'Contact',
              content:
                  'If you have questions about this privacy policy or our data practices, please contact us through the Help section in the app or email privacy@emergencyos.com.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
