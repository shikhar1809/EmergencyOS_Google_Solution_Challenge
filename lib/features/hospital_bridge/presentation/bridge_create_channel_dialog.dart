import 'package:flutter/material.dart';

Future<String?> showBridgeCreateChannelDialog(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: const Text(
        'Create Channel',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'channel-name',
          hintStyle: TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Color(0xFF0D1117),
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          onPressed: () {
            final name = controller.text.trim().toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9\-]'),
              '-',
            );
            if (name.isNotEmpty) {
              Navigator.pop(ctx, name);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF5865F2),
          ),
          child: const Text('Create'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
