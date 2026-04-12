import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dados/repositorio_agendamentos_impl.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/profissional.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/repositorios/repositorio_agendamentos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final schedulingRepositoryProvider = Provider<SchedulingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SchedulingRepositoryImpl(client);
});

final professionalsProvider = FutureProvider<List<Professional>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.listProfessionals();
});

final publishedServicesProvider = StreamProvider<List<Service>>((ref) {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.watchPublishedServices();
});

final myServicesProvider = StreamProvider<List<Service>>((ref) {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.watchMyServices();
});

final communityAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.watchCommunityAppointments();
});

final professionalTodayAppointmentsProvider = StreamProvider<List<Appointment>>(
  (ref) {
    ref.watch(authStateChangesProvider);
    final repository = ref.watch(schedulingRepositoryProvider);
    return repository.watchTodayProfessionalAppointments();
  },
);

final professionalAppointmentsProvider = StreamProvider<List<Appointment>>((
  ref,
) {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.watchProfessionalAppointments();
});

final allAppointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.watchAllAppointments();
});

final cancellationMessagesProvider = FutureProvider<List<CancellationNotice>>((
  ref,
) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(schedulingRepositoryProvider);
  return repository.consumeCancellationMessages();
});

final appointmentsNowTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream<DateTime>.periodic(
    const Duration(minutes: 1),
    (_) => DateTime.now(),
  ).startWith(DateTime.now());
});

extension _StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T initialValue) async* {
    yield initialValue;
    yield* this;
  }
}
