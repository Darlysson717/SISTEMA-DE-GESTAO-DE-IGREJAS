import 'package:centro_social_app/src/funcionalidades/administracao/dados/repositorio_admin.dart';
import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AdminRepository(client);
});

final isCurrentUserAdminProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  return repository.isCurrentUserAdmin();
});

final isCurrentUserSuperAdminProvider = Provider<bool>((ref) {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  return repository.isCurrentUserSuperAdmin;
});

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  final isAdmin = await repository.isCurrentUserAdmin();
  if (!isAdmin) {
    return [];
  }
  return repository.listAdmins();
});

final authenticatedUsersCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  final isAdmin = await repository.isCurrentUserAdmin();
  if (!isAdmin) {
    return 0;
  }

  return repository.countAuthenticatedUsers();
});

final publishAccessStateProvider = FutureProvider<PublishAccessState>((
  ref,
) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  return repository.getCurrentUserPublishAccess();
});

final pendingPublishRequestsProvider = FutureProvider<List<PublishRequest>>((
  ref,
) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  return repository.listPendingPublishRequests();
});

final authorizedPublishersProvider = FutureProvider<List<AuthorizedPublisher>>((
  ref,
) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  return repository.listAuthorizedPublishers();
});

final servicesReportProvider = FutureProvider<String>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  return repository.exportAppointmentsReport();
});

final eventsSummaryReportProvider = FutureProvider<List<int>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(adminRepositoryProvider);
  return repository.exportEventsSummaryXlsx();
});
