import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dados/repositorio_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EventsRepository(client);
});

final myEventsProvider = StreamProvider<List<AppEvent>>((ref) {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(eventsRepositoryProvider);
  return repository.watchMyEvents();
});

final publishedEventsProvider = FutureProvider<List<AppEvent>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(eventsRepositoryProvider);
  return repository.listPublishedEvents();
});

final eventRegistrationsProvider =
    StreamProvider.family<List<EventRegistrationEntry>, String>((ref, eventId) {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(eventsRepositoryProvider);
      return repository.watchEventRegistrations(eventId);
    });

final eventRegistrationStatsProvider =
    StreamProvider.family<EventRegistrationStats, String>((ref, eventId) {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(eventsRepositoryProvider);
      return repository.watchEventRegistrationStats(eventId);
    });
