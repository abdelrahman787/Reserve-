import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/account_repository.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _license = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  late final Future<PharmacyProfile?> _future = _load();
  String? _pharmacyId;
  bool _saving = false;

  Future<PharmacyProfile?> _load() async {
    _pharmacyId = await sl<SessionService>().pharmacyId();
    if (_pharmacyId == null) return null;
    final res = await sl<AccountRepository>().fetchPharmacy(_pharmacyId!);
    return res.fold((_) => null, (p) {
      _name.text = p.name;
      _license.text = p.licenseNumber ?? '';
      _phone.text = p.phone ?? '';
      _address.text = p.address ?? '';
      return p;
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _license, _phone, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _pharmacyId == null) {
      return;
    }
    setState(() => _saving = true);
    final res = await sl<AccountRepository>().updatePharmacy(
      pharmacyId: _pharmacyId!,
      name: _name.text.trim(),
      licenseNumber: _license.text.trim().isEmpty ? null : _license.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: AppColors.accent,
            content: Text('saved'.tr())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('account_settings'.tr())),
      body: FutureBuilder<PharmacyProfile?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const AppLoader();
          }
          if (snap.data == null) {
            return EmptyState(
                icon: Icons.person_off_outlined,
                title: 'admin_no_vendor'.tr());
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field(_name, 'pharmacy_name'.tr(), required: true),
                  _field(_phone, 'phone'.tr(), keyboard: TextInputType.phone),
                  _field(_license, 'license_number'.tr()),
                  _field(_address, 'address'.tr()),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('save_changes'.tr()),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'required_field'.tr() : null
            : null,
      ),
    );
  }
}
