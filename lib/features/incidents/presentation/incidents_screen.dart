import 'package:flutter/material.dart';

class IncidentsScreen extends StatelessWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Incidents')),
      body: const Center(child: Text('Incidents list will go here')),
    );
  }
}
