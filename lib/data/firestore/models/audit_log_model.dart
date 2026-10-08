import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String entityType;
  final String entityId;
  final String details;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AuditLogModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    return AuditLogModel(
      id: snapshot.id,
      userId: data?['userId']?.toString() ?? '',
      userName: data?['userName']?.toString() ?? '',
      action: data?['action']?.toString() ?? '',
      entityType: data?['entityType']?.toString() ?? '',
      entityId: data?['entityId']?.toString() ?? '',
      details: data?['details']?.toString() ?? '',
      createdAt: (data?['createdAt'] is Timestamp)
          ? (data!['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory AuditLogModel.fromMap(Map<String, dynamic> data, String id) {
    return AuditLogModel(
      id: id,
      userId: data['userId']?.toString() ?? '',
      userName: data['userName']?.toString() ?? '',
      action: data['action']?.toString() ?? '',
      entityType: data['entityType']?.toString() ?? '',
      entityId: data['entityId']?.toString() ?? '',
      details: data['details']?.toString() ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is String)
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AuditLogModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? action,
    String? entityType,
    String? entityId,
    String? details,
    DateTime? createdAt,
  }) {
    return AuditLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
