import 'dart:io';

import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum EventPersistenceMode { publish }

enum EventInterestType { participante, voluntario }

class EventRegistrationEntry {
  final String userId;
  final String displayName;
  final String? email;
  final String? volunteerWhatsapp;
  final EventInterestType interestType;

  const EventRegistrationEntry({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.volunteerWhatsapp,
    required this.interestType,
  });
}

class EventRegistrationStats {
  final int participantes;
  final int voluntarios;

  const EventRegistrationStats({
    required this.participantes,
    required this.voluntarios,
  });

  int get total => participantes + voluntarios;
}

class EventUpsertInput {
  final String nome;
  final String categoria;
  final List<String> publicoAlvo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final TimeOfDaySql? horaInicio;
  final TimeOfDaySql? horaFim;
  final bool diaInteiro;
  final String repeticao;
  final String tipoLocal;
  final String? endereco;
  final String? linkTransmissao;
  final String resumoCurto;
  final String descricao;
  final bool eventoPago;
  final int? limiteVagas;
  final bool requerInscricao;
  final String? linkInscricao;
  final bool permitirVoluntarios;
  final int? quantidadeVoluntarios;
  final String? atividadesVoluntarios;
  final String? acessibilidade;
  final String contatoNome;
  final String contatoTelefone;
  final String? contatoEmail;
  final bool agendarPublicacao;
  final DateTime? dataPublicacao;
  final XFile? imagemCapa;
  final List<String> galeriaImagensExistentes;
  final List<XFile> galeriaImagens;

  const EventUpsertInput({
    required this.nome,
    required this.categoria,
    required this.publicoAlvo,
    required this.dataInicio,
    required this.dataFim,
    required this.horaInicio,
    required this.horaFim,
    required this.diaInteiro,
    required this.repeticao,
    required this.tipoLocal,
    required this.endereco,
    required this.linkTransmissao,
    required this.resumoCurto,
    required this.descricao,
    required this.eventoPago,
    required this.limiteVagas,
    required this.requerInscricao,
    required this.linkInscricao,
    required this.permitirVoluntarios,
    required this.quantidadeVoluntarios,
    required this.atividadesVoluntarios,
    required this.acessibilidade,
    required this.contatoNome,
    required this.contatoTelefone,
    required this.contatoEmail,
    required this.agendarPublicacao,
    required this.dataPublicacao,
    required this.imagemCapa,
    required this.galeriaImagensExistentes,
    required this.galeriaImagens,
  });
}

class TimeOfDaySql {
  final int hour;
  final int minute;

  const TimeOfDaySql({required this.hour, required this.minute});

  String toSql() {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }
}

class EventsRepository {
  final SupabaseClient _client;

  const EventsRepository(this._client);

  Stream<List<AppEvent>> watchMyEvents() {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return Stream.value(const []);
    }

