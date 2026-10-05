import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _pharmacyName = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _license = TextEditingController();
  final _address = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _pharmacyName,
      _fullName,
      _phone,
      _email,
      _password,
      _license,
      _address,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().register(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            phone: _phone.text.trim(),
            pharmacyName: _pharmacyName.text.trim(),
            licenseNumber: _license.text.trim(),
            address: _address.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('create_account'.tr())),
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? 'error'.tr())),
              );
            }
            if (state.isAuthenticated) context.go('/home');
          },
          builder: (context, state) {
            final loading = state.status == AuthStatus.loading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _field(_pharmacyName, 'pharmacy_name'.tr(), required: true),
                      _field(_fullName, 'full_name'.tr(), required: true),
                      _field(_phone, 'phone'.tr(),
                          required: true, keyboard: TextInputType.phone),
                      _field(_email, 'email'.tr(),
                          required: true, keyboard: TextInputType.emailAddress),
                      _field(_password, 'password'.tr(),
                          required: true, obscure: true),
                      _field(_license, 'license_number'.tr()),
                      _field(_address, 'address'.tr()),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text('register'.tr()),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'required_field'.tr() : null
            : null,
      ),
    );
  }
}
