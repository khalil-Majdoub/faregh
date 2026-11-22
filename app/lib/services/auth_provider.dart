import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_account.dart';

class AuthProvider extends ChangeNotifier {
  static const String _storageKeyAccounts = 'queue_time_accounts_v1';
  static const String _storageKeySessionId = 'queue_time_session_id_v1';

  List<UserAccount> _accounts = [];
  UserAccount? _currentUser;
  bool _isInitialized = false;

  UserAccount? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsRaw = prefs.getString(_storageKeyAccounts);

      if (accountsRaw != null && accountsRaw.isNotEmpty) {
        final decoded = jsonDecode(accountsRaw) as List<dynamic>;
        _accounts = decoded
            .map((item) => UserAccount.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _accounts = _seedDefaultAccounts();
        await _persistAccounts(prefs);
      }

      final sessionId = prefs.getString(_storageKeySessionId);
      if (sessionId != null) {
        for (final acc in _accounts) {
          if (acc.id == sessionId) {
            _currentUser = acc;
            break;
          }
        }
      }
    } catch (_) {
      _accounts = _seedDefaultAccounts();
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Pre-seeded demo accounts matching the prototype ("Khalil") and "LA POSTE - Sousse Centre".
  List<UserAccount> _seedDefaultAccounts() {
    return [
      const UserAccount(
        id: 'demo_user_khalil',
        fullName: 'Khalil Ben Ali',
        email: 'khalil@user.tn',
        password: '123456',
        role: UserRole.user,
        city: 'Sousse',
      ),
      const UserAccount(
        id: 'demo_society_poste',
        fullName: 'LA POSTE - Sousse Centre',
        email: 'poste@society.tn',
        password: '123456',
        role: UserRole.society,
        city: 'Sousse',
        societyPlaceId: 'post_sousse_centre',
      ),
    ];
  }

  /// Signs in with email and password. Returns an error message on failure, or `null` on success.
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    for (final acc in _accounts) {
      if (acc.email.toLowerCase() == normalizedEmail) {
        if (acc.password == password) {
          _currentUser = acc;
          await _persistSession(acc.id);
          notifyListeners();
          return null;
        } else {
          return 'Incorrect password. Please try again.';
        }
      }
    }
    return 'No account found with this email. Please create an account first.';
  }

  /// Registers a brand-new Citizen User or Society account.
  /// Returns an error message on failure, or `null` on success.
  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    required String city,
    String? societyPlaceId,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_accounts.any((a) => a.email.toLowerCase() == normalizedEmail)) {
      return 'An account with this email already exists.';
    }

    final newAccount = UserAccount(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: normalizedEmail,
      password: password,
      role: role,
      city: city.trim().isEmpty ? 'Sousse' : city.trim(),
      societyPlaceId: societyPlaceId,
    );

    _accounts.add(newAccount);
    _currentUser = newAccount;

    final prefs = await SharedPreferences.getInstance();
    await _persistAccounts(prefs);
    await prefs.setString(_storageKeySessionId, newAccount.id);

    notifyListeners();
    return null;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKeySessionId);
    notifyListeners();
  }

  Future<void> _persistAccounts(SharedPreferences prefs) async {
    final encoded = jsonEncode(_accounts.map((a) => a.toJson()).toList());
    await prefs.setString(_storageKeyAccounts, encoded);
  }

  Future<void> _persistSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKeySessionId, id);
  }
}
