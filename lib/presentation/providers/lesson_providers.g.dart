// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unifiedCalendarRepositoryHash() =>
    r'65939c22464a6143bf20ef5f5b6ca8bdf6c2caf7';

/// See also [unifiedCalendarRepository].
@ProviderFor(unifiedCalendarRepository)
final unifiedCalendarRepositoryProvider =
    AutoDisposeProvider<UnifiedCalendarRepository>.internal(
  unifiedCalendarRepository,
  name: r'unifiedCalendarRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unifiedCalendarRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnifiedCalendarRepositoryRef
    = AutoDisposeProviderRef<UnifiedCalendarRepository>;
String _$lessonRepositoryHash() => r'f74c104a08a4608511fd6b8b6e5a99e9cf4ceb0c';

/// See also [lessonRepository].
@ProviderFor(lessonRepository)
final lessonRepositoryProvider = AutoDisposeProvider<LessonRepository>.internal(
  lessonRepository,
  name: r'lessonRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LessonRepositoryRef = AutoDisposeProviderRef<LessonRepository>;
String _$userRepositoryHash() => r'de4d747b1558dd2742db4ee1be04527e769fde9c';

/// See also [userRepository].
@ProviderFor(userRepository)
final userRepositoryProvider = AutoDisposeProvider<UserRepository>.internal(
  userRepository,
  name: r'userRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRepositoryRef = AutoDisposeProviderRef<UserRepository>;
String _$lessonsStreamHash() => r'ed50a1101a0ec33b00afac8d0bfcda9cd3bbdc72';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [lessonsStream].
@ProviderFor(lessonsStream)
const lessonsStreamProvider = LessonsStreamFamily();

/// See also [lessonsStream].
class LessonsStreamFamily extends Family<AsyncValue<List<Lesson>>> {
  /// See also [lessonsStream].
  const LessonsStreamFamily();

  /// See also [lessonsStream].
  LessonsStreamProvider call(
    String userId,
    UserRole userRole,
  ) {
    return LessonsStreamProvider(
      userId,
      userRole,
    );
  }

  @override
  LessonsStreamProvider getProviderOverride(
    covariant LessonsStreamProvider provider,
  ) {
    return call(
      provider.userId,
      provider.userRole,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lessonsStreamProvider';
}

/// See also [lessonsStream].
class LessonsStreamProvider extends AutoDisposeStreamProvider<List<Lesson>> {
  /// See also [lessonsStream].
  LessonsStreamProvider(
    String userId,
    UserRole userRole,
  ) : this._internal(
          (ref) => lessonsStream(
            ref as LessonsStreamRef,
            userId,
            userRole,
          ),
          from: lessonsStreamProvider,
          name: r'lessonsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonsStreamHash,
          dependencies: LessonsStreamFamily._dependencies,
          allTransitiveDependencies:
              LessonsStreamFamily._allTransitiveDependencies,
          userId: userId,
          userRole: userRole,
        );

  LessonsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.userRole,
  }) : super.internal();

  final String userId;
  final UserRole userRole;

  @override
  Override overrideWith(
    Stream<List<Lesson>> Function(LessonsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonsStreamProvider._internal(
        (ref) => create(ref as LessonsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        userRole: userRole,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Lesson>> createElement() {
    return _LessonsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonsStreamProvider &&
        other.userId == userId &&
        other.userRole == userRole;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, userRole.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LessonsStreamRef on AutoDisposeStreamProviderRef<List<Lesson>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `userRole` of this provider.
  UserRole get userRole;
}

class _LessonsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<Lesson>>
    with LessonsStreamRef {
  _LessonsStreamProviderElement(super.provider);

  @override
  String get userId => (origin as LessonsStreamProvider).userId;
  @override
  UserRole get userRole => (origin as LessonsStreamProvider).userRole;
}

String _$upcomingLessonsStreamHash() =>
    r'a9dc7d5c70d0bee09c979d778dc378e31ad0cfea';

/// See also [upcomingLessonsStream].
@ProviderFor(upcomingLessonsStream)
const upcomingLessonsStreamProvider = UpcomingLessonsStreamFamily();

/// See also [upcomingLessonsStream].
class UpcomingLessonsStreamFamily extends Family<AsyncValue<List<Lesson>>> {
  /// See also [upcomingLessonsStream].
  const UpcomingLessonsStreamFamily();

  /// See also [upcomingLessonsStream].
  UpcomingLessonsStreamProvider call(
    String userId,
    UserRole userRole,
  ) {
    return UpcomingLessonsStreamProvider(
      userId,
      userRole,
    );
  }

  @override
  UpcomingLessonsStreamProvider getProviderOverride(
    covariant UpcomingLessonsStreamProvider provider,
  ) {
    return call(
      provider.userId,
      provider.userRole,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'upcomingLessonsStreamProvider';
}

/// See also [upcomingLessonsStream].
class UpcomingLessonsStreamProvider
    extends AutoDisposeStreamProvider<List<Lesson>> {
  /// See also [upcomingLessonsStream].
  UpcomingLessonsStreamProvider(
    String userId,
    UserRole userRole,
  ) : this._internal(
          (ref) => upcomingLessonsStream(
            ref as UpcomingLessonsStreamRef,
            userId,
            userRole,
          ),
          from: upcomingLessonsStreamProvider,
          name: r'upcomingLessonsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$upcomingLessonsStreamHash,
          dependencies: UpcomingLessonsStreamFamily._dependencies,
          allTransitiveDependencies:
              UpcomingLessonsStreamFamily._allTransitiveDependencies,
          userId: userId,
          userRole: userRole,
        );

  UpcomingLessonsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.userRole,
  }) : super.internal();

  final String userId;
  final UserRole userRole;

  @override
  Override overrideWith(
    Stream<List<Lesson>> Function(UpcomingLessonsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UpcomingLessonsStreamProvider._internal(
        (ref) => create(ref as UpcomingLessonsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        userRole: userRole,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Lesson>> createElement() {
    return _UpcomingLessonsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingLessonsStreamProvider &&
        other.userId == userId &&
        other.userRole == userRole;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, userRole.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UpcomingLessonsStreamRef on AutoDisposeStreamProviderRef<List<Lesson>> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `userRole` of this provider.
  UserRole get userRole;
}

class _UpcomingLessonsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<Lesson>>
    with UpcomingLessonsStreamRef {
  _UpcomingLessonsStreamProviderElement(super.provider);

  @override
  String get userId => (origin as UpcomingLessonsStreamProvider).userId;
  @override
  UserRole get userRole => (origin as UpcomingLessonsStreamProvider).userRole;
}

String _$lessonParticipantsHash() =>
    r'd0b01f0d0657c58c4849c40f26be46bf4c1e4fe7';

/// See also [lessonParticipants].
@ProviderFor(lessonParticipants)
const lessonParticipantsProvider = LessonParticipantsFamily();

/// See also [lessonParticipants].
class LessonParticipantsFamily extends Family<AsyncValue<List<User>>> {
  /// See also [lessonParticipants].
  const LessonParticipantsFamily();

  /// See also [lessonParticipants].
  LessonParticipantsProvider call(
    String lessonId,
  ) {
    return LessonParticipantsProvider(
      lessonId,
    );
  }

  @override
  LessonParticipantsProvider getProviderOverride(
    covariant LessonParticipantsProvider provider,
  ) {
    return call(
      provider.lessonId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'lessonParticipantsProvider';
}

/// See also [lessonParticipants].
class LessonParticipantsProvider extends AutoDisposeFutureProvider<List<User>> {
  /// See also [lessonParticipants].
  LessonParticipantsProvider(
    String lessonId,
  ) : this._internal(
          (ref) => lessonParticipants(
            ref as LessonParticipantsRef,
            lessonId,
          ),
          from: lessonParticipantsProvider,
          name: r'lessonParticipantsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$lessonParticipantsHash,
          dependencies: LessonParticipantsFamily._dependencies,
          allTransitiveDependencies:
              LessonParticipantsFamily._allTransitiveDependencies,
          lessonId: lessonId,
        );

  LessonParticipantsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lessonId,
  }) : super.internal();

  final String lessonId;

  @override
  Override overrideWith(
    FutureOr<List<User>> Function(LessonParticipantsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LessonParticipantsProvider._internal(
        (ref) => create(ref as LessonParticipantsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lessonId: lessonId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<User>> createElement() {
    return _LessonParticipantsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonParticipantsProvider && other.lessonId == lessonId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lessonId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LessonParticipantsRef on AutoDisposeFutureProviderRef<List<User>> {
  /// The parameter `lessonId` of this provider.
  String get lessonId;
}

class _LessonParticipantsProviderElement
    extends AutoDisposeFutureProviderElement<List<User>>
    with LessonParticipantsRef {
  _LessonParticipantsProviderElement(super.provider);

  @override
  String get lessonId => (origin as LessonParticipantsProvider).lessonId;
}

String _$lessonNotifierHash() => r'6103d4494fd0c5864894a85d968e789be9b56731';

/// See also [LessonNotifier].
@ProviderFor(LessonNotifier)
final lessonNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LessonNotifier, List<Lesson>>.internal(
  LessonNotifier.new,
  name: r'lessonNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lessonNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LessonNotifier = AutoDisposeAsyncNotifier<List<Lesson>>;
String _$selectedLessonHash() => r'5db696f1db89ac1908875c55fd7480b8fdcb0cd5';

/// See also [SelectedLesson].
@ProviderFor(SelectedLesson)
final selectedLessonProvider =
    AutoDisposeNotifierProvider<SelectedLesson, Lesson?>.internal(
  SelectedLesson.new,
  name: r'selectedLessonProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedLessonHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedLesson = AutoDisposeNotifier<Lesson?>;
String _$participantManagementHash() =>
    r'd41870481f8340724a0aa338fb5e39098126bd63';

/// See also [ParticipantManagement].
@ProviderFor(ParticipantManagement)
final participantManagementProvider = NotifierProvider<ParticipantManagement,
    ParticipantManagementState>.internal(
  ParticipantManagement.new,
  name: r'participantManagementProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$participantManagementHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ParticipantManagement = Notifier<ParticipantManagementState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
