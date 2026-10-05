import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // The Supabase dashboard "anon public" key is the publishable key.
      publishableKey: Env.supabaseAnonKey,
    );
    setupLocator();
    // Guarded: no-op if Firebase isn't configured for this build.
    await sl<NotificationService>().init();
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const PharmaReserveApp(),
    ),
  );
}

class PharmaReserveApp extends StatelessWidget {
  const PharmaReserveApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) return const _NotConfiguredApp();

    final router = AppRouter(Supabase.instance.client).router;

    return BlocProvider(
      create: (_) => AuthCubit(sl<AuthRepository>()),
      child: MaterialApp.router(
        title: 'MedStock',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        routerConfig: router,
      ),
    );
  }
}

/// Shown when SUPABASE_URL / SUPABASE_ANON_KEY were not provided at build time.
class _NotConfiguredApp extends StatelessWidget {
  const _NotConfiguredApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings, size: 48),
                SizedBox(height: 16),
                Text(
                  'Supabase is not configured.\n\n'
                  'Run with:\n'
                  '--dart-define=SUPABASE_URL=...\n'
                  '--dart-define=SUPABASE_ANON_KEY=...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
