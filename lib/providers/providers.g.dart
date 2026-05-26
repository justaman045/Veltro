// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authServiceHash() => r'd95f6f0327b9783a3e7e039c4caaa93c6a60aa27';

/// See also [authService].
@ProviderFor(authService)
final authServiceProvider = Provider<AuthService>.internal(
  authService,
  name: r'authServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthServiceRef = ProviderRef<AuthService>;
String _$authStateHash() => r'884321275b8047a74331bf7b826d4bb1b3fd116d';

/// See also [authState].
@ProviderFor(authState)
final authStateProvider = AutoDisposeStreamProvider<User?>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthStateRef = AutoDisposeStreamProviderRef<User?>;
String _$dbServiceHash() => r'b2d08b9388df11c6960e863a458a1af090b29ee3';

/// See also [dbService].
@ProviderFor(dbService)
final dbServiceProvider = Provider<DbService>.internal(
  dbService,
  name: r'dbServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dbServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DbServiceRef = ProviderRef<DbService>;
String _$aiServiceHash() => r'f81b1a08e738e21eb6df8dceaf97e3b779cdccda';

/// See also [aiService].
@ProviderFor(aiService)
final aiServiceProvider = Provider<AiService>.internal(
  aiService,
  name: r'aiServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$aiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AiServiceRef = ProviderRef<AiService>;
String _$timelineTasksHash() => r'88b193be4bc4523b2e8dce7393658789337a7070';

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

/// See also [timelineTasks].
@ProviderFor(timelineTasks)
const timelineTasksProvider = TimelineTasksFamily();

/// See also [timelineTasks].
class TimelineTasksFamily extends Family<AsyncValue<List<TimeTask>>> {
  /// See also [timelineTasks].
  const TimelineTasksFamily();

  /// See also [timelineTasks].
  TimelineTasksProvider call(
    DateTime date,
  ) {
    return TimelineTasksProvider(
      date,
    );
  }

  @override
  TimelineTasksProvider getProviderOverride(
    covariant TimelineTasksProvider provider,
  ) {
    return call(
      provider.date,
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
  String? get name => r'timelineTasksProvider';
}

/// See also [timelineTasks].
class TimelineTasksProvider extends AutoDisposeStreamProvider<List<TimeTask>> {
  /// See also [timelineTasks].
  TimelineTasksProvider(
    DateTime date,
  ) : this._internal(
          (ref) => timelineTasks(
            ref as TimelineTasksRef,
            date,
          ),
          from: timelineTasksProvider,
          name: r'timelineTasksProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$timelineTasksHash,
          dependencies: TimelineTasksFamily._dependencies,
          allTransitiveDependencies:
              TimelineTasksFamily._allTransitiveDependencies,
          date: date,
        );

  TimelineTasksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    Stream<List<TimeTask>> Function(TimelineTasksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TimelineTasksProvider._internal(
        (ref) => create(ref as TimelineTasksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<TimeTask>> createElement() {
    return _TimelineTasksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineTasksProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TimelineTasksRef on AutoDisposeStreamProviderRef<List<TimeTask>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _TimelineTasksProviderElement
    extends AutoDisposeStreamProviderElement<List<TimeTask>>
    with TimelineTasksRef {
  _TimelineTasksProviderElement(super.provider);

  @override
  DateTime get date => (origin as TimelineTasksProvider).date;
}

String _$todoTasksHash() => r'6d7b832af37a8d8b3ffd802228031a716670adb8';

/// See also [todoTasks].
@ProviderFor(todoTasks)
final todoTasksProvider = AutoDisposeStreamProvider<List<TimeTask>>.internal(
  todoTasks,
  name: r'todoTasksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$todoTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TodoTasksRef = AutoDisposeStreamProviderRef<List<TimeTask>>;
String _$allTasksHash() => r'ae539e5c2cba1c3bfb478f15b9515ef4bb1ea2c4';

/// See also [allTasks].
@ProviderFor(allTasks)
final allTasksProvider = AutoDisposeFutureProvider<List<TimeTask>>.internal(
  allTasks,
  name: r'allTasksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllTasksRef = AutoDisposeFutureProviderRef<List<TimeTask>>;
String _$templateTasksHash() => r'56bb404452d45f9582e15b37ca4a196233a42cc1';

/// See also [templateTasks].
@ProviderFor(templateTasks)
final templateTasksProvider =
    AutoDisposeStreamProvider<List<TimeTask>>.internal(
  templateTasks,
  name: r'templateTasksProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$templateTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TemplateTasksRef = AutoDisposeStreamProviderRef<List<TimeTask>>;
String _$dailyBriefingHash() => r'0b28043f67a0676a2d943abdb53dfb50012feb69';

/// See also [dailyBriefing].
@ProviderFor(dailyBriefing)
final dailyBriefingProvider = AutoDisposeFutureProvider<String>.internal(
  dailyBriefing,
  name: r'dailyBriefingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dailyBriefingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DailyBriefingRef = AutoDisposeFutureProviderRef<String>;
String _$userProfileDataHash() => r'07c267d3103444a5152b2df13071b294af64ca79';

/// See also [userProfileData].
@ProviderFor(userProfileData)
final userProfileDataProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>?>.internal(
  userProfileData,
  name: r'userProfileDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userProfileDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef UserProfileDataRef
    = AutoDisposeFutureProviderRef<Map<String, dynamic>?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
