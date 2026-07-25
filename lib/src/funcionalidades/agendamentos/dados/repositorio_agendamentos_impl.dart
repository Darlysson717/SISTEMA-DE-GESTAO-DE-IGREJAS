// ignore_for_file: avoid_print

import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/profissional.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/repositorios/repositorio_agendamentos.dart';
import 'package:centro_social_app/src/nucleo/notificacoes/servico_notificacoes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {
  final SupabaseClient _client;
  final ServicoNotificacoes _notificacoes = ServicoNotificacoes();

  SchedulingRepositoryImpl(this._client);

  @override
  Future<List<Professional>> listProfessionals({String? specialty}) async {
    final baseQuery = _client
        .from('professional_profiles')
        .select('''
          user_id,
          specialty,
          is_active,
          profiles:profiles!professional_profiles_user_id_fkey(id, full_name, email),
          professional_availabilities(id, day_of_week, start_time, end_time)
        ''')
        .eq('is_active', true);

    final rows = specialty != null && specialty.trim().isNotEmpty
        ? await baseQuery.eq('specialty', specialty.trim()).order('specialty')
        : await baseQuery.order('specialty');

    return (rows as List<dynamic>).map(_mapProfessional).toList();
  }

  @override
  Future<List<Service>> listPublishedServices() async {
    final rows = await _client
        .from('servicos')
        .select()
        .eq('status', 'ativo')
        .order('created_at', ascending: false);

    print('DEBUG: Found ${rows.length} published services');
    if (rows.isNotEmpty) {
      print('DEBUG: First service: ${rows[0]}');
    }

    return (rows as List<dynamic>).map((row) => Service.fromJson(row)).toList();
  }

  @override
  Stream<List<Service>> watchPublishedServices() {
    return _client
        .from('servicos')
        .stream(primaryKey: ['id'])
        .eq('status', 'ativo')
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => Service.fromJson(row)).toList());
  }

  @override
  Future<List<Service>> listMyServices() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('servicos')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map((row) => Service.fromJson(row)).toList();
  }

  @override
  Stream<List<Service>> watchMyServices() {
    final uid = _client.auth.currentUser!.id;
    return _client
        .from('servicos')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((row) => Service.fromJson(row)).toList());
  }

  @override
  Future<void> deleteService(String serviceId) async {
    final uid = _client.auth.currentUser!.id;
    final serviceRow = await _client
        .from('servicos')
        .select('id, imagem_profissional')
        .eq('id', serviceId)
        .eq('user_id', uid)
        .maybeSingle();

    if (serviceRow == null) {
      return;
    }

    final imageUrl = serviceRow['imagem_profissional'] as String?;
    final imagePath = _extractStoragePathFromPublicUrl(imageUrl);

    // 🔴 CONSULTAR USUÁRIOS ANTES de deletar os appointments
    final affectedUserIds = await _obterUsuariosAfetados(serviceId: serviceId);

    await _client.from('appointments').delete().eq('service_id', serviceId);

    await _client
        .from('servicos')
        .delete()
        .eq('id', serviceId)
        .eq('user_id', uid);

    if (imagePath != null) {
      await _client.storage.from('servicos_images').remove([imagePath]);
    }

    // Notificar usuários afetados (dados já foram consultados antes do delete)
    if (affectedUserIds.isNotEmpty) {
      await _notificacoes.enviarParaUsuarios(
        userIds: affectedUserIds,
        titulo: 'Serviço Cancelado',
        corpo: 'O serviço que você agendou foi removido. Seu agendamento foi cancelado.',
        dados: {
          'tipo': 'cancelamento_servico',
          'service_id': serviceId,
        },
      );
    }
  }

  /// Consulta os IDs dos usuários com agendamentos ativos no serviço
  /// ANTES de deletar os registros
  Future<List<String>> _obterUsuariosAfetados({
    required String serviceId,
  }) async {
    try {
      final appointments = await _client
          .from('appointments')
          .select('user_id')
          .eq('service_id', serviceId)
          .inFilter('status', ['agendado']);

      return (appointments as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['user_id'] as String?)
          .whereType<String>()
          .toList();
    } catch (e) {
      print('Erro ao consultar usuários afetados: $e');
      return [];
    }
  }

  String? _extractStoragePathFromPublicUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      return null;
    }

    final segments = uri.pathSegments;
    final bucketIndex = segments.indexOf('servicos_images');
    if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
      return null;
    }

    return segments[bucketIndex + 1];
  }

  @override
  Future<void> upsertProfessionalByEmail({
    required String email,
    required String specialty,
    required bool isActive,
  }) async {
    final profile = await _client
        .from('profiles')
        .select('id')
        .eq('email', email.trim().toLowerCase())
        .maybeSingle();

    if (profile == null) {
      throw Exception('Perfil não encontrado para o e-mail informado.');
    }

    final profileId = profile['id'] as String;

    await _client.from('profiles').update({'role': 'volunteer'}).eq('id', profileId);

    await _client.from('professional_profiles').upsert({
      'user_id': profileId,
      'specialty': specialty.trim(),
      'is_active': isActive,
    }, onConflict: 'user_id');
  }

  @override
  Future<void> addAvailability({
    required String professionalId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    await _client.from('professional_availabilities').insert({
      'professional_id': professionalId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    });
  }

  @override
  Future<void> removeAvailability(String availabilityId) async {
    await _client
        .from('professional_availabilities')
        .delete()
        .eq('id', availabilityId);
  }

  @override
  Future<List<Appointment>> listCommunityAppointments() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    final uid = currentUser.id;
    final rows = await _client
        .from('appointments')
        .select('''
          id,
          service_id,
          user_id,
          scheduled_date,
          scheduled_time,
          status,
          notes,
          servicos:servicos(
            id,
            user_id,
            nome,
            categoria,
            nome_profissional,
            duracao_atendimento,
            tipo_atendimento,
            local,
            telefone,
            observacoes
          )
        ''')
        .eq('user_id', uid)
        .order('scheduled_date')
        .order('scheduled_time');

    return _mapAppointmentsWithServiceInfo(rows as List<dynamic>);
  }

  @override
  Stream<List<Appointment>> watchCommunityAppointments() {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    final uid = currentUser.id;
    return _client
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('scheduled_date')
        .order('scheduled_time')
        .asyncMap(_mapAppointmentsWithServiceInfoFromRows);
  }

  @override
  Future<List<Appointment>> listTodayProfessionalAppointments() async {
    final uid = _client.auth.currentUser!.id;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateValue = today.toIso8601String().split('T').first;

    final rows = await _client
        .from('appointments')
        .select('''
          id,
          service_id,
          user_id,
          scheduled_date,
          scheduled_time,
          status,
          notes,
          servicos:servicos!inner(
            id,
            user_id,
            nome,
            categoria,
            nome_profissional,
            duracao_atendimento,
            tipo_atendimento,
            local,
            telefone,
            observacoes
          )
        ''')
        .eq('servicos.user_id', uid)
        .eq('scheduled_date', dateValue)
        .order('scheduled_time');

    return _mapAppointmentsWithServiceInfo(rows as List<dynamic>);
  }

  @override
  Stream<List<Appointment>> watchTodayProfessionalAppointments() {
    final uid = _client.auth.currentUser!.id;
    return _client
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('servicos.user_id', uid)
        .order('scheduled_date')
        .order('scheduled_time')
        .asyncMap((rows) async {
          final appointments = await _mapAppointmentsWithServiceInfoFromRows(rows);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          return appointments.where((item) {
            final itemDate = DateTime(
              item.startsAt.year,
              item.startsAt.month,
              item.startsAt.day,
            );
            return itemDate == today && item.professionalId == uid;
          }).toList();
        });
  }

  @override
  Future<List<Appointment>> listProfessionalAppointments() async {
    final uid = _client.auth.currentUser!.id;
    final rows = await _client
        .from('appointments')
        .select('''
          id,
          service_id,
          user_id,
          scheduled_date,
          scheduled_time,
          status,
          notes,
          servicos:servicos!inner(
            id,
            user_id,
            nome,
            categoria,
            nome_profissional,
            duracao_atendimento,
            tipo_atendimento,
            local,
            telefone,
            observacoes
          )
        ''')
        .eq('servicos.user_id', uid)
        .order('scheduled_date')
        .order('scheduled_time');

    return _mapAppointmentsWithServiceInfo(rows as List<dynamic>);
  }

  @override
  Stream<List<Appointment>> watchProfessionalAppointments() {
    final uid = _client.auth.currentUser!.id;
    return _client
        .from('appointments')
        .stream(primaryKey: ['id'])
        .order('scheduled_date')
        .order('scheduled_time')
        .asyncMap((rows) async {
          final appointments = await _mapAppointmentsWithServiceInfoFromRows(rows);
          return appointments.where((item) => item.professionalId == uid).toList();
        });
  }

  @override
  Future<List<Appointment>> listAllAppointments() async {
    final rows = await _client
        .from('appointments')
        .select('''
          id,
          service_id,
          user_id,
          scheduled_date,
          scheduled_time,
          status,
          notes,
          servicos:servicos(
            id,
            user_id,
            nome,
            categoria,
            nome_profissional,
            duracao_atendimento,
            tipo_atendimento,
            local,
            telefone,
            observacoes
          )
        ''')
        .order('scheduled_date', ascending: false)
        .order('scheduled_time', ascending: false);

    return _mapAppointmentsWithServiceInfo(rows as List<dynamic>);
  }

  @override
  Stream<List<Appointment>> watchAllAppointments() {
    return _client
        .from('appointments')
        .stream(primaryKey: ['id'])
        .order('scheduled_date', ascending: false)
        .order('scheduled_time', ascending: false)
        .asyncMap(_mapAppointmentsWithServiceInfoFromRows);
  }

  @override
  Future<void> createAppointment({
    required DateTime startsAt,
    required String serviceId,
  }) async {
    final uid = _client.auth.currentUser!.id;

    final appointmentDate = DateTime(
      startsAt.year,
      startsAt.month,
      startsAt.day,
    );
    final dateValue = appointmentDate.toIso8601String().split('T').first;
    final timeValue = _formatTimeForDb(startsAt);

    final existingAppointments = await _client
        .from('appointments')
        .select('service_id, scheduled_time')
        .eq('user_id', uid)
        .eq('scheduled_date', dateValue)
        .neq('status', 'cancelado');

    final existingList = (existingAppointments as List<dynamic>);
    final hasSameService = existingList.any(
      (row) => (row as Map<String, dynamic>)['service_id'] == serviceId,
    );
    if (hasSameService) {
      throw Exception(
        'Você já possui um agendamento para este serviço neste dia.',
      );
    }

    final hasTimeConflict = existingList.any(
      (row) => (row as Map<String, dynamic>)['scheduled_time'] == timeValue,
    );
    if (hasTimeConflict) {
      throw Exception('Você já possui um agendamento neste mesmo horário.');
    }

    final occupiedByOtherUser = await _client
        .from('appointments')
        .select('id')
        .eq('service_id', serviceId)
        .eq('scheduled_date', dateValue)
        .eq('scheduled_time', timeValue)
        .inFilter('status', ['agendado'])
        .limit(1)
        .maybeSingle();

    if (occupiedByOtherUser != null) {
      throw Exception(
        'Este horário já está indisponível, pois foi agendado por outra pessoa.',
      );
    }

    try {
      await _client.from('appointments').insert({
        'user_id': uid,
        'service_id': serviceId,
        'scheduled_date': dateValue,
        'scheduled_time': timeValue,
        'status': 'agendado',
      });

      await _enviarNotificacaoNovoAgendamento(
        serviceId: serviceId,
        communityUserId: uid,
        scheduledDate: dateValue,
        scheduledTime: timeValue,
      );
    } catch (error) {
      final errorMessage = error.toString();
      if (errorMessage.contains('appointments_unique_active_slot') ||
          errorMessage.contains(
            'duplicate key value violates unique constraint',
          ) ||
          errorMessage.contains('23505')) {
        throw Exception(
          'Este horário já está indisponível, pois foi agendado por outra pessoa.',
        );
      }
      rethrow;
    }
  }

  Future<void> _enviarNotificacaoNovoAgendamento({
    required String serviceId,
    required String communityUserId,
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    try {
      final service = await _client
          .from('servicos')
          .select('user_id, nome_profissional, categoria, local, tipo_atendimento')
          .eq('id', serviceId)
          .maybeSingle();

      if (service == null) return;

      final professionalId = service['user_id'] as String?;
      if (professionalId == null) return;

      final communityProfile = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', communityUserId)
          .maybeSingle();

      final userName = communityProfile?['full_name'] as String? ?? 'Um usuário';
      final categoria = service['categoria'] as String? ?? '';
      final nomeProfissional = service['nome_profissional'] as String? ?? 'Profissional';
      final local = service['local'] as String?;
      final tipoAtendimento = service['tipo_atendimento'] as String?;

      // Formata data para exibição
      final dateParts = scheduledDate.split('-');
      final dataFormatada = dateParts.length == 3
          ? '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}'
          : scheduledDate;
      final horaFormatada = scheduledTime.length >= 5
          ? scheduledTime.substring(0, 5)
          : scheduledTime;

      // 🔒 NOTIFICAÇÃO SINCRONIZADA: Profissional ← Novo agendamento
      await _notificacoes.enviarNotificacaoSincronizada(
        usuarioId: professionalId,
        titulo: 'Novo Agendamento',
        corpo: '$userName agendou $categoria para $dataFormatada às $horaFormatada',
        tipo: 'agendamento',
        dados: {
          'tipo': 'novo_agendamento',
          'service_id': serviceId,
          'scheduled_date': scheduledDate,
          'scheduled_time': scheduledTime,
        },
      );

      // 🔒 NOTIFICAÇÃO SINCRONIZADA: Usuário ← Confirmação do agendamento
      await _notificacoes.enviarNotificacaoSincronizada(
        usuarioId: communityUserId,
        titulo: 'Agendamento Confirmado',
        corpo: 'Seu agendamento de $categoria com $nomeProfissional foi confirmado para $dataFormatada às $horaFormatada.',
        tipo: 'agendamento',
        dados: {
          'tipo': 'confirmacao_agendamento',
          'service_id': serviceId,
          'scheduled_date': scheduledDate,
          'scheduled_time': scheduledTime,
          'local': local,
          'tipo_atendimento': tipoAtendimento,
        },
      );
    } catch (e) {
      print('Erro ao enviar notificação de novo agendamento: $e');
    }
  }

  @override
  Future<Set<String>> listBookedTimesForServiceOnDate({
    required String serviceId,
    required DateTime date,
  }) async {
    final dateValue = DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().split('T').first;

    List<dynamic> rows;
    try {
      // Tenta usar o RPC primeiro (security definer - funciona entre usuários)
      final result = await _client
          .rpc(
            'get_service_booked_times',
            params: {
              'p_service_id': serviceId,
              'p_scheduled_date': dateValue,
            },
          );
      rows = result as List<dynamic>;
    } catch (_) {
      try {
        // Fallback 1: consulta direta (pode ser limitada por RLS)
        rows = await _client
            .from('appointments')
            .select('scheduled_time')
            .eq('service_id', serviceId)
            .eq('scheduled_date', dateValue)
            .inFilter('status', ['agendado']);
      } catch (_) {
        // Fallback 2: usa o usuário atual para buscar agendamentos do mesmo serviço
        rows = await _client
            .from('appointments')
            .select('scheduled_time')
            .eq('service_id', serviceId)
            .eq('scheduled_date', dateValue)
            .neq('status', 'cancelado');
      }
    }

    final bookedTimes = <String>{};
    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      final raw = (map['scheduled_time'] as String?)?.trim();
      if (raw == null || raw.isEmpty) {
        continue;
      }
      final parts = raw.split(':');
      if (parts.length < 2) {
        continue;
      }
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      bookedTimes.add('$hour:$minute');
    }

    return bookedTimes;
  }

  @override
  Future<void> cancelAppointment(String appointmentId) async {
    final currentUid = _client.auth.currentUser?.id;
    if (currentUid == null) {
      throw Exception('Usuário não autenticado.');
    }

    final appointment = await _client
        .from('appointments')
        .select('id, user_id, service_id, scheduled_date, scheduled_time')
        .eq('id', appointmentId)
        .maybeSingle();

    if (appointment == null) {
      throw Exception('Agendamento não encontrado.');
    }

    final communityUserId = appointment['user_id'] as String?;
    final serviceId = appointment['service_id'] as String?;

    var cancelledByProfessional = false;
    String? nomeProfissional;
    String? categoria;
    String? local;
    if (serviceId != null) {
      final service = await _client
          .from('servicos')
          .select('user_id, nome_profissional, categoria, local')
          .eq('id', serviceId)
          .maybeSingle();
      final serviceOwnerId = service?['user_id'] as String?;
      nomeProfissional = service?['nome_profissional'] as String?;
      categoria = service?['categoria'] as String?;
      local = service?['local'] as String?;
      cancelledByProfessional =
          serviceOwnerId != null &&
          serviceOwnerId == currentUid &&
          communityUserId != null &&
          communityUserId != currentUid;
    }

    final updatedRows = await _client
        .from('appointments')
        .update({
          'status': 'cancelado',
          'cancelled_at': DateTime.now().toIso8601String(),
          'cancelled_by': currentUid,
        })
        .eq('id', appointmentId)
        .select('id');

    final rows = (updatedRows as List<dynamic>);
    if (rows.isEmpty) {
      throw Exception(
        'Não foi possível cancelar este agendamento. Verifique as permissões e tente novamente.',
      );
    }

    if (serviceId != null) {
      await _enviarNotificacaoCancelamento(
        serviceId: serviceId,
        appointmentId: appointmentId,
        communityUserId: communityUserId,
        cancelledByProfessional: cancelledByProfessional,
        nomeProfissional: nomeProfissional,
        categoria: categoria,
        local: local,
      );
    }
  }

  Future<void> _enviarNotificacaoCancelamento({
    required String serviceId,
    required String appointmentId,
    required String? communityUserId,
    required bool cancelledByProfessional,
    String? nomeProfissional,
    String? categoria,
    String? local,
  }) async {
    try {
      final service = await _client
          .from('servicos')
          .select('user_id, nome_profissional, categoria')
          .eq('id', serviceId)
          .maybeSingle();

      if (service == null) return;

      final professionalId = service['user_id'] as String?;
      if (professionalId == null) return;

      final cat = categoria ?? service['categoria'] as String? ?? '';
      final nomeProf = nomeProfissional ?? service['nome_profissional'] as String? ?? 'Profissional';

      // 🔒 NOTIFICAÇÃO SINCRONIZADA: Profissional ← Usuário cancelou
      if (!cancelledByProfessional && communityUserId != null) {
        final communityProfile = await _client
            .from('profiles')
            .select('full_name')
            .eq('id', communityUserId)
            .maybeSingle();
        final userName = communityProfile?['full_name'] as String? ?? 'Um usuário';

        await _notificacoes.enviarNotificacaoSincronizada(
          usuarioId: professionalId,
          titulo: 'Agendamento Cancelado',
          corpo: '$userName cancelou o agendamento de $cat.',
          tipo: 'agendamento',
          dados: {
            'tipo': 'cancelamento_agendamento',
            'appointment_id': appointmentId,
            'service_id': serviceId,
          },
        );
      }

      // 🔒 NOTIFICAÇÃO SINCRONIZADA: Usuário ← Profissional cancelou
      if (cancelledByProfessional && communityUserId != null) {
        await _notificacoes.enviarNotificacaoSincronizada(
          usuarioId: communityUserId,
          titulo: 'Agendamento Cancelado',
          corpo: 'O profissional $nomeProf cancelou seu agendamento de $cat.',
          tipo: 'agendamento',
          dados: {
            'tipo': 'cancelado_pelo_profissional',
            'appointment_id': appointmentId,
            'service_id': serviceId,
          },
        );
      }
    } catch (e) {
      print('Erro ao enviar notificação de cancelamento: $e');
    }
  }

  @override
  Future<void> completeAppointment(String appointmentId) async {
    final currentUid = _client.auth.currentUser?.id;
    if (currentUid == null) {
      throw Exception('Usuário não autenticado.');
    }

    final appointment = await _client
        .from('appointments')
        .select('id, user_id, service_id')
        .eq('id', appointmentId)
        .maybeSingle();

    if (appointment == null) {
      throw Exception('Agendamento não encontrado.');
    }

    final communityUserId = appointment['user_id'] as String?;
    final serviceId = appointment['service_id'] as String?;

    await _client
        .from('appointments')
        .update({'status': 'concluido'})
        .eq('id', appointmentId);

    // 🔒 NOTIFICAÇÃO PRIVADA 5: Usuário ← Atendimento concluído
    if (serviceId != null && communityUserId != null) {
      try {
        final service = await _client
            .from('servicos')
            .select('user_id, nome_profissional, categoria')
            .eq('id', serviceId)
            .maybeSingle();

        final professionalId = service?['user_id'] as String?;
        final nomeProf = service?['nome_profissional'] as String? ?? 'Profissional';
        final cat = service?['categoria'] as String? ?? '';

        // 🔒 NOTIFICAÇÃO SINCRONIZADA: Usuário ← Atendimento concluído
        await _notificacoes.enviarNotificacaoSincronizada(
          usuarioId: communityUserId,
          titulo: 'Atendimento Concluído',
          corpo: 'Seu atendimento de $cat com $nomeProf foi concluído com sucesso.',
          tipo: 'agendamento',
          dados: {
            'tipo': 'atendimento_concluido',
            'appointment_id': appointmentId,
            'service_id': serviceId,
          },
        );

        // 🔒 NOTIFICAÇÃO SINCRONIZADA: Profissional ← Atendimento concluído
        if (professionalId != null && professionalId != communityUserId) {
          await _notificacoes.enviarNotificacaoSincronizada(
            usuarioId: professionalId,
            titulo: 'Atendimento Concluído',
            corpo: 'O atendimento de $cat foi concluído com sucesso.',
            tipo: 'agendamento',
            dados: {
              'tipo': 'atendimento_concluido',
              'appointment_id': appointmentId,
            },
          );
        }
      } catch (e) {
        print('Erro ao notificar conclusão: $e');
      }
    }
  }

  @override
  Future<List<CancellationNotice>> consumeCancellationMessages() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return [];
    }

    List<dynamic> rows;
    try {
      rows = await _client
          .from('appointment_cancellation_messages')
          .select(
            'id, message, scheduled_at, professional_name, specialty, location',
          )
          .eq('recipient_user_id', uid)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(20);
    } catch (_) {
      rows = await _client
          .from('appointment_cancellation_messages')
          .select('id, message')
          .eq('recipient_user_id', uid)
          .eq('is_read', false)
          .order('created_at', ascending: false)
          .limit(20);
    }

    final list = rows.map((item) => item as Map<String, dynamic>).toList();
    if (list.isEmpty) {
      return [];
    }

    final ids = list
        .map((item) => item['id'] as String?)
        .whereType<String>()
        .toList();
    if (ids.isNotEmpty) {
      await _client
          .from('appointment_cancellation_messages')
          .update({'is_read': true})
          .inFilter('id', ids);
    }

    return list
        .map((item) {
          final message = (item['message'] as String?)?.trim() ?? '';
          final scheduledAt = DateTime.tryParse(
            (item['scheduled_at'] as String?) ?? '',
          );
          return CancellationNotice(
            message: message,
            scheduledAt: scheduledAt,
            professionalName: item['professional_name'] as String?,
            specialty: item['specialty'] as String?,
            location: item['location'] as String?,
          );
        })
        .where((notice) => notice.message.isNotEmpty)
        .toList();
  }

  @override
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime startsAt,
    required String serviceId,
  }) async {
    final dateValue = startsAt.toIso8601String().split('T').first;
    final timeValue = _formatTimeForDb(startsAt);
    await _client
        .from('appointments')
        .update({
          'scheduled_date': dateValue,
          'scheduled_time': timeValue,
          'service_id': serviceId,
          'status': 'agendado',
        })
        .eq('id', appointmentId);

    // 🔒 NOTIFICAÇÃO PRIVADA: Notificar reagendamento
    try {
      final appointment = await _client
          .from('appointments')
          .select('user_id, service_id')
          .eq('id', appointmentId)
          .maybeSingle();

      final communityUserId = appointment?['user_id'] as String?;
      if (serviceId.isNotEmpty && communityUserId != null) {
        final service = await _client
            .from('servicos')
            .select('user_id, nome_profissional, categoria')
            .eq('id', serviceId)
            .maybeSingle();

        final professionalId = service?['user_id'] as String?;
        final nomeProf = service?['nome_profissional'] as String? ?? 'Profissional';
        final cat = service?['categoria'] as String? ?? '';

        final dateParts = dateValue.split('-');
        final dataFormatada = dateParts.length == 3
            ? '${dateParts[2]}/${dateParts[1]}/${dateParts[0]}'
            : dateValue;
        final horaFormatada = timeValue.length >= 5
            ? timeValue.substring(0, 5)
            : timeValue;

        // Notificar usuário sobre reagendamento
        await _notificacoes.enviarParaUsuario(
          userId: communityUserId,
          titulo: 'Agendamento Reagendado',
          corpo: 'Seu agendamento de $cat com $nomeProf foi alterado para $dataFormatada às $horaFormatada.',
          dados: {
            'tipo': 'reagendamento',
            'appointment_id': appointmentId,
            'scheduled_date': dateValue,
            'scheduled_time': timeValue,
          },
        );

        // 📋 NOTIFICAÇÃO IN-APP: Usuário
        await _notificacoes.criarNotificacaoInApp(
          usuarioId: communityUserId,
          titulo: 'Agendamento Reagendado',
          corpo: 'Seu agendamento de $cat com $nomeProf foi alterado para $dataFormatada às $horaFormatada.',
          tipo: 'agendamento',
          dados: {
            'tipo': 'reagendamento',
            'appointment_id': appointmentId,
          },
        );

        // Notificar profissional sobre reagendamento
        if (professionalId != null && professionalId != communityUserId) {
          final communityProfile = await _client
              .from('profiles')
              .select('full_name')
              .eq('id', communityUserId)
              .maybeSingle();
          final userName = communityProfile?['full_name'] as String? ?? 'Um usuário';

          await _notificacoes.enviarParaUsuario(
            userId: professionalId,
            titulo: 'Agendamento Reagendado',
            corpo: '$userName reagendou $cat para $dataFormatada às $horaFormatada.',
            dados: {
              'tipo': 'reagendamento',
              'appointment_id': appointmentId,
              'scheduled_date': dateValue,
              'scheduled_time': timeValue,
            },
          );

          // 📋 NOTIFICAÇÃO IN-APP: Profissional
          await _notificacoes.criarNotificacaoInApp(
            usuarioId: professionalId,
            titulo: 'Agendamento Reagendado',
            corpo: '$userName reagendou $cat para $dataFormatada às $horaFormatada.',
            tipo: 'agendamento',
            dados: {
              'tipo': 'reagendamento',
              'appointment_id': appointmentId,
            },
          );
        }
      }
    } catch (e) {
      print('Erro ao notificar reagendamento: $e');
    }
  }

  @override
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required AppointmentStatus status,
  }) async {
    await _client
        .from('appointments')
        .update({'status': status.value})
        .eq('id', appointmentId);

    if (status == AppointmentStatus.completed) {
      await completeAppointment(appointmentId);
    }
  }

  Professional _mapProfessional(dynamic row) {
    final map = row as Map<String, dynamic>;
    final profile = map['profiles'] as Map<String, dynamic>?;
    final availabilitiesRaw =
        (map['professional_availabilities'] as List<dynamic>? ?? []);

    return Professional(
      id: map['user_id'] as String,
      name: (profile?['full_name'] as String?) ?? 'Profissional',
      email: (profile?['email'] as String?) ?? '',
      specialty: map['specialty'] as String,
      isActive: map['is_active'] as bool? ?? true,
      availabilities: availabilitiesRaw
          .map(
            (item) => ProfessionalAvailability(
              id: item['id'] as String,
              dayOfWeek: item['day_of_week'] as int,
              startTime: (item['start_time'] as String).substring(0, 5),
              endTime: (item['end_time'] as String).substring(0, 5),
            ),
          )
          .toList(),
    );
  }

  Future<List<Appointment>> _mapAppointmentsWithServiceInfo(
    List<dynamic> rows,
  ) async {
    final profileIds = <String>{};
    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      profileIds.add(map['user_id'] as String);
      final service = map['servicos'] as Map<String, dynamic>?;
      final serviceOwnerId = service?['user_id'] as String?;
      if (serviceOwnerId != null) {
        profileIds.add(serviceOwnerId);
      }
    }

    final profiles = await _fetchProfilesDisplay(profileIds.toList());

    return rows
        .map(
          (item) => _mapAppointmentWithServiceInfo(
            item as Map<String, dynamic>,
            profiles,
          ),
        )
        .toList();
  }

  Appointment _mapAppointmentWithServiceInfo(
    Map<String, dynamic> map,
    Map<String, _ProfileDisplay> profiles,
  ) {
    final service = map['servicos'] as Map<String, dynamic>?;
    return _buildAppointmentFromData(map, service, profiles);
  }

  String _formatTimeForDb(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Future<Map<String, _ProfileDisplay>> _fetchProfilesDisplay(
    List<String> ids,
  ) async {
    if (ids.isEmpty) {
      return {};
    }

    List<dynamic> rows;
    try {
      rows = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', ids);
    } catch (_) {
      rows = await _client
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', ids);
    }

    final result = <String, _ProfileDisplay>{};
    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      final id = map['id'] as String;
      final name = (map['full_name'] as String?) ?? 'Usuário';
      final avatarUrl = (map['avatar_url'] as String?)?.trim();
      result[id] = _ProfileDisplay(
        name: name,
        avatarUrl: (avatarUrl?.isEmpty ?? true) ? null : avatarUrl,
      );
    }
    return result;
  }

  Future<List<Appointment>> _mapAppointmentsWithServiceInfoFromRows(
    List<dynamic> rows,
  ) async {
    if (rows.isEmpty) {
      return [];
    }

    final appointmentMaps = rows.cast<Map<String, dynamic>>();
    final serviceIds = appointmentMaps
        .map((item) => item['service_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final List<dynamic> servicesRows;
    if (serviceIds.isEmpty) {
      servicesRows = const [];
    } else {
      servicesRows = await _client
          .from('servicos')
          .select('''
            id,
            user_id,
            nome,
            categoria,
            nome_profissional,
            duracao_atendimento,
            tipo_atendimento,
            local,
            telefone,
            observacoes
          ''')
          .inFilter('id', serviceIds);
    }

    final servicesById = <String, Map<String, dynamic>>{};
    for (final row in servicesRows) {
      final map = row as Map<String, dynamic>;
      servicesById[map['id'] as String] = map;
    }

    final profileIds = <String>{};
    for (final appointment in appointmentMaps) {
      final userId = appointment['user_id'] as String?;
      if (userId != null) {
        profileIds.add(userId);
      }
      final serviceId = appointment['service_id'] as String?;
      final service = serviceId != null ? servicesById[serviceId] : null;
      final serviceOwnerId = service?['user_id'] as String?;
      if (serviceOwnerId != null) {
        profileIds.add(serviceOwnerId);
      }
    }

    final profiles = await _fetchProfilesDisplay(profileIds.toList());

    return appointmentMaps.map((appointment) {
      final serviceId = appointment['service_id'] as String?;
      final service = serviceId != null ? servicesById[serviceId] : null;
      return _buildAppointmentFromData(appointment, service, profiles);
    }).toList();
  }

  Appointment _buildAppointmentFromData(
    Map<String, dynamic> appointment,
    Map<String, dynamic>? service,
    Map<String, _ProfileDisplay> profiles,
  ) {
    final serviceOwnerId = service?['user_id'] as String?;
    final userId = appointment['user_id'] as String? ?? '';
    final dateValue = appointment['scheduled_date'] as String? ?? '1970-01-01';
    final timeValue = appointment['scheduled_time'] as String? ?? '00:00:00';
    final timeParts = timeValue.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final dateParts = dateValue.split('-');
    final year = int.tryParse(dateParts[0]) ?? 1970;
    final month = int.tryParse(dateParts[1]) ?? 1;
    final day = int.tryParse(dateParts[2]) ?? 1;
    final startsAt = DateTime(year, month, day, hour, minute);
    final duration = service?['duracao_atendimento'] as int? ?? 60;
    final endsAt = startsAt.add(Duration(minutes: duration));

    final communityProfile = profiles[userId];
    final professionalProfile = serviceOwnerId == null
        ? null
        : profiles[serviceOwnerId];

    return Appointment(
      id: appointment['id'] as String,
      serviceId: appointment['service_id'] as String? ?? '',
      professionalId: serviceOwnerId ?? '',
      professionalName:
          (service?['nome_profissional'] as String?) ??
          (professionalProfile?.name ?? 'Profissional'),
      communityUserId: userId,
      communityUserName: communityProfile?.name ?? 'Comunidade',
      communityUserPhotoUrl: communityProfile?.avatarUrl,
      specialty: (service?['categoria'] as String?) ?? 'Serviço',
      startsAt: startsAt,
      endsAt: endsAt,
      status: parseAppointmentStatus(
        (appointment['status'] as String?) ?? 'agendado',
      ),
      serviceType: service?['tipo_atendimento'] as String?,
      location: service?['local'] as String?,
      phone: service?['telefone'] as String?,
      notes: appointment['notes'] as String?,
    );
  }
}

class _ProfileDisplay {
  final String name;
  final String? avatarUrl;

  const _ProfileDisplay({required this.name, required this.avatarUrl});
}