import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/maps/eos_hybrid_map.dart';
import '../../../core/maps/ops_map_controller.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/demo_fleet_route_cache.dart';
import '../../../services/demo_fleet_routing.dart';
import '../../../services/demo_fleet_simulation.dart';
import '../../../services/fleet_unit_service.dart';
import '../../../services/volunteer_presence_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/map_marker_generator.dart';
import '../../../core/utils/fleet_map_icons.dart';
import '../../hazards/data/hazard_repository.dart';
import '../../hazards/domain/hazard_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/india_ops_zones.dart';
import '../../../services/places_service.dart';
import '../../../services/bed_availability_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_cache_service.dart';
import '../../../services/drill_map_demo_incidents.dart';
import '../../../services/incident_service.dart';
import '../../../services/offline_map_pack_service.dart';
import '../../../core/utils/map_platform.dart';
import '../domain/emergency_zone_classification.dart';
import 'area_info_page.dart';
import 'widgets/offline_emergency_directory.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.isDrillShell = false});

  /// Practice Grid under `/drill/map` — demo SOS pins, no live Firestore incidents.
  final bool isDrillShell;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  final Completer<OpsMapController> _controller = Completer<OpsMapController>();
  Position? _currentPosition;
  LatLng? _prevUserForCourse;
  double _userCourseDeg = 0;
  double _emergencyRadius = 15000;
  /// Used to pick fleet vehicle bitmap tier (zoom-responsive).
  double _mapZoomForFleet = 12.0;

  static bool _scanCompleted = false;
  bool _isScanning = true;
  Timer? _archiveSweepTimer;

  BitmapDescriptor? _hospitalIcon;
  BitmapDescriptor? _userIcon;
  List<EmergencyPlace> _hospitals = [];

  /// Layer toggles for the map. Emergency services = hospital directory.
  bool _mapShowEmergencyServices = true;
  /// Only the nearest facility per type (within grid radius).
  bool _mapNearestOnly = false;
  /// Live SOS pins + past incidents in the area (chip: "Live SOS").
  bool _mapShowPastIncidents = true;
  /// Hex response zones (annulus tiers to 30 km) from grid radius + service counts.
  bool _mapShowZoneClassification = true;
  /// Other on-duty volunteers with fresh locations inside the grid radius.
  bool _mapShowVolunteers = true;
  bool _zonePanelExpanded = true;
  bool _zoneClassHeaderHovered = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _volunteerDutySub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _fleetDemoSub;
  StreamSubscription<NetworkQuality>? _networkQualitySub;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _volunteerDutyDocs = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _fleetDemoDocs = [];
  Timer? _demoFleetMotionTimer;
  List<LatLng> _hospitalRoute = [];

  /// Responder → victim road paths (green on map), keyed by incident id.
  final Map<String, List<LatLng>> _volunteerResponderPolylines = {};
  String _lastVolunteerRouteRequestSig = '';
  String _lastDemoFleetResponderSig = '';
  String _lastFleetDemoRouteSig = '';

  BitmapDescriptor? _cardiacIcon;
  BitmapDescriptor? _accidentIcon;
  BitmapDescriptor? _fireHazardIcon;
  BitmapDescriptor? _chokingIcon;
  BitmapDescriptor? _bleedingIcon;

  BitmapDescriptor? _collisionEmoji;
  BitmapDescriptor? _pedestrianEmoji;
  BitmapDescriptor? _rolloverEmoji;

  BitmapDescriptor? _incidentCardiacMarker;
  BitmapDescriptor? _incidentCollisionMarker;
  BitmapDescriptor? _incidentBleedingMarker;
  BitmapDescriptor? _incidentFireMarker;
  BitmapDescriptor? _incidentDrowningMarker;
  BitmapDescriptor? _incidentStrokeMarker;
  BitmapDescriptor? _incidentChokingMarker;
  BitmapDescriptor? _incidentDefaultMarker;
  BitmapDescriptor? _volunteerDutyIcon;
  BitmapDescriptor? _volunteerMaleIcon;
  BitmapDescriptor? _volunteerFemaleIcon;

  late AnimationController _rotationController;
  late AnimationController _pulseController;

  CameraPosition _initialPosition = IndiaOpsZones.lucknowCameraPosition(zoom: 14.0);

  /// Bottom inset of the horizontal layer chip bar (`Positioned.bottom`).
  static const double _mapChipBarBottomInset = 96;
  /// Approximate total height of that bar (padding + chips).
  static const double _mapChipBarHeightEstimate = 56;
  /// Gap between chip bar top and nearest-service legend.
  static const double _mapLegendGapAboveChipBar = 10;

  DateTime _lastMapUiPaint = DateTime.fromMillisecondsSinceEpoch(0);
  Duration _mapUiMinInterval = const Duration(milliseconds: 180);
  bool? _lastSuppressMarkerMotion;

  List<SosIncident> _pastIncidents = [];
  AreaIntelligence _areaIntel = AreaIntelligence.empty();
  bool _loadingPastIncidents = false;
  bool _showHeatmaps = true;
  /// Demo: random heat blobs near you (Hotspot button).
  bool _mockHotspotsOn = false;
  final List<LatLng> _mockHotspotCenters = [];
  final List<double> _mockHotspotRadii = [];
  final math.Random _mockHotspotRng = math.Random();

  /// Offline map pack prefetch (places + incidents + OSRM routes).
  double _offlinePackProgress = 0;
  bool _offlinePackJobRunning = false;
  bool _offlinePackComplete = false;

  bool _offlineHydrateRequested = false;

  bool _archivedHistoryMapView = false;

  /// Tracks the currently selected fleet unit id.
  String? _selectedFleetKey;

  /// Countdown tick for periodic eviction of fallback straight-line routes.
  int _evictCountdown = 0;

  /// Nearest-service legend (bottom-right); chip bar leaves horizontal space when visible.
  bool _routeLegendVisible() {
    if (_isScanning || _currentPosition == null) return false;
    if (_mapShowZoneClassification) return true;
    return (_mapShowEmergencyServices && _hospitals.isNotEmpty) ||
        (_mapShowPastIncidents && _pastIncidents.isNotEmpty) ||
        (_mapShowVolunteers && _nearbyOnDutyVolunteers().isNotEmpty);
  }

  bool _placeWithinGrid(EmergencyPlace p) {
    final pos = _currentPosition;
    if (pos == null) return false;
    return Geolocator.distanceBetween(pos.latitude, pos.longitude, p.lat, p.lng) <= _emergencyRadius;
  }

  /// All in-range places, or only the nearest one when [_mapNearestOnly].
  List<EmergencyPlace> _placesForMapLayer(List<EmergencyPlace> all) {
    final inGrid = all.where(_placeWithinGrid).toList();
    if (inGrid.isEmpty) return [];
    if (!_mapNearestOnly) return inGrid;
    return [_nearestPlace(inGrid)];
  }

  EmergencyHexZoneModel? _computeHexZoneModel() {
    if (_currentPosition == null) return null;
    final c = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final volPts = VolunteerPresenceService.filterNearby(
      _volunteerDutyDocs,
      c,
      _emergencyRadius,
    ).map((v) => LatLng(v.lat, v.lng)).toList();
    return buildEmergencyHexZones(
      center: c,
      coverRadiusM: _emergencyRadius,
      hospitals: _hospitals,
      volunteerPositions: volPts,
      useMainAppHospitalDensityColors: true,
    );
  }

  List<ActiveVolunteerNearby> _nearbyOnDutyVolunteers() {
    if (_currentPosition == null) return [];
    final c = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    return VolunteerPresenceService.filterNearby(
      _volunteerDutyDocs,
      c,
      _emergencyRadius,
      excludeUid: FirebaseAuth.instance.currentUser?.uid,
    );
  }

  @override
  void initState() {
    super.initState();
    ConnectivityService().start();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseController.addListener(_scheduleMapUiRepaint);

    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMapAnimationMode());

    _volunteerDutySub = VolunteerPresenceService.watchOnDutyUsers().listen((snap) {
      if (!context.mounted) return;
      setState(() => _volunteerDutyDocs = snap.docs);
    });

    _networkQualitySub = ConnectivityService().qualityStream.listen((_) {
      if (!context.mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncMapAnimationMode());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Restore last known location for the initial camera position
      final lastLoc = await OfflineMapPackService.loadLastLocation();
      if (lastLoc != null && context.mounted) {
        setState(() {
          _initialPosition = IndiaOpsZones.lucknowSafeCamera(lastLoc, preferZoom: 11.5);
        });
      }
      final ready = await OfflineMapPackService.isReady();
      final r = await OfflineMapPackService.loadRoutePolylines();
      if (!context.mounted) return;
      setState(() {
        _offlinePackComplete = ready;
        if (r.hospital.length > 1) _hospitalRoute = r.hospital;
      });
    });

    _loadCustomMarkers();
    if (_scanCompleted) {
      _isScanning = false;
      _determinePosition();
    } else {
      _startScanSequence();
    }

    if (!widget.isDrillShell) {
      _archiveSweepTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => IncidentService.autoArchiveExpiredIncidents(),
      );
    }
    // Demo fleet / seeded `demo_ops_*` playback: practice map only — main map is real incidents only.
    if (widget.isDrillShell) {
      _fleetDemoSub = FleetUnitService.watchFleetUnits().listen((snap) {
        if (!context.mounted) return;
        final demo = snap.docs.where((d) => DemoFleetSimulation.isDemoDoc(d.id)).toList();
        setState(() => _fleetDemoDocs = demo);
      });
      // Synchronized with Admin Command Center for 30 FPS fleet simulation (~33ms)
      _demoFleetMotionTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
        if (!context.mounted || _fleetDemoDocs.isEmpty) return;
        // Every ~90 seconds evict cached fallback straight lines so OSRM routes
        // are retried once the rate limit window has passed.
        _evictCountdown++;
        if (_evictCountdown >= 2727) { // 2727 * 33ms ≈ 90s
          _evictCountdown = 0;
          DemoFleetRouteCache.evictFallbacks();
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _archiveSweepTimer?.cancel();
    _fleetDemoSub?.cancel();
    _demoFleetMotionTimer?.cancel();
    _networkQualitySub?.cancel();
    _volunteerDutySub?.cancel();
    _rotationController.dispose();
    _pulseController.removeListener(_scheduleMapUiRepaint);
    _pulseController.dispose();
    super.dispose();
  }

  void _bumpUserCourseFrom(Position p) {
    final prev = _prevUserForCourse;
    final h = p.heading;
    if (h >= 0 &&
        h <= 360 &&
        (p.speed > 0.4 || (p.headingAccuracy >= 0 && p.headingAccuracy < 55))) {
      _userCourseDeg = h;
    } else if (prev != null) {
      final d = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        p.latitude,
        p.longitude,
      );
      if (d >= 6) {
        _userCourseDeg = Geolocator.bearingBetween(
          prev.latitude,
          prev.longitude,
          p.latitude,
          p.longitude,
        );
      }
    }
    _prevUserForCourse = LatLng(p.latitude, p.longitude);
  }

  Future<void> _loadCustomMarkers() async {
    const subtleHospital = Color(0xFF26C6DA);
    _hospitalIcon = await MapMarkerGenerator.getMinimalPin(Icons.local_hospital_rounded, subtleHospital);
    _userIcon = await MapMarkerGenerator.getMinimalPin(Icons.navigation_rounded, AppColors.primaryInfo);
    _volunteerMaleIcon = await MapMarkerGenerator.getMinimalPin(Icons.man_rounded, AppColors.primarySafe);
    _volunteerFemaleIcon = await MapMarkerGenerator.getMinimalPin(Icons.woman_rounded, const Color(0xFFE91E63));
    _volunteerDutyIcon = await MapMarkerGenerator.getMinimalPin(Icons.groups_rounded, AppColors.primarySafe);
    _cardiacIcon = await MapMarkerGenerator.getMinimalPin(HazardType.cardiacArrest.icon, HazardType.cardiacArrest.color);
    _accidentIcon = await MapMarkerGenerator.getMinimalPin(HazardType.accident.icon, HazardType.accident.color);
    _fireHazardIcon = await MapMarkerGenerator.getMinimalPin(HazardType.fire.icon, HazardType.fire.color);
    _chokingIcon = await MapMarkerGenerator.getMinimalPin(HazardType.choking.icon, HazardType.choking.color);
    _bleedingIcon = await MapMarkerGenerator.getMinimalPin(HazardType.bleeding.icon, HazardType.bleeding.color);

    _collisionEmoji = await MapMarkerGenerator.getMinimalPin(Icons.car_crash_rounded, AppColors.primaryDanger);
    _pedestrianEmoji = await MapMarkerGenerator.getMinimalPin(Icons.directions_run_rounded, AppColors.primaryWarning);
    _rolloverEmoji = await MapMarkerGenerator.getMinimalPin(Icons.car_repair_rounded, AppColors.primaryDanger);

    _incidentCardiacMarker = await MapMarkerGenerator.getMinimalPin(Icons.favorite_rounded, AppColors.primaryDanger);
    _incidentCollisionMarker = await MapMarkerGenerator.getMinimalPin(Icons.car_crash_rounded, AppColors.primaryWarning);
    _incidentBleedingMarker = await MapMarkerGenerator.getMinimalPin(Icons.bloodtype_rounded, AppColors.primaryDanger);
    _incidentFireMarker = await MapMarkerGenerator.getMinimalPin(Icons.local_fire_department_rounded, AppColors.primaryWarning);
    _incidentDrowningMarker = await MapMarkerGenerator.getMinimalPin(Icons.pool_rounded, AppColors.primaryInfo);
    _incidentStrokeMarker = await MapMarkerGenerator.getMinimalPin(Icons.psychology_rounded, const Color(0xFF9575CD));
    _incidentChokingMarker = await MapMarkerGenerator.getMinimalPin(Icons.air_rounded, const Color(0xFF26C6DA));
    _incidentDefaultMarker = await MapMarkerGenerator.getMinimalPin(Icons.emergency_rounded, AppColors.primaryDanger);

    await FleetMapIcons.preload();

    if (context.mounted) setState(() {});
  }

  Future<void> _startScanSequence() async {
    await _determinePosition();
    if (context.mounted) {
      setState(() => _isScanning = false);
      _scanCompleted = true;
    }
  }

  Future<void> _determinePosition({bool forcePlacesRefresh = false}) async {
    try {
      if (forcePlacesRefresh && context.mounted) {
        setState(() {
          _offlinePackComplete = false;
          _offlinePackProgress = 0;
        });
      }
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (context.mounted) {
        setState(() {
          _bumpUserCourseFrom(position);
          _currentPosition = position;
        });
      }

      if (!widget.isDrillShell) {
        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid;
        if (uid != null && uid.isNotEmpty) {
          try {
            await FirebaseFirestore.instance.collection('volunteers').doc(uid).set(
              {
                'lat': position.latitude,
                'lng': position.longitude,
                'updatedAt': DateTime.now().toIso8601String(),
                'isAvailable': true,
              },
              SetOptions(merge: true),
            );
          } catch (_) {}
        }
      }

      final OpsMapController controller = await _controller.future;
      final cam = IndiaOpsZones.lucknowSafeCamera(
        LatLng(position.latitude, position.longitude),
        preferZoom: 11.5,
      );
      await controller.animateCamera(CameraUpdate.newCameraPosition(cam));
      
      if (context.mounted) {
        setState(() {
          _offlinePackJobRunning = true;
          _offlinePackProgress = 0.06;
        });
      }

      // Persist user location for offline map restoration
      unawaited(OfflineMapPackService.saveLastLocation(position.latitude, position.longitude));

      final deferPlaces = ConnectivityService().shouldDeferExpensiveNetworkWork;
      final placesForceRefresh = forcePlacesRefresh || !deferPlaces;

      PlacesService.getNearby(
              lat: position.latitude, lng: position.longitude, type: 'hospital', forceRefresh: placesForceRefresh)
          .then((r) {
        _bumpOfflinePack(0.15);
        return r;
      }).then((results) {
        if (context.mounted) {
          setState(() {
            _hospitals = results;
            _offlinePackProgress = math.max(_offlinePackProgress, 0.52);
          });
          unawaited(OfflineCacheService.saveOfflinePackPlaces('hospital', results.map((p) => p.toJson()).toList()));
          unawaited(_refreshRoadRoutes());
          _expandRadiusIfNeeded(results.isNotEmpty);
        }
      }).catchError((_) {
        if (context.mounted) setState(() => _offlinePackJobRunning = false);
      });

      unawaited(_loadPastIncidents(position));
    } catch (_) {
      if (context.mounted) setState(() => _offlinePackJobRunning = false);
    }
  }

  Future<void> _loadPastIncidents(Position pos) async {
    if (_loadingPastIncidents) return;
    _loadingPastIncidents = true;
    try {
      final center = LatLng(pos.latitude, pos.longitude);
      if (widget.isDrillShell) {
        final now = DateTime.now();
        final archived = DrillMapDemoIncidents.archivedNear(center, now);
        if (context.mounted) {
          setState(() {
            _pastIncidents = archived;
            _areaIntel = IncidentService.computeAreaIntel(archived, center);
            _offlinePackProgress = math.max(_offlinePackProgress, 0.72);
          });
        }
        _loadingPastIncidents = false;
        return;
      }

      unawaited(IncidentService.autoArchiveExpiredIncidents());

      final past = await IncidentService.fetchPastIncidents(
        center: center,
        radiusMeters: _emergencyRadius,
      );
      if (context.mounted) {
        setState(() {
          _pastIncidents = past;
          _areaIntel = IncidentService.computeAreaIntel(past, center);
          _offlinePackProgress = math.max(_offlinePackProgress, 0.72);
        });
        unawaited(OfflineCacheService.savePastIncidentsArchive(
          past.map((i) => i.toJson()).toList(),
        ));
      }
    } catch (_) {}
    _loadingPastIncidents = false;
  }

  void _bumpOfflinePack(double delta) {
    if (!context.mounted) return;
    setState(() {
      _offlinePackProgress = (_offlinePackProgress + delta).clamp(0.0, 1.0);
    });
  }

  Future<void> _openExternalNavigationTo(EmergencyPlace place) async {
    final lat = place.lat;
    final lng = place.lng;
    final name = Uri.encodeComponent(place.name);
    var gStr = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (place.placeId.isNotEmpty) {
      gStr += '&destination_place_id=${Uri.encodeComponent(place.placeId)}';
    }
    final g = Uri.parse(gStr);
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
    try {
      if (await canLaunchUrl(g)) {
        await launchUrl(g, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    try {
      if (await canLaunchUrl(geo)) await launchUrl(geo, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _showHospitalDetailSheet(EmergencyPlace place) {
    _presentEmergencyServiceSheet(place, 'hospital');
  }

  void _presentEmergencyServiceSheet(EmergencyPlace place, String layerKind) {
    _showEmergencyPlaceDetailSheet(
      place,
      layerKind: 'hospital',
      headerIcon: Icons.local_hospital_rounded,
      headerColor: const Color(0xFFFF1744).withValues(alpha: 0.9),
      serviceLabel: 'Hospital',
    );
  }

  void _showEmergencyPlaceDetailSheet(
    EmergencyPlace place, {
    required String layerKind,
    required IconData headerIcon,
    required Color headerColor,
    required String serviceLabel,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dist = _currentPosition == null
            ? null
            : Geolocator.distanceBetween(
                _currentPosition!.latitude, _currentPosition!.longitude, place.lat, place.lng,
              );
        final spec = place.specializationForLayer(layerKind);
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 18),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(headerIcon, color: headerColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      place.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(serviceLabel, style: TextStyle(color: headerColor.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(place.vicinity, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              if (dist != null) ...[
                const SizedBox(height: 6),
                Text('${(dist / 1000).toStringAsFixed(1)} km away', style: const TextStyle(color: AppColors.primaryInfo, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
              const SizedBox(height: 12),
              const Text('Contact', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              SelectableText(
                place.phoneNumber,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                layerKind == 'hospital' ? 'Specializations & services' : 'Role & specialization',
                style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(spec, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        unawaited(_openExternalNavigationTo(place));
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 20),
                      label: const Text('Navigate'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryInfo, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () async {
                      final uri = Uri.parse('tel:${place.phoneNumber}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    icon: const Icon(Icons.phone_in_talk_rounded),
                    tooltip: 'Call',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _markerSnippet(EmergencyPlace p, String layerKind, double distM) {
    final km = (distM / 1000).toStringAsFixed(1);
    final spec = p.specializationForLayer(layerKind);
    final short = spec.length > 38 ? '${spec.substring(0, 36)}…' : spec;
    return '$km km · $short';
  }

  void _expandRadiusIfNeeded(bool foundAnyService) {
    if (!foundAnyService && _emergencyRadius < 15000 && context.mounted) {
      setState(() { _emergencyRadius += 3000; });
    }
  }

  void _scheduleMapUiRepaint() {
    final now = DateTime.now();
    if (now.difference(_lastMapUiPaint) < _mapUiMinInterval) return;
    _lastMapUiPaint = now;
    if (context.mounted) setState(() {});
  }

  void _syncMapAnimationMode() {
    if (!context.mounted) return;
    final suppressMotion = suppressGoogleMapMarkerAnimations(context) ||
        ConnectivityService().shouldDeferExpensiveNetworkWork;
    if (suppressMotion == _lastSuppressMarkerMotion) return;
    _lastSuppressMarkerMotion = suppressMotion;

    final wantMotion = !suppressMotion;
    if (wantMotion) {
      _mapUiMinInterval = const Duration(milliseconds: 180);
      _rotationController.addListener(_scheduleMapUiRepaint);
      if (!_rotationController.isAnimating) _rotationController.repeat();
    } else {
      _rotationController.removeListener(_scheduleMapUiRepaint);
      _rotationController.stop();
      _mapUiMinInterval = const Duration(milliseconds: 500);
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMapAnimationMode());
  }

  void _onMapCreated(OpsMapController controller) {
    if (!_controller.isCompleted) _controller.complete(controller);
  }

  Future<void> _toggleArchivedHistoryMapView() async {
    final next = !_archivedHistoryMapView;
    setState(() {
      _archivedHistoryMapView = next;
      if (next) {
        _mapShowEmergencyServices = false;
        _mapShowZoneClassification = false;
        _mapShowPastIncidents = true;
        _mapShowVolunteers = false;
      } else {
        _mapShowEmergencyServices = true;
        _mapShowZoneClassification = true;
        _mapShowPastIncidents = true;
        _mapShowVolunteers = true;
      }
    });
    _rotationController.duration = const Duration(seconds: 10);
    if (_rotationController.isAnimating) {
      _rotationController.repeat();
    }
    if (next && _currentPosition != null) {
      unawaited(_loadPastIncidents(_currentPosition!));
    }
  }

  BitmapDescriptor _incidentStyleIconForCategory(String category) {
    if (category.contains('stroke')) {
      return _incidentStrokeMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
    if (category.contains('cardiac') || category.contains('heart')) {
      return _incidentCardiacMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    if (category.contains('collision') ||
        category.contains('accident') ||
        category.contains('traffic') ||
        category.contains('rtc') ||
        category.contains('crash') ||
        category.contains('fall')) {
      return _incidentCollisionMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    if (category.contains('bleeding') || category.contains('hemorrhage')) {
      return _incidentBleedingMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
    if (category.contains('fire') || category.contains('lpg') || category.contains('chemical')) {
      return _incidentFireMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
    if (category.contains('drown')) {
      return _incidentDrowningMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    if (category.contains('choking') || category.contains('airway')) {
      return _incidentChokingMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
    }
    return _incidentDefaultMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
  }

  void _openAreaInfo() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => AreaInfoPage(
          currentPosition: _currentPosition,
          hospitals: List<EmergencyPlace>.from(_hospitals),
          areaIntel: _areaIntel,
          pastIncidents: List<SosIncident>.from(_pastIncidents),
        ),
      ),
    );
  }

  void _showMapDirectoryAccuracyDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Verify important places by phone',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Pins come from maps and third-party listings and can be wrong or out of date. '
            'Before you rely on a hospital or recovery service for routing, confirm the address, '
            'hours, and capabilities by phone — especially in an emergency.\n\n'
            'If you spot a wrong listing, tell your coordinator or operations contact so the directory can be corrected.',
            style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _regenerateMockHotspots() {
    if (_currentPosition == null) return;
    _mockHotspotCenters.clear();
    _mockHotspotRadii.clear();
    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;
    for (var i = 0; i < 16; i++) {
      final dLat = (_mockHotspotRng.nextDouble() - 0.5) * 0.07;
      final dLng = (_mockHotspotRng.nextDouble() - 0.5) * 0.07;
      _mockHotspotCenters.add(LatLng(lat + dLat, lng + dLng));
      _mockHotspotRadii.add(260 + _mockHotspotRng.nextDouble() * 880);
    }
  }

  void _toggleMockHotspotDemo() {
    setState(() {
      _mockHotspotsOn = !_mockHotspotsOn;
      if (_mockHotspotsOn) {
        _regenerateMockHotspots();
      } else {
        _mockHotspotCenters.clear();
        _mockHotspotRadii.clear();
      }
    });
  }

  Future<void> _hydrateOfflineFromPack() async {
    if (!context.mounted) return;
    final h = OfflineCacheService.loadOfflinePackPlaces('hospital')?.map(EmergencyPlace.fromJson).toList() ?? [];
    final routes = await OfflineMapPackService.loadRoutePolylines();
    if (!context.mounted) return;
    setState(() {
      if (h.isNotEmpty) _hospitals = h;
      if (routes.hospital.length > 1) _hospitalRoute = routes.hospital;
    });
    final pos = _currentPosition;
    if (pos != null && !widget.isDrillShell) {
      final center = LatLng(pos.latitude, pos.longitude);
      final cachedIncidents = OfflineCacheService.loadPastIncidentsArchive()
          .map((m) => SosIncident.fromJson(Map<String, dynamic>.from(m)))
          .where((inc) {
            final dist = Geolocator.distanceBetween(
              center.latitude, center.longitude, inc.location.latitude, inc.location.longitude,
            );
            return dist <= _emergencyRadius;
          })
          .toList();
      if (cachedIncidents.isNotEmpty && context.mounted) {
        setState(() {
          _pastIncidents = cachedIncidents;
          _areaIntel = IncidentService.computeAreaIntel(cachedIncidents, center);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeHazards = ref.watch(activeHazardsProvider);
    final bedsAsync = ref.watch(bedAvailabilityProvider);
    final beds = bedsAsync.value ??
        const HospitalBedState(
          totalBedsAvailable: 0,
          totalBedsCapacity: 0,
          totalDoctorsOnDuty: 0,
          totalSpecialistsOnCall: 0,
        );
    final isOnlineAsync = ref.watch(connectivityProvider);
    final isOnline = isOnlineAsync.value ?? true;
    final center = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : IndiaOpsZones.lucknow.center;
    final now = DateTime.now();
    final liveIncidents = widget.isDrillShell
        ? DrillMapDemoIncidents.activeNear(center, now)
        : (ref.watch(activeIncidentsProvider).value ?? []);
    // Main app: hide seeded training incidents (`demo_ops_*`); drill uses synthetic or full feed as needed.
    final mapLiveIncidents = widget.isDrillShell
        ? liveIncidents
        : liveIncidents.where((e) => !DemoFleetSimulation.isDemoIncident(e.id)).toList();
    final volSig = mapLiveIncidents
        .map((e) {
          final v = e.volunteerLiveLocation;
          if (v == null) return '';
          final p = e.liveVictimPin;
          return '${e.id}:${v.latitude.toStringAsFixed(4)}:${v.longitude.toStringAsFixed(4)}:'
              '${p.latitude.toStringAsFixed(4)}:${p.longitude.toStringAsFixed(4)}';
        })
        .where((s) => s.isNotEmpty)
        .join('|');
    if (volSig != _lastVolunteerRouteRequestSig) {
      _lastVolunteerRouteRequestSig = volSig;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) unawaited(_syncVolunteerResponderRoutes(mapLiveIncidents));
      });
    }
    final demoResponderSig = liveIncidents
        .where((e) => DemoResponderSimulation.isDemoIncident(e.id))
        .map((e) {
          final p = e.liveVictimPin;
          final bits = <String>[e.id, p.latitude.toStringAsFixed(5), p.longitude.toStringAsFixed(5)];
          if (e.ambulanceLiveLocation != null) bits.add('a');
          return bits.join('|');
        })
        .join('~');
    if (widget.isDrillShell && demoResponderSig != _lastDemoFleetResponderSig) {
      _lastDemoFleetResponderSig = demoResponderSig;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !widget.isDrillShell) return;
        final z = IndiaOpsZones.lucknow;
        for (final e in liveIncidents) {
          if (!DemoResponderSimulation.isDemoIncident(e.id)) continue;
          final scene = e.liveVictimPin;
          if (e.ambulanceLiveLocation != null) {
            DemoFleetRouteCache.prefetchResponderRoute(e.id, 'amb', scene, z);
          }
        }
      });
    }
    final demoVictimPinsForFleet = <String, LatLng>{
      for (final inc in liveIncidents)
        if (inc.id.startsWith('demo_ops_')) inc.id: inc.liveVictimPin,
    };
    final sortedDemoIds = demoVictimPinsForFleet.keys.toList()..sort();
    final fleetPrefetchSig = '${_fleetDemoDocs.map((d) {
      final aid = (d.data()['assignedIncidentId'] as String?) ?? '';
      return '${d.id}|$aid';
    }).join(',')}~${sortedDemoIds.join(',')}';
    if (widget.isDrillShell &&
        _fleetDemoDocs.isNotEmpty &&
        fleetPrefetchSig != _lastFleetDemoRouteSig) {
      _lastFleetDemoRouteSig = fleetPrefetchSig;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted || !widget.isDrillShell) return;
        final z = IndiaOpsZones.lucknow;
        final pins = <String, LatLng>{
          for (final inc in liveIncidents)
            if (inc.id.startsWith('demo_ops_')) inc.id: inc.liveVictimPin,
        };
        for (final d in _fleetDemoDocs) {
          if (!DemoFleetSimulation.isDemoDoc(d.id)) continue;
          final data = d.data();
          final aid = (data['assignedIncidentId'] as String?)?.trim();
          final pin = aid != null ? pins[aid] : null;
          final (a, b) = DemoFleetRouting.fleetEndpoints(d.id, z, aid, pin, pins);
          DemoFleetRouteCache.prefetchFleetLoop(DemoFleetRouting.fleetCacheKey(d.id, z, a, b), a, b);
        }
      });
    }
    final suppressMotion = suppressGoogleMapMarkerAnimations(context);

    ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      if (next.value == true && context.mounted) {
        setState(() => _offlineHydrateRequested = false);
      }
    });

    if (!isOnline) {
      final hasPackSnapshot = OfflineCacheService.loadOfflinePackPlaces('hospital') != null;
      final hasLists = _hospitals.isNotEmpty;
      if (!_offlineHydrateRequested && (!hasLists && hasPackSnapshot)) {
        _offlineHydrateRequested = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_hydrateOfflineFromPack()));
      }
      if (!hasLists && !hasPackSnapshot) {
        return OfflineEmergencyDirectory(
          hospitals: _hospitals,
          currentPosition: _currentPosition,
        );
      }
    }

    final showPackProgress =
        !_isScanning && !_offlinePackComplete && (_offlinePackJobRunning || _offlinePackProgress > 0.04);

    return Scaffold(
      body: Stack(
        children: [
          EosHybridMap(
            mapType: MapType.normal,
            mapId: AppConstants.googleMapsDarkMapId.isNotEmpty
                ? AppConstants.googleMapsDarkMapId
                : null,
            style: AppConstants.googleMapsDarkMapId.isEmpty ? _mapStyle : null,
            trafficEnabled: false,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
            cameraTargetBounds: IndiaOpsZones.lucknowCameraTargetBounds,
            initialCameraPosition: IndiaOpsZones.lucknowSafeCamera(
              _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _initialPosition.target,
              preferZoom: _currentPosition != null ? 15.0 : _initialPosition.zoom,
            ),
            onMapCreated: _onMapCreated,
            onCameraMove: (CameraPosition p) {
              if (!context.mounted) return;
              if (FleetMapIcons.zoomTierChanged(_mapZoomForFleet, p.zoom)) {
                setState(() => _mapZoomForFleet = p.zoom);
              }
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            onTap: (_) {
              if (_selectedFleetKey != null && context.mounted) {
                setState(() => _selectedFleetKey = null);
              }
            },
            circles: _mapCircles(mapLiveIncidents),
            polygons: _mapZonePolygons(),
            markers: _buildServiceMarkers(activeHazards, beds, mapLiveIncidents, suppressMotion, _mapZoomForFleet),
            polylines: _buildRouteLines(),
          ),

          // Subtle loading overlay
          if (_isScanning)
            _buildScanOverlay(),

          if (showPackProgress)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.black.withValues(alpha: 0.55),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: _offlinePackProgress.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: Colors.white10,
                      color: AppColors.primarySafe,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: Text(
                        'Caching area for offline — ${(_offlinePackProgress * 100).clamp(0, 100).round()}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isScanning && widget.isDrillShell)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              right: 12,
              child: Material(
                color: Colors.cyan.shade900.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.school_rounded, color: Colors.cyanAccent.shade200, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Practice Grid: pulsing pins = demo active alerts. Tap the folder icon (Archived SOS) for demo closed incidents — not real data.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!_isScanning && !widget.isDrillShell)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 12,
              right: 80,
              child: Semantics(
                label:
                    'Map accuracy notice. Facility pins may be wrong. Verify by phone before routing.',
                child: Material(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.amberAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pins can be wrong — verify hospitals and stations by phone before routing.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(left: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _showMapDirectoryAccuracyDialog,
                          child: const Text('Details', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Top-right: re-center + map controls
          if (!_isScanning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: Column(
                children: [
                  _MapActionButton(
                    icon: Icons.my_location,
                    tooltip: 'Re-center',
                    onTap: () => _determinePosition(forcePlacesRefresh: true),
                  ),
                  const SizedBox(height: 10),
                  _MapActionButton(
                    icon: Icons.inventory_2_outlined,
                    tooltip: _archivedHistoryMapView
                        ? 'Exit archived SOS view'
                        : (widget.isDrillShell
                            ? 'Archived SOS — practice closed incidents'
                            : 'Archived SOS — real incidents near you'),
                    isActive: _archivedHistoryMapView,
                    activeColor: Colors.amber,
                    onTap: () => unawaited(_toggleArchivedHistoryMapView()),
                  ),
                ],
              ),
            ),

          if (!_isScanning && _archivedHistoryMapView)
            Positioned(
              bottom: 78 + MediaQuery.of(context).padding.bottom,
              left: 12,
              right: 12,
              child: Material(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.archive_outlined, color: Colors.amber.shade200, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pastIncidents.isEmpty
                              ? (widget.isDrillShell
                                  ? 'Practice archived view — demo list is empty (wait for location).'
                                  : 'Archived SOS view — no closed incidents in this area yet. Data comes from real sos_incidents_archive.')
                              : (widget.isDrillShell
                                  ? 'Practice archived view — ${_pastIncidents.length} demo closed incident${_pastIncidents.length == 1 ? '' : 's'} (not Firestore).'
                                  : 'Archived SOS view — ${_pastIncidents.length} real closed incident${_pastIncidents.length == 1 ? '' : 's'} in range (Firestore).'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 11,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Avg emergency response on-map (hidden in drill shell — practice banner uses top space)
          if (!_isScanning && !widget.isDrillShell)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.primaryInfo, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Avg response ${_areaIntel.avgResponseMinutes > 0 ? _areaIntel.avgResponseMinutes : '~8'} min',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Route legend — above the layer chip bar (not overlapping it).
          if (!_isScanning && _routeLegendVisible())
            Positioned(
              bottom: _mapChipBarBottomInset +
                  _mapChipBarHeightEstimate +
                  _mapLegendGapAboveChipBar +
                  MediaQuery.of(context).padding.bottom,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_mapShowZoneClassification) _buildZoneClassificationPanel(context),
                    if (_mapShowZoneClassification &&
                        _mapShowPastIncidents &&
                        _pastIncidents.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Container(height: 1, color: Colors.white24),
                      ),
                    if (!_mapShowZoneClassification) ...[
                      if (_mapShowEmergencyServices && _hospitals.isNotEmpty)
                        _legendRow(const Color(0xFFFF1744), 'Hospital', _nearestDistLabel(_hospitals)),
                    ],
                    if (_mapShowPastIncidents && _pastIncidents.isNotEmpty) ...[
                      if (!_mapShowZoneClassification && (_mapShowEmergencyServices && _hospitals.isNotEmpty))
                        const SizedBox(height: 4),
                      _legendRow(Colors.blueGrey, 'Live SOS / history', '${_pastIncidents.length} in area'),
                    ],
                    if (_mapShowVolunteers && _nearbyOnDutyVolunteers().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _legendRow(
                          const Color(0xFF69F0AE),
                          'Volunteers on duty',
                          '${_nearbyOnDutyVolunteers().length} in grid',
                        ),
                      ),
                    if (_volunteerResponderPolylines.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _legendRow(
                          AppColors.primarySafe,
                          'Responder → scene',
                          '${_volunteerResponderPolylines.length} route${_volunteerResponderPolylines.length == 1 ? "" : "s"}',
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Quick layer toggles (full width; legend sits above this bar).
          if (!_isScanning && _currentPosition != null)
            Positioned(
              left: 10,
              right: 10,
              bottom: _mapChipBarBottomInset + MediaQuery.of(context).padding.bottom,
              child: Material(
                color: Colors.black.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(14),
                elevation: 6,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      _quickMapChip(
                        'Zones',
                        Icons.radar_rounded,
                        AppColors.primarySafe,
                        _mapShowZoneClassification,
                        (v) => setState(() => _mapShowZoneClassification = v),
                      ),
                      _quickMapChip(
                        'Emergency services',
                        Icons.health_and_safety_rounded,
                        const Color(0xFF2979FF),
                        _mapShowEmergencyServices,
                        (v) => setState(() => _mapShowEmergencyServices = v),
                      ),
                      _quickMapChip(
                        'Live SOS',
                        Icons.sos_rounded,
                        Colors.blueGrey,
                        _mapShowPastIncidents,
                        (v) => setState(() => _mapShowPastIncidents = v),
                      ),
                      _quickMapChip(
                        'Volunteers',
                        Icons.groups_rounded,
                        const Color(0xFF69F0AE),
                        _mapShowVolunteers,
                        (v) => setState(() => _mapShowVolunteers = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Area info (full insights panel)
          if (!_isScanning)
            Positioned(
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              left: 16,
              child: FloatingActionButton.extended(
                heroTag: 'area_info_map',
                onPressed: _openAreaInfo,
                backgroundColor: AppColors.primaryInfo.withValues(alpha: 0.9),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.info_outline_rounded, size: 20),
                label: const Text(
                  'Info',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ).animate().scale(delay: 500.ms),
            ),

          // Nearest-only mode (one pin per service type) — dedicated control, not a layer chip.
          if (!_isScanning && _currentPosition != null)
            Positioned(
              left: 16,
              bottom: _mapChipBarBottomInset +
                  MediaQuery.of(context).padding.bottom +
                  _mapChipBarHeightEstimate +
                  10,
              child: Tooltip(
                message: _mapNearestOnly
                    ? 'Showing nearest facility per type. Tap to show all in range.'
                    : 'Tap to show only the nearest hospital in range.',
                child: Material(
                  color: _mapNearestOnly
                      ? const Color(0xFF26A69A).withValues(alpha: 0.95)
                      : Colors.black.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                  elevation: 6,
                  child: InkWell(
                    onTap: () => setState(() => _mapNearestOnly = !_mapNearestOnly),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nearest',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MINIMAL SCAN OVERLAY
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _quickMapChip(
    String label,
    IconData icon,
    Color color,
    bool selected,
    ValueChanged<bool> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        avatar: Icon(icon, size: 16, color: selected ? color : Colors.white54),
        selected: selected,
        onSelected: onSelected,
        selectedColor: color.withValues(alpha: 0.35),
        checkmarkColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.white),
        side: const BorderSide(color: Colors.white24),
        backgroundColor: Colors.white10,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      color: AppColors.background.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 56 + 12 * _pulseController.value,
                height: 56 + 12 * _pulseController.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryInfo.withValues(alpha: 0.08 + 0.06 * _pulseController.value),
                  border: Border.all(
                    color: AppColors.primaryInfo.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.gps_fixed_rounded, color: AppColors.primaryInfo, size: 24),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Locating you…',
              style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPORT HAZARD SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  void _showReportSosSheet() {
    if (_currentPosition == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24.0, right: 24.0, top: 24.0,
              bottom: 24.0 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report SOS for someone else', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Drop an emergency pin at your location to instantly alert nearby volunteers and medics.', style: TextStyle(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: HazardType.values.map((type) => InkWell(
                  onTap: () {
                    ref.read(activeHazardsProvider.notifier).addHazard(
                      type, 
                      _currentPosition!.latitude, 
                      _currentPosition!.longitude
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${type.label} reported successfully. Global routes updated.'),
                        backgroundColor: AppColors.primarySafe,
                      )
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 60) / 2,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: type.color.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type.icon, color: type.color, size: 32),
                        const SizedBox(height: 8),
                        Text(type.label, style: TextStyle(color: type.color, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ));
      }
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP POLYGONS (hex zone mesh)
  // ═══════════════════════════════════════════════════════════════════════════

  Set<Polygon> _mapZonePolygons() {
    if (!_mapShowZoneClassification || _currentPosition == null) return {};
    final model = _computeHexZoneModel();
    if (model == null) return {};
    return model.polygons;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAP CIRCLES
  // ═══════════════════════════════════════════════════════════════════════════

  Set<Circle> _mapCircles(List<SosIncident> liveSosIncidents) {
    final Set<Circle> circles = {};
    final pulse = _pulseController.value;

    for (var i = 0; i < liveSosIncidents.length; i++) {
      final incident = liveSosIncidents[i];
      final center = LatLng(incident.location.latitude, incident.location.longitude);
      final ringRadius = 38 + 140 * pulse;
      circles.add(Circle(
        circleId: CircleId('live_sos_pulse_${incident.id}_$i'),
        center: center,
        radius: ringRadius,
        fillColor: Color.lerp(Colors.redAccent, Colors.orangeAccent, pulse)!.withValues(alpha: 0.06 + 0.14 * (1 - pulse)),
        strokeColor: Color.lerp(Colors.redAccent, Colors.amberAccent, pulse)!.withValues(alpha: 0.45 + 0.45 * pulse),
        strokeWidth: 2,
        zIndex: 4,
      ));
    }

    if (_currentPosition == null) return circles;
    final LatLng c = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    if (_mapShowZoneClassification) {
      circles.add(Circle(
        circleId: const CircleId('emergency_radius_hex_zones'),
        center: c,
        radius: _emergencyRadius,
        fillColor: Colors.transparent,
        strokeColor: Colors.white.withValues(alpha: 0.22),
        strokeWidth: 1,
        zIndex: 0,
      ));
    } else {
      circles.add(Circle(
        circleId: const CircleId('emergency_radius'),
        center: c,
        radius: _emergencyRadius,
        fillColor: AppColors.primaryInfo.withValues(alpha: 0.05),
        strokeColor: AppColors.primaryInfo.withValues(alpha: 0.5),
        strokeWidth: 2,
      ));
    }

    // Heat overlays: not gated on low-power map mode (that mode is for raster/hybrid stability).
    if (_showHeatmaps) {
      for (int i = 0; i < _areaIntel.dangerZones.length; i++) {
        final zone = _areaIntel.dangerZones[i];
        final intensity = (zone.incidentCount / (_areaIntel.totalPastIncidents.clamp(1, 999))).clamp(0.05, 0.3);
        circles.add(Circle(
          circleId: CircleId('hotspot_$i'),
          center: zone.center,
          radius: zone.radiusMeters,
          fillColor: Colors.deepOrange.withValues(alpha: intensity),
          strokeColor: Colors.deepOrange.withValues(alpha: 0.7),
          strokeWidth: 2,
          zIndex: 5,
        ));
      }
    }

    if (_mockHotspotsOn) {
      for (var i = 0; i < _mockHotspotCenters.length; i++) {
        final c = _mockHotspotCenters[i];
        final r = i < _mockHotspotRadii.length ? _mockHotspotRadii[i] : 400.0;
        final alpha = 0.07 + (i % 8) * 0.018;
        circles.add(Circle(
          circleId: CircleId('mock_risk_$i'),
          center: c,
          radius: r,
          fillColor: Color.lerp(Colors.red, Colors.deepOrange, (i % 3) / 3.0)!.withValues(alpha: alpha),
          strokeColor: Colors.redAccent.withValues(alpha: 0.35),
          strokeWidth: 1,
          zIndex: 6,
        ));
      }
    }

    return circles;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROUTE LINES (polylines to nearest services)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _syncVolunteerResponderRoutes(List<SosIncident> incidents) async {
    final targets = incidents.where((e) => e.volunteerLiveLocation != null).toList();
    if (targets.isEmpty) {
      if (_volunteerResponderPolylines.isNotEmpty && context.mounted) {
        setState(() => _volunteerResponderPolylines.clear());
      }
      return;
    }
    final out = <String, List<LatLng>>{};
    await Future.wait(targets.map((inc) async {
      final v = inc.volunteerLiveLocation!;
      final pin = inc.liveVictimPin;
      var pts = await _getRoadRoute(v, pin);
      if (pts.length < 2) pts = [v, pin];
      out[inc.id] = pts;
    }));
    if (!context.mounted) return;
    setState(() {
      _volunteerResponderPolylines
        ..clear()
        ..addAll(out);
    });
  }

  Set<Polyline> _buildRouteLines() {
    if (_currentPosition == null) return {};
    final Set<Polyline> lines = {};

    if (_mapShowEmergencyServices && _hospitalRoute.length > 1) {
      lines.add(Polyline(
        polylineId: const PolylineId('route_hospital'),
        points: _hospitalRoute,
        color: const Color(0xFFFF1744),
        width: 5,
        patterns: [PatternItem.dash(12), PatternItem.gap(8)],
      ));
    }

    for (final e in _volunteerResponderPolylines.entries) {
      if (e.value.length < 2) continue;
      lines.add(Polyline(
        polylineId: PolylineId('volunteer_resp_${e.key}'),
        points: e.value,
        color: AppColors.primarySafe,
        width: 6,
        zIndex: 24,
        patterns: [PatternItem.dash(14), PatternItem.gap(8)],
      ));
    }

    if (widget.isDrillShell) {
      final z = IndiaOpsZones.lucknow;
      final liveIncidents = widget.isDrillShell
          ? DrillMapDemoIncidents.activeNear(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              DateTime.now())
          : [];
      final pins = <String, LatLng>{
        for (final inc in liveIncidents)
          if (inc.id.startsWith('demo_ops_')) inc.id: inc.liveVictimPin,
      };

      for (final d in _fleetDemoDocs) {
        if (!DemoFleetSimulation.isDemoDoc(d.id)) continue;
        final data = d.data();
        if (data['available'] != true) continue;

        final aid = (data['assignedIncidentId'] as String?)?.trim();
        if (aid != null && aid.isNotEmpty) {
          final pin = pins[aid];
          final (a, b) = DemoFleetRouting.fleetEndpoints(d.id, z, aid, pin, pins);
          final route = DemoFleetRouteCache.loopForKey(
            DemoFleetRouting.fleetCacheKey(d.id, z, a, b),
          );
          
          // Skip if route hasn't loaded yet or is still a fallback straight-line
          if (route == null || DemoFleetRouteCache.isFallbackLine(route)) continue;

            const routeColor = Colors.lightBlueAccent;

            final isSelected = _selectedFleetKey == d.id;
            final isDimmed = _selectedFleetKey != null && !isSelected;

            lines.add(Polyline(
              polylineId: PolylineId('demofleet_${d.id}'),
              points: route,
              color: isDimmed ? routeColor.withValues(alpha: 0.15) : routeColor.withValues(alpha: 0.85),
              width: isSelected ? 8 : (isDimmed ? 3 : 5),
              zIndex: isSelected ? 4 : 1,
              patterns: isSelected ? [] : [PatternItem.dash(16), PatternItem.gap(10)],
            ));
        }
      }
    }

    return lines;
  }

  EmergencyPlace _nearestPlace(List<EmergencyPlace> places) {
    EmergencyPlace nearest = places.first;
    double minDist = double.infinity;
    for (final p in places) {
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude, p.lat, p.lng,
      );
      if (d < minDist) {
        minDist = d;
        nearest = p;
      }
    }
    return nearest;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKERS
  // ═══════════════════════════════════════════════════════════════════════════

  Set<Marker> _buildServiceMarkers(
    List<HazardModel> activeHazards,
    HospitalBedState beds,
    List<SosIncident> liveIncidents,
    bool suppressMarkerMotion,
    double fleetMapZoom,
  ) {
    final Set<Marker> markers = {};

    final liveSosFlash = 0.52 + 0.46 * _pulseController.value;

    for (final incident in liveIncidents) {
      final String statusEmoji = incident.status == IncidentStatus.pending
          ? '🆘'
          : (incident.status == IncidentStatus.blocked ? '⏸️' : '🚑');
      final String timeAgo = _timeAgo(incident.timestamp);
      final String category = incident.type.toLowerCase();

      BitmapDescriptor icon;
      if (category.contains('cardiac') || category.contains('heart')) {
        icon = _incidentCardiacMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      } else if (category.contains('collision') || category.contains('accident') || category.contains('traffic') || category.contains('pedestrian') || category.contains('casualty')) {
        icon = _incidentCollisionMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      } else if (category.contains('bleeding') || category.contains('hemorrhage')) {
        icon = _incidentBleedingMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
      } else if (category.contains('fire')) {
        icon = _incidentFireMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
      } else if (category.contains('drown')) {
        icon = _incidentDrowningMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      } else if (category.contains('stroke')) {
        icon = _incidentStrokeMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      } else if (category.contains('choking') || category.contains('airway')) {
        icon = _incidentChokingMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);
      } else {
        icon = _incidentDefaultMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta);
      }

      markers.add(Marker(
        markerId: MarkerId('sos_${incident.id}'),
        position: LatLng(incident.location.latitude + 0.00015, incident.location.longitude + 0.00015),
        zIndexInt: 180,
        alpha: liveSosFlash,
        icon: icon,
        infoWindow: InfoWindow(
          title: '$statusEmoji ${incident.type}',
          snippet: '${incident.userDisplayName} • $timeAgo',
        ),
      ));
    }

    final fbFleetAz = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    final lucknowZ = IndiaOpsZones.lucknow;
    final simNow = DateTime.now();
    final demoVictimPins = <String, LatLng>{
      for (final inc in liveIncidents)
        if (inc.id.startsWith('demo_ops_')) inc.id: inc.liveVictimPin,
    };
    for (final incident in liveIncidents) {
      final scene = incident.liveVictimPin;
      final amb = incident.ambulanceLiveLocation;
      if (amb != null) {
        final sim = widget.isDrillShell && DemoResponderSimulation.isDemoIncident(incident.id)
            ? DemoResponderSimulation.respondingUnitNearScene(incident.id, 'amb', scene, simNow)
            : null;
        markers.add(Marker(
          markerId: MarkerId('sos_${incident.id}_amb'),
          position: sim?.latLng ?? amb,
          zIndexInt: 175,
          icon: FleetMapIcons.ambulanceForZoom(fleetMapZoom, fbFleetAz),
          rotation: sim?.headingDeg ?? (incident.ambulanceLiveHeadingDeg ?? 0),
          flat: true,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: 'Ambulance unit',
            snippet: incident.userDisplayName,
          ),
        ));
      }
    }

    if (widget.isDrillShell) {
      for (final d in _fleetDemoDocs) {
        final data = d.data();
        if (data['available'] != true) continue;
        final aid = (data['assignedIncidentId'] as String?)?.trim();
        final pin = aid != null ? demoVictimPins[aid] : null;
        final pose = DemoFleetSimulation.poseFor(
          d.id,
          simNow,
          lucknowZ,
          assignedIncidentId: aid,
          assignedIncidentScene: pin,
          demoIncidentScenes: demoVictimPins,
        );
        final icon = FleetMapIcons.ambulanceForZoom(fleetMapZoom, fbFleetAz);
        final cs = (data['fleetCallSign'] as String?)?.trim() ?? d.id;
        
        final isSelected = _selectedFleetKey == d.id;
        final isDimmed = _selectedFleetKey != null && !isSelected;
        final alpha = isDimmed ? 0.45 : 1.0;

        markers.add(Marker(
          markerId: MarkerId('demofleet_${d.id}'),
          position: pose.latLng,
          zIndexInt: isSelected ? 200 : 174,
          icon: icon,
          rotation: pose.headingDeg,
          alpha: alpha,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: cs,
            snippet: aid != null && aid.isNotEmpty
                ? 'Practice · response/return ↔ $aid'
                : 'Practice fleet · simulation',
          ),
          onTap: () {
            if (context.mounted) {
              setState(() {
                _selectedFleetKey = _selectedFleetKey == d.id ? null : d.id;
              });
            }
          },
        ));
      }
    }

    if (_mapShowPastIncidents) {
      for (final inc in _pastIncidents) {
        final cat = inc.type.toLowerCase();
        markers.add(Marker(
          markerId: MarkerId('past_${inc.id}'),
          position: LatLng(inc.location.latitude, inc.location.longitude),
          zIndexInt: 55,
          alpha: 0.82,
          icon: _incidentStyleIconForCategory(cat),
          infoWindow: InfoWindow(
            title: widget.isDrillShell ? '📋 Practice: ${inc.type}' : '📋 Past: ${inc.type}',
            snippet: widget.isDrillShell ? '${inc.userDisplayName} · drill demo' : '${inc.userDisplayName} · area history',
          ),
        ));
      }
    }

    if (_currentPosition == null) return markers;
    final double lat = _currentPosition!.latitude;
    final double lng = _currentPosition!.longitude;

    markers.add(Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(lat, lng),
      icon: _userIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
      rotation: suppressMarkerMotion ? 0.0 : _userCourseDeg,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      infoWindow: const InfoWindow(title: 'You', snippet: 'Active Unit'),
    ));

    if (_mapShowVolunteers) {
      for (final v in _nearbyOnDutyVolunteers()) {
        final dist = Geolocator.distanceBetween(lat, lng, v.lat, v.lng);
        final distLabel = dist >= 1000
            ? '${(dist / 1000).toStringAsFixed(1)} km away'
            : '${dist.round()} m away';
        // Pick the gendered marker (male default when gender is unknown)
        final BitmapDescriptor volunteerIcon = v.gender == 'female'
            ? (_volunteerFemaleIcon ??
                _volunteerDutyIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen))
            : (_volunteerMaleIcon ??
                _volunteerDutyIcon ??
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen));
        markers.add(Marker(
          markerId: MarkerId('volunteer_${v.userId}'),
          position: LatLng(v.lat, v.lng),
          zIndexInt: 72,
          icon: volunteerIcon,
          infoWindow: InfoWindow(
            title: v.displayName,
            snippet: 'On duty · $distLabel',
          ),
        ));
      }
    }

    if (_mapShowEmergencyServices) {
      var hi = 0;
      for (var h in _placesForMapLayer(_hospitals)) {
        final suffix = h.placeId.isNotEmpty ? h.placeId : 'noid_${h.lat}_${h.lng}_$hi';
        final sLat = h.lat;
        final sLng = h.lng;
        final dist = Geolocator.distanceBetween(lat, lng, sLat, sLng);
        final hospital = h;
        markers.add(Marker(
          markerId: MarkerId('hospital_${hi}_$suffix'),
          position: LatLng(sLat, sLng),
          icon: _hospitalIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(title: h.name, snippet: _markerSnippet(hospital, 'hospital', dist)),
          onTap: () => _showHospitalDetailSheet(hospital),
        ));
        hi++;
      }
    }

    markers.addAll(activeHazards.map((hazard) {
      BitmapDescriptor icon;
      switch (hazard.type) {
        case HazardType.cardiacArrest: icon = _cardiacIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed); break;
        case HazardType.accident: icon = _accidentIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange); break;
        case HazardType.fire: icon = _fireHazardIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed); break;
        case HazardType.choking: icon = _chokingIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta); break;
        case HazardType.bleeding: icon = _bleedingIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed); break;
      }
      return Marker(
        markerId: MarkerId(hazard.id),
        position: hazard.location,
        icon: icon,
        infoWindow: InfoWindow(title: '${hazard.type.label} Reported', snippet: 'By ${hazard.reportedBy}'),
      );
    }));

    return markers;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildZoneClassificationPanel(BuildContext context) {
    final model = _computeHexZoneModel();
    final baseHeaderColor = model != null
        ? (model.zonePanelHeaderColorOverride ??
            zoneClassificationHeaderColor(model.userCellHealth))
        : const Color(0xFF424242);
    final coverPct = model != null ? model.coveragePercent.toStringAsFixed(0) : '–';
    final totalCells = model != null ? model.totalCells : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) {
            if (!_zoneClassHeaderHovered) setState(() => _zoneClassHeaderHovered = true);
          },
          onExit: (_) {
            if (_zoneClassHeaderHovered) setState(() => _zoneClassHeaderHovered = false);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: _zoneClassHeaderHovered ? AppColors.primaryInfo : baseHeaderColor,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _zonePanelExpanded = !_zonePanelExpanded),
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.white24,
                highlightColor: Colors.white10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _zonePanelExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white70,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 240),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: Text(
                              _zoneClassHeaderHovered
                                  ? '$coverPct% high-density (3+ hospitals)'
                                  : 'Zone classification',
                              key: ValueKey(_zoneClassHeaderHovered),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_zonePanelExpanded) ...[
          const SizedBox(height: 4),
          Text(
            model != null && model.mainAppHospitalDensityLegend
                ? '$kZoneTierCount rings · 0–${(kMaxCoverageRadiusM / 1000).round()} km · $totalCells hex · $coverPct% cells with 3+ hospitals · 🟢≥3 🟡2 🔴1 ⬛0'
                : '$kZoneTierCount rings · 0–${(kMaxCoverageRadiusM / 1000).round()} km · $totalCells hex cells · $coverPct% covered',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.38), fontSize: 9, height: 1.25),
          ),
          const SizedBox(height: 6),
          if (model != null)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.32,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(8),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final t in model.tierSummaries)
                        _tierLegendRow(t, hospitalLegend: model.mainAppHospitalDensityLegend),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ],
    );
  }

  Widget _tierLegendRow(TierAnnulusSummary t, {required bool hospitalLegend}) {
    final range = tierBandLabelKm(t.tierIndex);
    final total = t.total;
    final withHospital = t.greenHexes + t.yellowHexes + t.redHexes;
    final healthPct = total > 0
        ? ((hospitalLegend ? withHospital : t.greenHexes + t.yellowHexes) /
                total *
            100)
            .round()
        : 0;
    final parts = <String>[];
    if (t.greenHexes > 0) parts.add('${t.greenHexes}🟢');
    if (t.yellowHexes > 0) parts.add('${t.yellowHexes}🟡');
    if (t.redHexes > 0) parts.add('${t.redHexes}🔴');
    if (t.greyHexes > 0) parts.add('${t.greyHexes}⬛');
    final subLabel = hospitalLegend ? 'with hospital' : 'covered';
    final sub = parts.isEmpty ? 'No data' : '${parts.join(' ')}  ($healthPct% $subLabel)';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        'T${t.tierIndex + 1} · $range\n$sub',
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, String dist) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(width: 6),
        Text(dist, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      ],
    );
  }

  String _nearestDistLabel(List<EmergencyPlace> places) {
    if (_currentPosition == null || places.isEmpty) return '';
    final n = _nearestPlace(places);
    final km = Geolocator.distanceBetween(
      _currentPosition!.latitude, _currentPosition!.longitude, n.lat, n.lng,
    ) / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  Future<List<LatLng>> _getRoadRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [start, end];
      final data = json.decode(res.body);
      if (data is! Map<String, dynamic>) return [start, end];
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return [start, end];
      final geometry = routes.first['geometry'];
      if (geometry is! Map<String, dynamic>) return [start, end];
      final coords = geometry['coordinates'];
      if (coords is! List || coords.isEmpty) return [start, end];
      final points = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          points.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
        }
      }
      return points.length > 1 ? points : [start, end];
    } catch (_) {
      return [start, end];
    }
  }

  Future<void> _refreshRoadRoutes() async {
    if (_currentPosition == null) return;
    final start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    Future<List<LatLng>> buildFor(List<EmergencyPlace> places) async {
      if (places.isEmpty) return [];
      final nearest = _nearestPlace(places);
      return _getRoadRoute(start, LatLng(nearest.lat, nearest.lng));
    }

    final h = await buildFor(_hospitals);
    if (!context.mounted) return;
    setState(() {
      _hospitalRoute = h;
      _offlinePackProgress = math.max(_offlinePackProgress, 0.92);
    });
    await OfflineMapPackService.saveRoutePolylines(hospital: h, crane: const []);
    if (!context.mounted) return;
    setState(() {
      _offlinePackProgress = 1.0;
      _offlinePackComplete = true;
      _offlinePackJobRunning = false;
    });
  }

  final String _mapStyle = '[{"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},{"featureType":"transit","elementType":"labels","stylers":[{"visibility":"off"}]},{"elementType":"geometry","stylers":[{"color":"#212121"}]},{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]';
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;

  const _MapActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
    this.activeColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? activeColor.withValues(alpha: 0.15) : AppColors.surface.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? activeColor.withValues(alpha: 0.6) : Colors.white10),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Icon(icon, color: isActive ? activeColor : Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }
}
