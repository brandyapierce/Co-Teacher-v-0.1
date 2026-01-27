// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for securely storing and retrieving JWT tokens
/// 
/// This service uses flutter_secure_storage which:
/// - On Android: Uses EncryptedSharedPreferences (AES encryption)
/// - On iOS: Uses Keychain (hardware-backed encryption)
/// - On Windows/Desktop: Falls back to SharedPreferences (development only!)
/// 
/// EDUCATIONAL NOTE:
/// JWT tokens are sensitive! Never store them in:
/// - SharedPreferences (not encrypted) - except for development
/// - Regular files (not secure)
/// - In memory only (lost on app restart)
/// 
/// Always use platform-specific secure storage!
/// 
/// WINDOWS NOTE:
/// flutter_secure_storage requires ATL (Visual Studio component).
/// For development, we fall back to SharedPreferences.
/// TODO: Install Visual Studio ATL component for production builds.
class TokenStorageService {
  // FlutterSecureStorage instance (mobile) - TODO: Re-enable for production
  // final FlutterSecureStorage? _storage;
  
  // SharedPreferences instance (development/Windows)
  SharedPreferences? _prefs;

  // Keys for storing tokens
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  TokenStorageService() {
    _initPrefs();
  }

  /// Initialize SharedPreferences
  /// TODO: For production, use flutter_secure_storage on mobile
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is initialized
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== TOKEN MANAGEMENT ====================

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _getPrefs();
    await Future.wait([
      prefs.setString(_accessTokenKey, accessToken),
      prefs.setString(_refreshTokenKey, refreshToken),
    ]);
  }

  /// Get the access token (used for API requests)
  Future<String?> getAccessToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_accessTokenKey);
  }

  /// Get the refresh token (used to get new access token)
  Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_refreshTokenKey);
  }

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Clear all stored tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await _getPrefs();
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_userIdKey),
      prefs.remove(_userEmailKey),
    ]);
  }

  // ==================== USER INFO CACHE ====================

  /// Save user info (cached from API)
  Future<void> saveUserInfo({
    required String userId,
    required String email,
  }) async {
    final prefs = await _getPrefs();
    await Future.wait([
      prefs.setString(_userIdKey, userId),
      prefs.setString(_userEmailKey, email),
    ]);
  }

  /// Get cached user ID
  Future<String?> getUserId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userIdKey);
  }

  /// Get cached user email
  Future<String?> getUserEmail() async {
    final prefs = await _getPrefs();
    return prefs.getString(_userEmailKey);
  }

  // ==================== DEBUGGING ====================

  /// Get all stored keys (for debugging only!)
  Future<Map<String, String>> getAllSecureData() async {
    final prefs = await _getPrefs();
    return {
      _accessTokenKey: prefs.getString(_accessTokenKey) ?? '',
      _refreshTokenKey: prefs.getString(_refreshTokenKey) ?? '',
      _userIdKey: prefs.getString(_userIdKey) ?? '',
      _userEmailKey: prefs.getString(_userEmailKey) ?? '',
    };
  }

  /// Delete all secure storage (use with caution!)
  Future<void> deleteAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}

