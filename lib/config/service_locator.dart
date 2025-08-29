import 'package:get_it/get_it.dart';
import 'package:knafayim_app/data/repositories/artist_community_analytics_repository.dart';
import 'package:knafayim_app/data/repositories/attendance_repository.dart';
import 'package:knafayim_app/data/repositories/booking_repository.dart';
import 'package:knafayim_app/data/repositories/room_repository.dart';
import 'package:knafayim_app/data/repositories/working_hours_repository.dart';
import 'package:knafayim_app/services/enhanced_message_service.dart';
import 'package:knafayim_app/services/excel_export_service.dart';
import 'package:knafayim_app/services/message_service.dart';
import 'package:knafayim_app/services/report_generation_service.dart';
import 'package:knafayim_app/services/report_scheduler_service.dart';
// ✅ ADD NOTIFICATION IMPORTS
import 'package:knafayim_app/services/enhanced_notification_service.dart';
import 'package:knafayim_app/services/notification_integration_service.dart';
import 'package:knafayim_app/data/repositories/notification_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/calendar_repository.dart';
import '../data/repositories/unified_calendar_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/lesson_repository.dart';
import '../data/repositories/message_repository.dart';
import '../services/auth_service.dart';
import '../services/custom_auth_service.dart';
import '../services/storage_service.dart';
import '../services/event_cache_service.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator() {
  // ✅ Check if already initialized to prevent double registration
  if (serviceLocator.isRegistered<UserRepository>()) {
    print('🔄 Service locator already initialized, skipping...');
    return;
  }

  print('🚀 Initializing service locator...');

  // ✅ Register Services first
  serviceLocator.registerLazySingleton<MessageService>(() => MessageService());
  serviceLocator.registerLazySingleton<EventCacheService>(
    () => EventCacheService(),
  );
  serviceLocator.registerLazySingleton<ExcelExportService>(
    () => ExcelExportService(),
  );
  serviceLocator.registerLazySingleton<ReportGenerationService>(
    () => ReportGenerationService(),
  );
  serviceLocator.registerLazySingleton<ReportSchedulerService>(
    () => ReportSchedulerService(),
  );
  serviceLocator.registerLazySingleton<StorageService>(() => StorageService());

  // ✅ ADD NOTIFICATION SERVICES
  serviceLocator.registerLazySingleton<EnhancedNotificationService>(
    () => EnhancedNotificationService(),
  );

  // ✅ Register Repositories (each only ONCE)
  serviceLocator.registerLazySingleton<UserRepository>(() => UserRepository());
  serviceLocator.registerLazySingleton<CalendarRepository>(
    () => CalendarRepository(),
  );
  serviceLocator.registerLazySingleton<LessonRepository>(
    () => LessonRepository(),
  );
  serviceLocator.registerLazySingleton<MessageRepository>(
    () => MessageRepository(),
  );
  serviceLocator.registerLazySingleton<ReportRepository>(
    () => ReportRepository(),
  );
  serviceLocator.registerLazySingleton<WorkingHoursRepository>(
    () => WorkingHoursRepository(),
  );
  serviceLocator.registerLazySingleton<ArtistCommunityAnalyticsRepository>(
    () => ArtistCommunityAnalyticsRepository(),
  );
  serviceLocator.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepository(),
  );
  serviceLocator.registerLazySingleton<RoomRepository>(() => RoomRepository());
  serviceLocator.registerLazySingleton<BookingRepository>(
    () => BookingRepository(),
  );

  // ✅ ADD NOTIFICATION REPOSITORY
  serviceLocator.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(),
  );
  serviceLocator.registerLazySingleton<EnhancedMessageService>(
    () => EnhancedMessageService(),
  );
  // ✅ Register dependent services (after their dependencies)
  serviceLocator.registerLazySingleton<UnifiedCalendarRepository>(
    () => UnifiedCalendarRepository(
      calendarRepository: serviceLocator<CalendarRepository>(),
      lessonRepository: serviceLocator<LessonRepository>(),
      userRepository: serviceLocator<UserRepository>(),
      cacheService: serviceLocator<EventCacheService>(),
    ),
  );

  // ✅ Register Auth Services (after UserRepository)
  serviceLocator.registerLazySingleton<AuthService>(
    () => AuthService(userRepository: serviceLocator<UserRepository>()),
  );
  serviceLocator.registerLazySingleton<CustomAuthService>(
    () => CustomAuthService(userRepository: serviceLocator<UserRepository>()),
  );

  print('✅ Service locator initialized successfully!');
}

// ✅ Helper method to reset services (useful for testing)
void resetServiceLocator() {
  serviceLocator.reset();
  print('🔄 Service locator reset');
}
