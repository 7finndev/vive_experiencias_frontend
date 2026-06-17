// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'passport_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$passportHash() => r'9f1d24c38cc2189c99216d5d005634fbd8de294f';

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

/// See also [passport].
@ProviderFor(passport)
const passportProvider = PassportFamily();

/// See also [passport].
class PassportFamily extends Family<AsyncValue<List<PassportEntryModel>>> {
  /// See also [passport].
  const PassportFamily();

  /// See also [passport].
  PassportProvider call(
    int eventId,
  ) {
    return PassportProvider(
      eventId,
    );
  }

  @override
  PassportProvider getProviderOverride(
    covariant PassportProvider provider,
  ) {
    return call(
      provider.eventId,
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
  String? get name => r'passportProvider';
}

/// See also [passport].
class PassportProvider
    extends AutoDisposeFutureProvider<List<PassportEntryModel>> {
  /// See also [passport].
  PassportProvider(
    int eventId,
  ) : this._internal(
          (ref) => passport(
            ref as PassportRef,
            eventId,
          ),
          from: passportProvider,
          name: r'passportProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$passportHash,
          dependencies: PassportFamily._dependencies,
          allTransitiveDependencies: PassportFamily._allTransitiveDependencies,
          eventId: eventId,
        );

  PassportProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.eventId,
  }) : super.internal();

  final int eventId;

  @override
  Override overrideWith(
    FutureOr<List<PassportEntryModel>> Function(PassportRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PassportProvider._internal(
        (ref) => create(ref as PassportRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        eventId: eventId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PassportEntryModel>> createElement() {
    return _PassportProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PassportProvider && other.eventId == eventId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, eventId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PassportRef on AutoDisposeFutureProviderRef<List<PassportEntryModel>> {
  /// The parameter `eventId` of this provider.
  int get eventId;
}

class _PassportProviderElement
    extends AutoDisposeFutureProviderElement<List<PassportEntryModel>>
    with PassportRef {
  _PassportProviderElement(super.provider);

  @override
  int get eventId => (origin as PassportProvider).eventId;
}

String _$hasStampHash() => r'910b70d0a87a2dfef09377a5463c32503e9b2ba8';

/// See also [hasStamp].
@ProviderFor(hasStamp)
const hasStampProvider = HasStampFamily();

/// See also [hasStamp].
class HasStampFamily extends Family<bool> {
  /// See also [hasStamp].
  const HasStampFamily();

  /// See also [hasStamp].
  HasStampProvider call({
    required int establishmentId,
    required int eventId,
  }) {
    return HasStampProvider(
      establishmentId: establishmentId,
      eventId: eventId,
    );
  }

  @override
  HasStampProvider getProviderOverride(
    covariant HasStampProvider provider,
  ) {
    return call(
      establishmentId: provider.establishmentId,
      eventId: provider.eventId,
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
  String? get name => r'hasStampProvider';
}

/// See also [hasStamp].
class HasStampProvider extends AutoDisposeProvider<bool> {
  /// See also [hasStamp].
  HasStampProvider({
    required int establishmentId,
    required int eventId,
  }) : this._internal(
          (ref) => hasStamp(
            ref as HasStampRef,
            establishmentId: establishmentId,
            eventId: eventId,
          ),
          from: hasStampProvider,
          name: r'hasStampProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasStampHash,
          dependencies: HasStampFamily._dependencies,
          allTransitiveDependencies: HasStampFamily._allTransitiveDependencies,
          establishmentId: establishmentId,
          eventId: eventId,
        );

  HasStampProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.establishmentId,
    required this.eventId,
  }) : super.internal();

  final int establishmentId;
  final int eventId;

  @override
  Override overrideWith(
    bool Function(HasStampRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasStampProvider._internal(
        (ref) => create(ref as HasStampRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        establishmentId: establishmentId,
        eventId: eventId,
      ),
    );
  }

  @override
  AutoDisposeProviderElement<bool> createElement() {
    return _HasStampProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasStampProvider &&
        other.establishmentId == establishmentId &&
        other.eventId == eventId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, establishmentId.hashCode);
    hash = _SystemHash.combine(hash, eventId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin HasStampRef on AutoDisposeProviderRef<bool> {
  /// The parameter `establishmentId` of this provider.
  int get establishmentId;

  /// The parameter `eventId` of this provider.
  int get eventId;
}

class _HasStampProviderElement extends AutoDisposeProviderElement<bool>
    with HasStampRef {
  _HasStampProviderElement(super.provider);

  @override
  int get establishmentId => (origin as HasStampProvider).establishmentId;
  @override
  int get eventId => (origin as HasStampProvider).eventId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
