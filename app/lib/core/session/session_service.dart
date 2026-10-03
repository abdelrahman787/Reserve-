import 'package:supabase_flutter/supabase_flutter.dart';

/// Caches the current user's profile fields (role, pharmacy id, vendor id).
class SessionService {
  SessionService(this._client);
  final SupabaseClient _client;

  String? _role;
  String? _pharmacyId;
  String? _vendorId;
  bool _loaded = false;

  Future<void> _ensure() async {
    if (_loaded) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    final row = await _client
        .from('profiles')
        .select('role, pharmacy_id, vendor_id')
        .eq('id', uid)
        .maybeSingle();
    _role = row?['role'] as String?;
    _pharmacyId = row?['pharmacy_id'] as String?;
    _vendorId = row?['vendor_id'] as String?;
    _loaded = true;
  }

  Future<String?> role() async {
    await _ensure();
    return _role;
  }

  Future<String?> pharmacyId() async {
    await _ensure();
    return _pharmacyId;
  }

  Future<String?> vendorId() async {
    await _ensure();
    return _vendorId;
  }

  Future<bool> isAdminOrVendor() async {
    final r = await role();
    return r == 'admin' || r == 'vendor';
  }

  void clear() {
    _role = null;
    _pharmacyId = null;
    _vendorId = null;
    _loaded = false;
  }
}
