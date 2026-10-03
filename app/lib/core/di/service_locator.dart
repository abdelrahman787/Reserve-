import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/admin/data/admin_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/cart/data/cart_repository.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/orders/data/orders_repository.dart';
import '../session/session_service.dart';

final GetIt sl = GetIt.instance;

/// Registers singletons. Call after Supabase.initialize().
void setupLocator() {
  final client = Supabase.instance.client;

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => client);
    sl.registerLazySingleton(() => SessionService(client));
    sl.registerLazySingleton(() => AuthRepository(client));
    sl.registerLazySingleton(() => CatalogRepository(client));
    sl.registerLazySingleton(() => CartRepository(client));
    sl.registerLazySingleton(() => OrdersRepository(client));
    sl.registerLazySingleton(() => AdminRepository(client));
  }
}
