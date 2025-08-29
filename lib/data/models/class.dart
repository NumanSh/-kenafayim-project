import 'package:cloud_firestore/cloud_firestore.dart';

class Class {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String mentorId;
  final String mentorName;
  final int capacity;
  final List<String> registeredUserIds;
  final bool isActive;

  Class({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.mentorId,
    required this.mentorName,
    required this.capacity,
    required this.registeredUserIds,
    this.isActive = true,
  });

  bool get isFull => registeredUserIds.length >= capacity;
  
  int get availableSpots => capacity - registeredUserIds.length;

  Class copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    String? location,
    String? mentorId,
    String? mentorName,
    int? capacity,
    List<String>? registeredUserIds,
    bool? isActive,
  }) {
    return Class(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      mentorId: mentorId ?? this.mentorId,
      mentorName: mentorName ?? this.mentorName,
      capacity: capacity ?? this.capacity,
      registeredUserIds: registeredUserIds ?? this.registeredUserIds,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'location': location,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'capacity': capacity,
      'registeredUserIds': registeredUserIds,
      'isActive': isActive,
    };
  }

  factory Class.fromMap(Map<String, dynamic> map, String documentId) {
    // Handle potential type issues with dateTime
    DateTime dateTime;
    if (map['dateTime'] is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(map['dateTime']);
    } else if (map['dateTime'] is Timestamp) {
      dateTime = (map['dateTime'] as Timestamp).toDate();
    } else {
      dateTime = DateTime.now();
    }

    // Handle potential type issues with registeredUserIds
    List<String> registeredUserIds = [];
    if (map['registeredUserIds'] is List) {
      registeredUserIds = List<String>.from(map['registeredUserIds'] ?? []);
    }

    return Class(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: dateTime,
      location: map['location'] ?? '',
      mentorId: map['mentorId'] ?? '',
      mentorName: map['mentorName'] ?? '',
      capacity: map['capacity'] ?? 10,
      registeredUserIds: registeredUserIds,
      isActive: map['isActive'] ?? true,
    );
  }
}
