import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/db_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  String _tier = 'free';
  bool _isAdmin = false;

  final _tierController = StreamController<String>.broadcast();
  final _isAdminController = StreamController<bool>.broadcast();

  String get tier => _tier;
  bool get isPro => _tier == 'pro' || _tier == 'proMax';
  bool get isProMax => _tier == 'proMax';
  bool get isAdmin => _isAdmin;

  Stream<String> get tierStream => _tierController.stream;
  Stream<bool> get isProStream => _tierController.stream.map((t) => t == 'pro' || t == 'proMax');
  Stream<bool> get isAdminStream => _isAdminController.stream;

  StreamSubscription? _profileSub;
  StreamSubscription? _authSub;
  DbService? _db;

  Future<void> init(DbService db) async {
    _db = db;
    await _setupForCurrentUser();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _setupForCurrentUser();
    });
  }

  Future<void> _setupForCurrentUser() async {
    _profileSub?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      _tier = 'free';
      _isAdmin = false;
      _tierController.add(_tier);
      _isAdminController.add(false);
      return;
    }

    await _db!.ensureProfileDoc(user.email!);

    try {
      final profile = await _db!.getUserProfile(user.email!);
      if (profile != null) {
        _tier = profile['tier']?.toString() ?? 'free';
        _isAdmin = profile['isAdmin'] == true;
      }
    } catch (e) {
      debugPrint('Failed to read profile: $e');
    }
    _tierController.add(_tier);
    _isAdminController.add(_isAdmin);

    _profileSub = _db!.watchUserProfile(user.email!).listen((data) {
      if (data == null) {
        _tier = 'free';
        _isAdmin = false;
      } else {
        _tier = data['tier']?.toString() ?? 'free';
        _isAdmin = data['isAdmin'] == true;
      }
      _tierController.add(_tier);
      _isAdminController.add(_isAdmin);
    }, onError: (e, st) {
      debugPrint('Profile stream error: $e');
    });
  }

  Future<void> setTier(String email, String newTier) async {
    if (!_isAdmin || _db == null) return;
    await _db!.setUserTier(email, newTier);
  }

  Future<void> setAdmin(String email, bool isAdmin) async {
    if (!_isAdmin || _db == null) return;
    await _db!.setAdminFlag(email, isAdmin);
  }

  void dispose() {
    _profileSub?.cancel();
    _authSub?.cancel();
    _tierController.close();
    _isAdminController.close();
  }
}
