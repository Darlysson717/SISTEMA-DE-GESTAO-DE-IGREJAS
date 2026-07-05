import 'package:centro_social_app/src/funcionalidades/autenticacao/apresentacao/provedores/provedores_autenticacao.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dados/repositorio_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EventsRepository(client);
});

final myEventsProvider = FutureProvider<List<AppEvent>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(eventsRepositoryProvider);
  return repository.fetchMyEvents();
});

final publishedEventsProvider = FutureProvider<List<AppEvent>>((ref) async {
  ref.watch(authStateChangesProvider);
  final repository = ref.watch(eventsRepositoryProvider);
  return repository.listPublishedEvents();
});

final eventRegistrationsProvider =
    FutureProvider.family<List<EventRegistrationEntry>, String>((ref, eventId) async {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(eventsRepositoryProvider);
      return repository.fetchEventRegistrations(eventId);
    });

final eventRegistrationStatsProvider =
    FutureProvider.family<EventRegistrationStats, String>((ref, eventId) async {
      ref.watch(authStateChangesProvider);
      final repository = ref.watch(eventsRepositoryProvider);
      return repository.fetchEventRegistrationStats(eventId);
    });
