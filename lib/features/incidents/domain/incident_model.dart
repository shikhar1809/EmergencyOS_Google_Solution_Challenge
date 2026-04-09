import 'package:cloud_firestore/cloud_firestore.dart';

/// EmergencyOS: IncidentModel in lib/features/incidents/domain/incident_model.dart.
class IncidentModel {
  final String id;
  final String reportedBy;
  final GeoPoint location;
  final double speedOnImpact;
  final String severity; // High, Medium, Low
  final DateTime timestamp;
  final String? aiAssessment;
  final String status; // Active, Responding, Resolved
  final List<String> assignedResponders;
  final DateTime? resolvedAt;
  final bool hasReport;

  IncidentModel({
    required this.id,
    required this.reportedBy,
    required this.location,
    required this.speedOnImpact,
    required this.severity,
    required this.timestamp,
    this.aiAssessment,
    this.status = 'Active',
    this.assignedResponders = const [],
    this.resolvedAt,
    this.hasReport = false,
  });

  factory IncidentModel.fromMap(Map<String, dynamic> map, String docId) {
    return IncidentModel(
      id: docId,
      reportedBy: map['reportedBy'] ?? '',
      location: map['location'] as GeoPoint,
      speedOnImpact: map['speedOnImpact']?.toDouble() ?? 0.0,
      severity: map['severity'] ?? 'Medium',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      aiAssessment: map['aiAssessment'],
      status: map['status'] ?? 'Active',
      assignedResponders: List<String>.from(map['assignedResponders'] ?? []),
      resolvedAt: map['resolvedAt'] != null ? (map['resolvedAt'] as Timestamp).toDate() : null,
      hasReport: map['hasReport'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportedBy': reportedBy,
      'location': location,
      'speedOnImpact': speedOnImpact,
      'severity': severity,
      'timestamp': Timestamp.fromDate(timestamp),
      'aiAssessment': aiAssessment,
      'status': status,
      'assignedResponders': assignedResponders,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'hasReport': hasReport,
    };
  }
}
