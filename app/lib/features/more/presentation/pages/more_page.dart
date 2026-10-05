import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/session/session_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text('more'.tr())),
      body: ListView(
        children: [
          FutureBuilder<bool>(
            future: sl<SessionService>().isAdminOrVendor(),
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox.shrink();
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: Text('admin_dashboard'.tr()),
                    onTap: () => context.push('/admin'),
                  ),
                  const Divider(),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text('account_settings'.tr()),
            onTap: () => context.push('/account'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text('wallet'.tr()),
            onTap: () => context.push('/wallet'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            subtitle: Text(isArabic ? 'arabic'.tr() : 'english'.tr()),
            onTap: () => context.setLocale(
              isArabic ? const Locale('en') : const Locale('ar'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text('logout'.tr()),
            onTap: () {
              sl<SessionService>().clear();
              context.read<AuthCubit>().logout();
            },
          ),
        ],
      ),
    );
  }
}
