import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, mentor, staff }

class User {
  // ✅ TECHNICAL ID: Database primary key (never changes, system use only)
  final String id;

  // ✅ BASIC INFO: Core user information
  final String name;
  final String email;
  final String phoneNumber;
  final UserRole role;
  final DateTime createdAt;
  final String? profileImageUrl;

  // ✅ PERSONAL ID: Real-world identification (can be null for privacy/flexibility)
  final String? idNumber; // National ID, passport, student ID, etc.

  // ✅ PERSONAL INFO: Basic profile information
  final String? bio;
  final String? address;
  final String? city;
  final String? postalCode;

  // ✅ EMERGENCY CONTACT: Critical for safety
  final String? emergencyContact;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;

  // ✅ MEDICAL INFO: Healthcare and insurance details
  final String? healthFund; // קופת חולים
  final String? nationalInsurance; // ביטוח לאומי
  final String? medicalFileNumber; // מספר תיק רפואי
  final String? medicalInfo; // מידע רפואי נוסף
  final DateTime? lastMedicalUpdate;

  // ✅ PROFESSIONAL INFO: For mentors and staff
  final String? specialization; // התמחות
  final List<String>? disciplines; // תחומי הוראה
  final DateTime? startDate; // תאריך התחלה בעבודה
  final String? therapistContact; // פרטי מטפל (for artists)