    return _client
        .from('eventos')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => AppEvent.fromJson(row)).toList());
  }

  Stream<List<AppEvent>> watchPublishedEvents() {
    return _client
        .from('eventos')
        .stream(primaryKey: ['id'])
        .neq('status', 'cancelado')
        .order('publicado_em', ascending: false)
        .map((rows) {
          final now = DateTime.now();
          return rows.map((row) => AppEvent.fromJson(row)).where((event) {
            if (event.status == 'publicado') {
              return true;
            }

            if (event.status == 'agendado') {
              if (event.publicadoEm == null) {
                return false;
              }
              return !event.publicadoEm!.isAfter(now);
            }

            return false;
          }).toList();
        });
  }

  Future<List<AppEvent>> listPublishedEvents() async {
    final rows = await _client
        .from('eventos')
        .select()
        .neq('status', 'cancelado')
        .order('publicado_em', ascending: false);

    final now = DateTime.now();
    return (rows as List<dynamic>)
        .map((row) => AppEvent.fromJson(row as Map<String, dynamic>))
        .where((event) {
          if (event.status == 'publicado') {
            return true;
          }

          if (event.status == 'agendado') {
            if (event.publicadoEm == null) {
              return false;
            }
            return !event.publicadoEm!.isAfter(now);
          }

          return false;
        })
        .toList();
  }

  Stream<List<EventRegistrationEntry>> watchEventRegistrations(String eventId) {
    return _client
        .from('event_registrations')
        .stream(primaryKey: ['id'])
        .eq('event_id', eventId)
        .order('created_at', ascending: true)
        .asyncMap(_attachProfilesToRegistrations);
  }

  Stream<EventRegistrationStats> watchEventRegistrationStats(String eventId) {
    return watchEventRegistrations(eventId).map((items) {
      final participantes = items
          .where((item) => item.interestType == EventInterestType.participante)
          .length;
      final voluntarios = items
          .where((item) => item.interestType == EventInterestType.voluntario)
          .length;
      return EventRegistrationStats(
        participantes: participantes,
        voluntarios: voluntarios,
      );
    });
  }

  Future<void> registerInterest({
    required String eventId,
    required EventInterestType interestType,
    String? volunteerWhatsapp,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario nao autenticado.');
    }

    if (interestType == EventInterestType.voluntario) {
      final event = await _client
          .from('eventos')
          .select('permitir_voluntarios')
          .eq('id', eventId)
          .single();

      final allowVolunteers = (event['permitir_voluntarios'] as bool?) ?? false;
      if (!allowVolunteers) {
        throw Exception('Este evento nao aceita voluntarios.');
      }

      if ((volunteerWhatsapp ?? '').trim().isEmpty) {
        throw Exception('Informe um WhatsApp para contato.');
      }
    }

    final normalizedWhatsapp = _normalizeWhatsapp(volunteerWhatsapp);

    await _client.from('event_registrations').upsert({
      'event_id': eventId,
      'user_id': currentUser.id,
      'interesse': _interestTypeToSql(interestType),
      'volunteer_whatsapp': interestType == EventInterestType.voluntario
          ? normalizedWhatsapp
          : null,
    }, onConflict: 'event_id,user_id');
  }

  Future<String> saveEvent({
    required EventUpsertInput input,
    required EventPersistenceMode mode,
    AppEvent? existingEvent,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario nao autenticado.');
    }

    final uid = currentUser.id;
    final eventPathPrefix =
        existingEvent?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final storagePrefix = '$uid/$eventPathPrefix';

    final uploadedPaths = <String>[];
    String? coverImageUrl = existingEvent?.imagemCapaUrl;
    final galleryUrls = List<String>.from(input.galeriaImagensExistentes);
    String? oldCoverToDelete;
    final removedGalleryUrls = <String>[];

    if (existingEvent != null) {
      final previous = existingEvent.galeriaImagensUrls.toSet();
      final next = input.galeriaImagensExistentes.toSet();
      removedGalleryUrls.addAll(previous.difference(next));
    }

    try {
      if (input.imagemCapa != null) {
        final ext = _safeExtension(input.imagemCapa!.path);
        final path =
            '$storagePrefix/cover_${DateTime.now().microsecondsSinceEpoch}.$ext';
        await _client.storage
            .from('eventos_images')
            .upload(path, File(input.imagemCapa!.path));
        uploadedPaths.add(path);

        final newCoverUrl = _client.storage
            .from('eventos_images')
            .getPublicUrl(path);
        if (coverImageUrl != null) {
          oldCoverToDelete = coverImageUrl;
        }
        coverImageUrl = newCoverUrl;
      }

      for (final image in input.galeriaImagens) {
        final ext = _safeExtension(image.path);
        final path =
            '$storagePrefix/gallery_${DateTime.now().microsecondsSinceEpoch}.$ext';
        await _client.storage
            .from('eventos_images')
            .upload(path, File(image.path));
        uploadedPaths.add(path);
        galleryUrls.add(
          _client.storage.from('eventos_images').getPublicUrl(path),
        );
      }

      final publishAt = _resolvePublishedAt(input, mode);
      final status = _resolveStatus(input, mode, publishAt);

      final payload = {
        'user_id': uid,
        'nome': input.nome,
        'categoria': input.categoria,
        'publico_alvo': input.publicoAlvo,
        'data_inicio': _dateOnly(input.dataInicio),
        'data_fim': _dateOnly(input.dataFim),
        'hora_inicio': input.diaInteiro ? null : input.horaInicio?.toSql(),
        'hora_fim': input.diaInteiro ? null : input.horaFim?.toSql(),
        'dia_inteiro': input.diaInteiro,
        'repeticao': input.repeticao,
        'tipo_local': input.tipoLocal,
        'endereco': _nullable(input.endereco),
        'link_transmissao': _nullable(input.linkTransmissao),
        'descricao': input.descricao,
        'imagem_capa_url': coverImageUrl,
        'galeria_imagens_urls': galleryUrls,
        'evento_pago': input.eventoPago,
        'limite_vagas': input.limiteVagas,
        'requer_inscricao': input.requerInscricao,
        'link_inscricao': input.requerInscricao
            ? _nullable(input.linkInscricao)
            : null,
        'permitir_voluntarios': input.permitirVoluntarios,
        'quantidade_voluntarios': input.permitirVoluntarios
            ? input.quantidadeVoluntarios
            : null,
        'atividades_voluntarios': input.permitirVoluntarios
            ? _nullable(input.atividadesVoluntarios)
            : null,
        'acessibilidade': _nullable(input.acessibilidade),
        'contato_nome': input.contatoNome,
        'contato_telefone': input.contatoTelefone,
        'contato_email': _nullable(input.contatoEmail),
        'agendar_publicacao': input.agendarPublicacao,
        'publicado_em': publishAt?.toIso8601String(),
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final saved = existingEvent == null
          ? await _client.from('eventos').insert(payload).select('id').single()
          : await _client
                .from('eventos')
                .update(payload)
                .eq('id', existingEvent.id)
                .eq('user_id', uid)
                .select('id')
                .single();

      if (oldCoverToDelete != null) {
        try {
          final oldPath = _extractStoragePathFromPublicUrl(oldCoverToDelete);
          if (oldPath != null) {
            await _client.storage.from('eventos_images').remove([oldPath]);
          }
        } catch (_) {}
      }

      if (removedGalleryUrls.isNotEmpty) {
        final removedPaths = removedGalleryUrls
            .map(_extractStoragePathFromPublicUrl)
            .whereType<String>()
            .toList();
        if (removedPaths.isNotEmpty) {
          try {
            await _client.storage.from('eventos_images').remove(removedPaths);
          } catch (_) {}
        }
      }

      return saved['id'] as String;
    } catch (e) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await _client.storage.from('eventos_images').remove(uploadedPaths);
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> deleteEvent(AppEvent event) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario nao autenticado.');
    }

    final removablePaths = <String>[];
    final coverPath = _extractStoragePathFromPublicUrl(event.imagemCapaUrl);
    if (coverPath != null) {
      removablePaths.add(coverPath);
    }

    for (final url in event.galeriaImagensUrls) {
      final path = _extractStoragePathFromPublicUrl(url);
      if (path != null) {
        removablePaths.add(path);
      }
    }

    await _client
        .from('eventos')
        .delete()
        .eq('id', event.id)
        .eq('user_id', currentUser.id);

    if (removablePaths.isNotEmpty) {
      try {
        await _client.storage.from('eventos_images').remove(removablePaths);
      } catch (_) {}
    }
  }

  DateTime? _resolvePublishedAt(
    EventUpsertInput input,
    EventPersistenceMode mode,
  ) {
    if (input.agendarPublicacao && input.dataPublicacao != null) {
      return input.dataPublicacao;
    }

    return DateTime.now();
  }

  String _resolveStatus(
    EventUpsertInput input,
    EventPersistenceMode mode,
    DateTime? publishedAt,
  ) {
    if (input.agendarPublicacao &&
        publishedAt != null &&
        publishedAt.isAfter(DateTime.now())) {
      return 'agendado';
    }

    return 'publicado';
  }

  String _dateOnly(DateTime dateTime) {
    final yyyy = dateTime.year.toString().padLeft(4, '0');
    final mm = dateTime.month.toString().padLeft(2, '0');
    final dd = dateTime.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _safeExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) {
      return 'jpg';
    }
    return path.substring(lastDot + 1).toLowerCase();
  }

  String? _extractStoragePathFromPublicUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf('eventos_images');
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
      return null;
    }

    final encodedPath = segments.sublist(bucketIndex + 1).join('/');
    return Uri.decodeComponent(encodedPath);
  }

  Future<List<EventRegistrationEntry>> _attachProfilesToRegistrations(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return const [];
    }

    final userIds = rows
        .map((row) => row['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final List<Map<String, dynamic>> profileRows = userIds.isEmpty
        ? const []
        : (await _client
                  .from('profiles')
                  .select('id, full_name, email')
                  .inFilter('id', userIds))
              .cast<Map<String, dynamic>>();

    final profileById = <String, Map<String, dynamic>>{};
    for (final map in profileRows) {
      final id = map['id']?.toString();
      if (id != null && id.isNotEmpty) {
        profileById[id] = map;
      }
    }

    return rows.map((row) {
      final userId = row['user_id']?.toString() ?? '';
      final profile = profileById[userId];
      final fullName = (profile?['full_name'] as String?)?.trim();
      final email = (profile?['email'] as String?)?.trim();

      return EventRegistrationEntry(
        userId: userId,
        displayName: (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (email != null && email.isNotEmpty ? email : 'Usuario'),
        email: email,
        volunteerWhatsapp: (row['volunteer_whatsapp'] as String?)?.trim(),
        interestType: _interestTypeFromSql(
          row['interesse']?.toString() ?? 'participante',
        ),
      );
    }).toList();
  }

  EventInterestType _interestTypeFromSql(String value) {
    switch (value) {
      case 'voluntario':
        return EventInterestType.voluntario;
      default:
        return EventInterestType.participante;
    }
  }

  String _interestTypeToSql(EventInterestType value) {
    switch (value) {
      case EventInterestType.voluntario:
        return 'voluntario';
      case EventInterestType.participante:
        return 'participante';
    }
  }

  String _normalizeWhatsapp(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return input;
    }

    final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return input;
    }

    if (digitsOnly.startsWith('55')) {
      return digitsOnly;
    }

    return '55$digitsOnly';
  }
}
