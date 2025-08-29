import 'dart:ui';

enum RoomType { plasticArts, theater, music, writing, animation, videoCinema }

enum RoomStatus { available, occupied, maintenance, reserved }

class Room {
  final String id;
  final String name;
  final String displayName;
  final RoomType type;
  final int capacity;
  final String description;
  final String location;
  final List<String> features;
  final List<String> availableResources;
  final RoomStatus status;
  final String? imageUrl;
  final Map<String, dynamic> additionalInfo;

  Room({
    required this.id,
    required this.name,
    required this.displayName,
    required this.type,
    required this.capacity,
    required this.description,
    required this.location,
    required this.features,
    required this.availableResources,
    this.status = RoomStatus.available,
    this.imageUrl,
    this.additionalInfo = const {},
  });

  // Get room type display name in Hebrew
  String getTypeDisplayName() {
    switch (type) {
      case RoomType.plasticArts:
        return 'אמנות פלסטית';
      case RoomType.theater:
        return 'תאטרון';
      case RoomType.music:
        return 'מוזיקה';
      case RoomType.writing:
        return 'כתיבה יוצרת';
      case RoomType.animation:
        return 'אנימציה';
      case RoomType.videoCinema:
        return 'וידאו קולנוע';
    }
  }

  // Get room color based on type
  Color getRoomColor() {
    switch (type) {
      case RoomType.plasticArts:
        return const Color(0xFFef4444); // Red
      case RoomType.theater:
        return const Color(0xFF8b5cf6); // Purple
      case RoomType.music:
        return const Color(0xFF10b981); // Green
      case RoomType.writing:
        return const Color(0xFF3b82f6); // Blue
      case RoomType.animation:
        return const Color(0xFFf59e0b); // Orange
      case RoomType.videoCinema:
        return const Color(0xFF06b6d4); // Cyan
    }
  }

  // Check if room is available
  bool get isAvailable => status == RoomStatus.available;

  Room copyWith({
    String? id,
    String? name,
    String? displayName,
    RoomType? type,
    int? capacity,
    String? description,
    String? location,
    List<String>? features,
    List<String>? availableResources,
    RoomStatus? status,
    String? imageUrl,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      location: location ?? this.location,
      features: features ?? this.features,
      availableResources: availableResources ?? this.availableResources,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'type': type.toString().split('.').last,
      'capacity': capacity,
      'description': description,
      'location': location,
      'features': features,
      'availableResources': availableResources,
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'additionalInfo': additionalInfo,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      displayName: map['displayName'] ?? '',
      type: _typeFromString(map['type'] ?? 'plasticArts'),
      capacity: map['capacity'] ?? 0,
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      features: List<String>.from(map['features'] ?? []),
      availableResources: List<String>.from(map['availableResources'] ?? []),
      status: _statusFromString(map['status'] ?? 'available'),
      imageUrl: map['imageUrl'],
      additionalInfo: Map<String, dynamic>.from(map['additionalInfo'] ?? {}),
    );
  }

  static RoomType _typeFromString(String typeStr) {
    switch (typeStr) {
      case 'plasticArts':
        return RoomType.plasticArts;
      case 'theater':
        return RoomType.theater;
      case 'music':
        return RoomType.music;
      case 'writing':
        return RoomType.writing;
      case 'animation':
        return RoomType.animation;
      case 'videoCinema':
        return RoomType.videoCinema;
      default:
        return RoomType.plasticArts;
    }
  }

  static RoomStatus _statusFromString(String statusStr) {
    switch (statusStr) {
      case 'available':
        return RoomStatus.available;
      case 'occupied':
        return RoomStatus.occupied;
      case 'maintenance':
        return RoomStatus.maintenance;
      case 'reserved':
        return RoomStatus.reserved;
      default:
        return RoomStatus.available;
    }
  }
}

// Predefined rooms for Knafayim Association
class KnafayimRooms {
  static List<Room> getDefaultRooms() {
    return [
      Room(
        id: 'plastic_arts_studio',
        name: 'plastic_arts_studio',
        displayName: 'סטודיו אמנות פלסטית',
        type: RoomType.plasticArts,
        capacity: 12,
        description:
            'סטודיו מאובזר לאמנות פלסטית עם שולחנות עבודה ותאורה מקצועית',
        location: 'קומה 1, חדר 101',
        features: ['תאורה מקצועית', 'כיור לניקוי', 'אוורור', 'שולחנות גדולים'],
        availableResources: ['צבעים', 'מכחולים', 'בדים', 'עפרונות', 'פחם'],
      ),
      Room(
        id: 'theater_studio',
        name: 'theater_studio',
        displayName: 'סטודיו תאטרון',
        type: RoomType.theater,
        capacity: 20,
        description: 'אולם תאטרון עם במה ומערכת תאורה',
        location: 'קומה 2, אולם ראשי',
        features: ['במה', 'תאורת במה', 'מערכת קול', 'מראות'],
        availableResources: ['תלבושות', 'אביזרי במה', 'מיקרופונים', 'כסאות'],
      ),
      Room(
        id: 'music_studio',
        name: 'music_studio',
        displayName: 'סטודיו מוזיקה',
        type: RoomType.music,
        capacity: 8,
        description: 'סטודיו מוזיקה מבודד קולית עם כלי נגינה',
        location: 'קומה 1, חדר 103',
        features: ['בידוד קולי', 'פסנתר', 'מערכת הקלטה', 'אקוסטיקה מותאמת'],
        availableResources: ['גיטרות', 'תופים', 'מיקרופונים', 'אוזניות'],
      ),
      Room(
        id: 'writing_studio',
        name: 'writing_studio',
        displayName: 'סטודיו כתיבה יוצרת',
        type: RoomType.writing,
        capacity: 10,
        description: 'חדר שקט ונוח לכתיבה יוצרת',
        location: 'קומה 2, חדר 201',
        features: ['שקט מוחלט', 'תאורה רכה', 'כסאות נוחים', 'שולחנות אישיים'],
        availableResources: ['מחשבים', 'מדפסת', 'נייר', 'עטים'],
      ),
      Room(
        id: 'animation_studio',
        name: 'animation_studio',
        displayName: 'סטודיו אנימציה',
        type: RoomType.animation,
        capacity: 6,
        description: 'סטודיו מחשבים לאנימציה ועיצוב דיגיטלי',
        location: 'קומה 2, חדר 202',
        features: [
          'מחשבים חזקים',
          'טאבלטים גרפיים',
          'מסכים גדולים',
          'תוכנות מקצועיות',
        ],
        availableResources: ['טאבלטים', 'עטים דיגיטליים', 'אוזניות', 'מקלדות'],
      ),
      Room(
        id: 'video_cinema_studio',
        name: 'video_cinema_studio',
        displayName: 'סטודיו וידאו וקולנוע',
        type: RoomType.videoCinema,
        capacity: 8,
        description: 'סטודיו לצילום ועריכת וידאו',
        location: 'קומה 1, חדר 104',
        features: ['רקע ירוק', 'תאורת סטודיו', 'מצלמות מקצועיות', 'חדר עריכה'],
        availableResources: ['מצלמות', 'חצובות', 'מיקרופונים', 'כרטיסי זיכרון'],
      ),
    ];
  }
}
