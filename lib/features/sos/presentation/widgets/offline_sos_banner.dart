import 'package:flutter/material.dart';

class OfflineSosBanner extends StatelessWidget {
  const OfflineSosBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Semantics(
        label:
            'SOS is queued on this device. It will sync to responders when you are back online.',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orangeAccent.withValues(alpha: 0.35),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: Colors.orangeAccent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SOS is saved on this device and will sync to responders when you are back online. '
                  'Keep the app open; reconnect on Wi\u2011Fi or mobile data when you can.',
                  style: TextStyle(
                    color: Colors.orangeAccent.shade100,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
