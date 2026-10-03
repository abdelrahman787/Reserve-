import 'package:supabase_flutter/supabase_flutter.dart';

/// Caches the current user's pharmacy id (resolved from their profile row).
class SessionService {
  SessionService(this._client);
  final SupabaseClient _client;

  String? _pharmacyId;

  Future<String?> pharmacyId() async {
    if (_pharmacyId != null) return _pharmacyId;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select('pharmacy_id')
        .eq('id', uid)
        .maybeSingle();
    _pharmacyId = row?['pharmacy_id'] as String?;
    return _pharmacyId;
  }

  void clear() => _pharmacyId = null;
}
