import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ops_hospital_service.dart';

/// EmergencyOS: HospitalBedState in lib/services/bed_availability_service.dart.
///
/// This is an aggregate view over all rows in `ops_hospitals`, so that UI
/// elements (e.g. the command center or map chrome) can show a quick summary
/// of total capacity across the grid.
class HospitalBedState {
  final int totalBedsAvailable;
  final int totalBedsCapacity;
  final int totalDoctorsOnDuty;
  final int totalSpecialistsOnCall;

  const HospitalBedState({
    required this.totalBedsAvailable,
    required this.totalBedsCapacity,
    required this.totalDoctorsOnDuty,
    required this.totalSpecialistsOnCall,
  });

  HospitalBedState copyWith({
    int? totalBedsAvailable,
    int? totalBedsCapacity,
    int? totalDoctorsOnDuty,
    int? totalSpecialistsOnCall,
  }) {
    return HospitalBedState(
      totalBedsAvailable: totalBedsAvailable ?? this.totalBedsAvailable,
      totalBedsCapacity: totalBedsCapacity ?? this.totalBedsCapacity,
      totalDoctorsOnDuty: totalDoctorsOnDuty ?? this.totalDoctorsOnDuty,
      totalSpecialistsOnCall:
          totalSpecialistsOnCall ?? this.totalSpecialistsOnCall,
    );
  }
}

/// EmergencyOS: BedAvailabilityNotifier in lib/services/bed_availability_service.dart.
///
/// Listens to `OpsHospitalService.watchHospitals()` and aggregates a single
/// `HospitalBedState` snapshot across all hospitals.
class BedAvailabilityNotifier extends StreamNotifier<HospitalBedState> {
  @override
  Stream<HospitalBedState> build() async* {
    yield const HospitalBedState(
      totalBedsAvailable: 0,
      totalBedsCapacity: 0,
      totalDoctorsOnDuty: 0,
      totalSpecialistsOnCall: 0,
    );
    yield* OpsHospitalService.watchHospitals().map((rows) {
      var available = 0;
      var capacity = 0;
      var doctors = 0;
      var specialists = 0;
      for (final r in rows) {
        available += r.bedsAvailable;
        capacity += r.bedsTotal;
        doctors += r.doctorsOnDuty;
        specialists += r.specialistsOnCall;
      }
      return HospitalBedState(
        totalBedsAvailable: available,
        totalBedsCapacity: capacity,
        totalDoctorsOnDuty: doctors,
        totalSpecialistsOnCall: specialists,
      );
    });
  }
}

final bedAvailabilityProvider =
    StreamNotifierProvider<BedAvailabilityNotifier, HospitalBedState>(
  BedAvailabilityNotifier.new,
);
