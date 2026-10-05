import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background/terminated message handler. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Keep this light; data-only messages arrive here when the app is in the
  // background or terminated.
  debugPrint('BG notification: ${message.messageId}');
}

/// Firebase Cloud Messaging integration.
///
/// Guarded: if Firebase is not configured for this build (no
/// `firebase_options.dart` / platform config), [init] disables notifications
/// gracefully instead of crashing the app. See docs/NOTIFICATIONS.md for setup.
class NotificationService {
  NotificationService(this._client);
  final SupabaseClient _client;

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onMessage.listen((m) {
        debugPrint('FG notification: ${m.notification?.title}');
      });
      _ready = true;
    } catch (e) {
      _ready = false;
      debugPrint('Push notifications disabled (Firebase not configured): $e');
    }
  }

  /// Persists the device's FCM token for the signed-in user. Call after login.
  Future<void> registerToken() async {
    if (!_ready) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null) await _upsert(uid, token);
      messaging.onTokenRefresh.listen((t) => _upsert(uid, t));
    } catch (e) {
      debugPrint('registerToken failed: $e');
    }
  }

  Future<void> _upsert(String uid, String token) async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    await _client.from('device_tokens').upsert(
      {'user_id': uid, 'token': token, 'platform': platform},
      onConflict: 'token',
    );
  }
}
