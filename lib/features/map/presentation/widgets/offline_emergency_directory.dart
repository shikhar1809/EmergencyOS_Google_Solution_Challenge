import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart' show Geolocator, Position;
import '../../../../core/theme/app_colors.dart';
import '../../../../services/places_service.dart';

class OfflineEmergencyDirectory extends StatelessWidget {
  final List<EmergencyPlace> hospitals;
  final Position? currentPosition;

  const OfflineEmergencyDirectory({
    super.key,
    required this.hospitals,
    this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    final allPlaces = <_PlaceItem>[
      ...hospitals.map((e) => _PlaceItem(place: e, layerKind: 'hospital', type: 'Hospital', icon: Icons.local_hospital_rounded, color: Colors.cyan)),
    ];

    if (currentPosition != null) {
      allPlaces.sort((a, b) {
        final distA = Geolocator.distanceBetween(currentPosition!.latitude, currentPosition!.longitude, a.place.lat, a.place.lng);
        final distB = Geolocator.distanceBetween(currentPosition!.latitude, currentPosition!.longitude, b.place.lat, b.place.lng);
        return distA.compareTo(distB);
      });
    }

    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 28),
                      const SizedBox(width: 12),
                      Text('OFFLINE MAP HUB', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Live map is unavailable. Cached emergency services: tap call for dialer; specialization is inferred from place data (verify when online).',
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            Expanded(
              child: allPlaces.isEmpty
                  ? const Center(
                      child: Text('No emergency data cached for this region.\nCall 112 immediately.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: allPlaces.length,
                      itemBuilder: (context, index) {
                        final item = allPlaces[index];
                        final place = item.place;
                        double? distance;
                        if (currentPosition != null) {
                          distance = Geolocator.distanceBetween(currentPosition!.latitude, currentPosition!.longitude, place.lat, place.lng);
                        }
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(item.icon, color: item.color, size: 32),
                            title: Text(place.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (place.vicinity.isNotEmpty)
                                  Text(place.vicinity, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                Text(
                                  place.specializationForLayer(item.layerKind),
                                  style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.3),
                                ),
                                if (distance != null)
                                  Text('~${(distance / 1000).toStringAsFixed(1)} km', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.phone_rounded, color: Colors.greenAccent),
                              onPressed: () async {
                                final uri = Uri.parse('tel:${place.phoneNumber}');
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceItem {
  final EmergencyPlace place;
  final String layerKind;
  final String type;
  final IconData icon;
  final Color color;

  _PlaceItem({
    required this.place,
    required this.layerKind,
    required this.type,
    required this.icon,
    required this.color,
  });
}