  // ✅ SYSTEM INFO: Additional data storage
  final Map<String, dynamic> additionalInfo;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.profileImageUrl,
    this.idNumber,
    this.bio,
    this.address,
    this.city,
    this.postalCode,
    this.emergencyContact,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.healthFund,
    this.nationalInsurance,
    this.medicalFileNumber,
    this.medicalInfo,
    this.lastMedicalUpdate,
    this.specialization,
    this.disciplines,
    this.startDate,
    this.therapistContact,
    this.additionalInfo = const {},
  });

  // ✅ HELPER METHODS: Role-based access
  bool get isStaff => role == UserRole.staff;
  bool get isMentor => role == UserRole.mentor;
  bool get isArtist => role == UserRole.client;

  // ✅ VALIDATION: Check profile completeness
  bool get hasCompleteBasicProfile {
    return name.isNotEmpty && email.isNotEmpty && phoneNumber.isNotEmpty;
  }

  bool get hasEmergencyContact {
    return emergencyContact?.isNotEmpty == true &&
        emergencyContactPhone?.isNotEmpty == true;
  }

  bool get hasMedicalInfo {
    return healthFund?.isNotEmpty == true ||
        nationalInsurance?.isNotEmpty == true ||
        medicalInfo?.isNotEmpty == true;
  }

  // ✅ PROFILE COMPLETENESS: Calculate percentage
  double getProfileCompleteness() {
    int totalFields = 8; // Core fields
    int completedFields = 0;

    if (name.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (phoneNumber.isNotEmpty) completedFields++;
    if (bio?.isNotEmpty == true) completedFields++;
    if (address?.isNotEmpty == true) completedFields++;
    if (emergencyContact?.isNotEmpty == true) completedFields++;
    if (profileImageUrl?.isNotEmpty == true) completedFields++;

    // Role-specific requirements
    if (isArtist && hasEmergencyContact) completedFields++;
    if (isMentor && specialization?.isNotEmpty == true) completedFields++;
    if (isStaff && startDate != null) completedFields++;

    return completedFields / totalFields;
  }

  // ✅ VALIDATION: Validate profile data
  Map<String, String> validateProfile() {
    Map<String, String> errors = {};

    // Basic validation
    if (name.trim().length < 2) {
      errors['name'] = 'השם חייב להכיל לפחות 2 תווים';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      errors['email'] = 'כתובת אימייל לא תקינה';
    }

    if (!RegExp(
      r'^05\d{8}$',
    ).hasMatch(phoneNumber.replaceAll(RegExp(r'[-\s]'), ''))) {
      errors['phoneNumber'] = 'מספר טלפון לא תקין (צריך להתחיל ב-05)';
    }

    // ID Number validation (if provided)
    if (idNumber != null && idNumber!.isNotEmpty) {
      if (!RegExp(r'^\d{9}$').hasMatch(idNumber!)) {
        errors['idNumber'] = 'מספר זהות חייב להכיל 9 ספרות';
      }
    }

    // Role-specific validation
    if (isArtist && (emergencyContact?.isEmpty ?? true)) {
      errors['emergencyContact'] = 'איש קשר חירום נדרש עבור אמנים';
    }

    if (isMentor && (specialization?.isEmpty ?? true)) {
      errors['specialization'] = 'התמחות נדרשת עבור מנחים';
    }

    return errors;
  }

  // ✅ COPY WITH: Create modified copy
  User copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? idNumber,
    String? bio,
    String? address,
    String? city,
    String? postalCode,
    String? emergencyContact,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? healthFund,
    String? nationalInsurance,
    String? medicalFileNumber,
    String? medicalInfo,
    DateTime? lastMedicalUpdate,
    String? specialization,
    List<String>? disciplines,
    DateTime? startDate,
    String? therapistContact,
    Map<String, dynamic>? additionalInfo,
  }) {
    return User(
      id: id, // ID never changes
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role, // Role rarely changes
      createdAt: createdAt, // Created date never changes
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      idNumber: idNumber ?? this.idNumber,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      healthFund: healthFund ?? this.healthFund,
      nationalInsurance: nationalInsurance ?? this.nationalInsurance,
      medicalFileNumber: medicalFileNumber ?? this.medicalFileNumber,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      lastMedicalUpdate: lastMedicalUpdate ?? this.lastMedicalUpdate,
      specialization: specialization ?? this.specialization,
      disciplines: disciplines ?? this.disciplines,
      startDate: startDate ?? this.startDate,
      therapistContact: therapistContact ?? this.therapistContact,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }

  // ✅ TO MAP: Convert to Firestore format
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'profileImageUrl': profileImageUrl,
      'idNumber': idNumber,
      'bio': bio,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'emergencyContact': emergencyContact,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'healthFund': healthFund,
      'nationalInsurance': nationalInsurance,
      'medicalFileNumber': medicalFileNumber,
      'medicalInfo': medicalInfo,
      'lastMedicalUpdate': lastMedicalUpdate?.millisecondsSinceEpoch,
      'specialization': specialization,
      'disciplines': disciplines,
      'startDate': startDate?.millisecondsSinceEpoch,
      'therapistContact': therapistContact,
      'additionalInfo': additionalInfo,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    try {
      // Validate required fields
      if (map['id'] == null || map['name'] == null || map['email'] == null) {
        throw Exception('Missing required user fields');
      }

      // Parse creation date safely
      DateTime createdAt;
      if (map['createdAt'] is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt']);
      } else if (map['createdAt'] != null) {
        try {
          createdAt = (map['createdAt'] as Timestamp).toDate();
        } catch (_) {
          createdAt = DateTime.now();
        }
      } else {
        createdAt = DateTime.now();
      }

      // Parse optional DateTime fields
      DateTime? lastMedicalUpdate;
      if (map['lastMedicalUpdate'] is int) {
        lastMedicalUpdate = DateTime.fromMillisecondsSinceEpoch(
          map['lastMedicalUpdate'],
        );
      }

      DateTime? startDate;
      if (map['startDate'] is int) {
        startDate = DateTime.fromMillisecondsSinceEpoch(map['startDate']);
      }

      // Parse role safely
      UserRole role;
      try {
        role = UserRole.values.firstWhere(
          (e) => e.name == map['role'],
          orElse: () => UserRole.client,
        );
      } catch (e) {
        role = UserRole.client;
      }

      // Parse additional info
      Map<String, dynamic> additionalInfo = {};
      if (map['additionalInfo'] is Map) {
        additionalInfo = Map<String, dynamic>.from(map['additionalInfo']);
      }

      return User(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        phoneNumber: map['phoneNumber']?.toString() ?? '',
        role: role,
        createdAt: createdAt,
        // ✅ ADD: All the missing optional fields
        profileImageUrl: map['profileImageUrl']?.toString(),
        idNumber: map['idNumber']?.toString(),
        bio: map['bio']?.toString(),
        address: map['address']?.toString(),
        city: map['city']?.toString(),
        postalCode: map['postalCode']?.toString(),
        emergencyContact: map['emergencyContact']?.toString(),
        emergencyContactPhone: map['emergencyContactPhone']?.toString(),
        emergencyContactRelation: map['emergencyContactRelation']?.toString(),
        healthFund: map['healthFund']?.toString(),
        nationalInsurance: map['nationalInsurance']?.toString(),
        medicalFileNumber: map['medicalFileNumber']?.toString(),
        medicalInfo: map['medicalInfo']?.toString(),
        lastMedicalUpdate: lastMedicalUpdate,
        specialization: map['specialization']?.toString(),
        disciplines: map['disciplines'] != null
            ? List<String>.from(map['disciplines'])
            : null,
        startDate: startDate,
        therapistContact: map['therapistContact']?.toString(),
        additionalInfo: additionalInfo,
      );
    } catch (e) {
      print('Error creating User from map: $e');
      // Return a basic user object if parsing fails
      return User(
        id: map['id']?.toString() ?? 'error_id',
        name: map['name']?.toString() ?? 'Error User',
        email: map['email']?.toString() ?? 'error@example.com',
        phoneNumber: map['phoneNumber']?.toString() ?? '',
        role: UserRole.client,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
