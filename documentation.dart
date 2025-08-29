import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

/// This file contains the complete documentation for the Knafayim Association Flutter application.
/// The application serves three user types: clients (artists), mentors, and office staff.
/// It provides features for user management, calendar scheduling, messaging, notifications, and reporting.

/// # Data Models
/// 
/// ## User Model
/// ```dart
/// class User {
///   final String id;
///   final String name;
///   final String email;
///   final String phoneNumber;
///   final UserRole role;
///   final DateTime createdAt;
///   final String? profileImageUrl;
///   final Map<String, dynamic> additionalInfo;
///   
///   // Constructor and methods...
/// }
/// 
/// enum UserRole { client, mentor, staff }
/// ```
/// 
/// ## Notification Model
/// ```dart
/// class Notification {
///   final String id;
///   final String userId;
///   final String title;
///   final String content;
///   final DateTime timestamp;
///   final NotificationType type;
///   final bool isRead;
///   
///   // Constructor and methods...
/// }
/// 
/// enum NotificationType { message, reminder, announcement, system }
/// ```
/// 
/// ## Calendar Event Model
/// ```dart
/// class CalendarEvent {
///   final String id;
///   final String title;
///   final String description;
///   final DateTime startTime;
///   final DateTime endTime;
///   final String createdById;
///   final List<String> participantIds;
///   final EventType type;
///   final String? locationOrLink;
///   
///   // Constructor and methods...
/// }
/// 
/// enum EventType { meeting, therapy, workshop, other }
/// ```
/// 
/// ## Message Model
/// ```dart
/// class Message {
///   final String id;
///   final String content;
///   final String senderId;
///   final List<String> recipientIds;
///   final DateTime timestamp;
///   final bool isRead;
///   
///   // Constructor and methods...
/// }
/// ```
/// 
/// ## Report Model
/// ```dart
/// class Report {
///   final String id;
///   final String title;
///   final String content;
///   final String createdById;
///   final String createdByName;
///   final DateTime createdAt;
///   final ReportType type;
///   final List<String> relatedUserIds;
///   
///   // Constructor and methods...
/// }
/// 
/// enum ReportType { all, meeting, progress, event, other }
/// ```

/// # Repositories
/// 
/// ## User Repository
/// Handles CRUD operations for users.
/// 
/// ## Notification Repository
/// Manages notifications for users.
/// 
/// ## Calendar Repository
/// Handles calendar events and scheduling.
/// 
/// ## Message Repository
/// Manages messaging between users.
/// 
/// ## Report Repository
/// Handles report creation and retrieval.

/// # Services
/// 
/// ## Auth Service
/// Handles user authentication, registration, and password reset.
/// 
/// ## Notification Service
/// Manages push notifications and in-app notifications.
/// 
/// ## Storage Service
/// Handles file storage and retrieval.

/// # UI Components
/// 
/// ## Authentication Screens
/// - Login Screen
/// - Register Screen
/// - Forgot Password Screen
/// 
/// ## Home Screens
/// - Client Home Screen
/// - Mentor Home Screen
/// - Staff Home Screen
/// 
/// ## Dashboard Widgets
/// - Client Dashboard
/// - Mentor Dashboard
/// - Staff Dashboard
/// 
/// ## Calendar Components
/// - Calendar View
/// 
/// ## Messaging Components
/// - Messages Screen
/// 
/// ## Profile Components
/// - Profile Screen
/// 
/// ## User Management Components
/// - Clients List Screen
/// - Mentors List Screen
/// 
/// ## Reporting Components
/// - Reports Screen

/// # Application Architecture
/// 
/// The application follows a layered architecture:
/// 
/// 1. Presentation Layer (UI)
///    - Screens and widgets
///    - State management with BLoC pattern
/// 
/// 2. Domain Layer (Business Logic)
///    - Services
///    - Models
/// 
/// 3. Data Layer
///    - Repositories
///    - Data sources (Firebase)
/// 
/// The application uses dependency injection with GetIt for service locator pattern.

/// # Firebase Integration
/// 
/// The application uses Firebase for:
/// - Authentication
/// - Firestore Database
/// - Storage
/// - Cloud Messaging (for notifications)

/// # Localization
/// 
/// The application supports Hebrew (primary) and English languages.

/// # Testing
/// 
/// Unit tests are provided for data models to ensure proper functionality.

/// # Getting Started
/// 
/// 1. Clone the repository
/// 2. Run `flutter pub get` to install dependencies
/// 3. Configure Firebase project
/// 4. Run the application with `flutter run`
