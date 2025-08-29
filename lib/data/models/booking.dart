import 'package:flutter/material.dart';

enum BookingStatus { pending, approved, rejected, cancelled, completed }

enum BookingType { lesson, meeting, event, maintenance, personal }

class Booking {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final BookingType type;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> requestedResources;
  final BookingStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? lastModified;
  final Map<String, dynamic> additionalInfo;

  Booking({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.requestedResources,
    this.status = BookingStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.lastModified,
    this.additionalInfo = const {},
  });

  // Get booking duration in minutes
  int get durationInMinutes => endTime.difference(startTime).inMinutes;

  // Get booking duration in hours
  double get durationInHours => durationInMinutes / 60.0;

  // Check if booking is active (approved and current)
  bool get isActive {
    final now = DateTime.now();
    return status == BookingStatus.approved &&
        startTime.isBefore(now) &&
        endTime.isAfter(now);
  }

  // Check if booking is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return status == BookingStatus.approved && startTime.isAfter(now);
  }

  // Check if booking is today
  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  // Get booking type display name in Hebrew
  String getTypeDisplayName() {
    switch (type) {
      case BookingType.lesson:
        return 'שיעור';
      case BookingType.meeting:
        return 'פגישה';
      case BookingType.event:
        return 'אירוע';
      case BookingType.maintenance:
        return 'תחזוקה';
      case BookingType.personal:
        return 'אישי';
    }
  }

  // Get booking status display name in Hebrew
  String getStatusDisplayName() {
    switch (status) {
      case BookingStatus.pending:
        return 'ממתין לאישור';
      case BookingStatus.approved:
        return 'אושר';
      case BookingStatus.rejected:
        return 'נדחה';
      case BookingStatus.cancelled:
        return 'בוטל';
      case BookingStatus.completed:
        return 'הושלם';
    }
  }

  // Get booking status color
  Color getStatusColor() {
    switch (status) {
      case BookingStatus.pending:
        return const Color(0xFFf59e0b); // Orange
      case BookingStatus.approved:
        return const Color(0xFF10b981); // Green
      case BookingStatus.rejected:
        return const Color(0xFFef4444); // Red
      case BookingStatus.cancelled:
        return const Color(0xFF6b7280); // Gray
      case BookingStatus.completed:
        return const Color(0xFF3b82f6); // Blue
    }
  }

  Booking copyWith({
    String? id,
    String? roomId,
    String? userId,
    String? userName,
    BookingType? type,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? requestedResources,
    BookingStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? lastModified,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Booking(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      requestedResources: requestedResources ?? this.requestedResources,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'userId': userId,
      'userName': userName,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'requestedResources': requestedResources,
      'status': status.toString().split('.').last,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.millisecondsSinceEpoch,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified?.millisecondsSinceEpoch,
      'additionalInfo': additionalInfo,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      type: _typeFromString(map['type'] ?? 'lesson'),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] ?? 0),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] ?? 0),
      requestedResources: List<String>.from(map['requestedResources'] ?? []),
      status: _statusFromString(map['status'] ?? 'pending'),
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['approvedAt'])
          : null,
      rejectionReason: map['rejectionReason'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      lastModified: map['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'])
          : null,
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }

  static BookingType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'lesson':
        return BookingType.lesson;
      case 'meeting':
        return BookingType.meeting;
      case 'event':
        return BookingType.event;
      case 'maintenance':
        return BookingType.maintenance;
      case 'personal':
        return BookingType.personal;
      default:
        return BookingType.lesson;
    }
  }

  static BookingStatus _statusFromString(String statusStr) {
    switch (statusStr) {
      case 'pending':
        return BookingStatus.pending;
      case 'approved':
        return BookingStatus.approved;
      case 'rejected':
        return BookingStatus.rejected;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
}
