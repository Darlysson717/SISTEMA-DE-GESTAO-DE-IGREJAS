// ignore_for_file: avoid_print

import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/agendamento.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/profissional.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/repositorios/repositorio_agendamentos.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SchedulingRepositoryImpl implements SchedulingRepository {
  final SupabaseClient _client;

  const SchedulingRepositoryImpl(this._client);

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

    await _client.from('appointments').delete().eq('service_id', serviceId);

    await _client
        .from('servicos')
        .delete()
        .eq('id', serviceId)
        .eq('user_id', uid);

    if (imagePath != null) {
      await _client.storage.from('servicos_images').remove([imagePath]);
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

    final encodedPath = segments.sublist(bucketIndex + 1).join('/');
    return Uri.decodeComponent(encodedPath);
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
        .eq('email', email.trim())
        .maybeSingle();

    if (profile == null) {
      throw Exception('Usuário com esse e-mail não encontrado em profiles.');
    }

    final profileId = profile['id'] as String;

    await _client
        .from('profiles')
        .update({'role': 'volunteer'})
        .eq('id', profileId);

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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateValue = today.toIso8601String().split('T').first;

    return _client
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('scheduled_date', dateValue)
        .order('scheduled_time')
        .asyncMap((rows) async {
          final filtered = rows.where((row) {
            final serviceId = row['service_id'] as String?;
            return serviceId != null;
          }).toList();

          final appointments = await _mapAppointmentsWithServiceInfoFromRows(
            filtered,
          );
          return appointments
              .where((item) => item.professionalId == uid)
              .toList();
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
          final appointments = await _mapAppointmentsWithServiceInfoFromRows(
            rows,
          );
          return appointments
              .where((item) => item.professionalId == uid)
              .toList();
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

    // Verificar se o usuário já tem agendamento no mesmo dia
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

      // Enviar notificação push para o profissional
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
      // Buscar informações do serviço e profissional
      final service = await _client
          .from('servicos')
          .select('user_id, nome_profissional, categoria')
          .eq('id', serviceId)
          .maybeSingle();

      if (service == null) return;

      final professionalId = service['user_id'] as String?;
      if (professionalId == null) return;

      // Buscar token FCM do profissional
      final professionalProfile = await _client
          .from('professional_profiles')
          .select('fcm_token')
          .eq('user_id', professionalId)
          .maybeSingle();

      final tokenFcm = professionalProfile?['fcm_token'] as String?;
      if (tokenFcm == null || tokenFcm.isEmpty) return;

      // Buscar nome do usuário que está agendando
      final communityProfile = await _client
          .from('profiles')
          .select('full_name')
          .eq('id', communityUserId)
          .maybeSingle();

      final userName = communityProfile?['full_name'] as String? ?? 'Um usuário';

      // Chamar Edge Function para enviar notificação
      await _client.functions.invoke(
        'enviar-notificacao',
        body: {
          'tokenFcm': tokenFcm,
          'titulo': 'Novo Agendamento',
          'corpo': '$userName agendou um serviço de ${service['categoria']}',
          'dados': {
            'tipo': 'novo_agendamento',
            'service_id': serviceId,
            'scheduled_date': scheduledDate,
            'scheduled_time': scheduledTime,
          },
        },
      );
    } catch (e) {
      // Não lançar erro - notificação é secundária
      print('Erro ao enviar notificação: $e');
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
      rows =
          await _client.rpc(
                'get_service_booked_times',
                params: {
                  'p_service_id': serviceId,
                  'p_scheduled_date': dateValue,
                },
              )
              as List<dynamic>;
    } catch (_) {
      rows = await _client
          .from('appointments')
          .select('scheduled_time')
          .eq('service_id', serviceId)
          .eq('scheduled_date', dateValue)
          .inFilter('status', ['agendado']);
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
    if (serviceId != null) {
      final service = await _client
          .from('servicos')
          .select('user_id, nome_profissional, categoria, local')
          .eq('id', serviceId)
          .maybeSingle();
      final serviceOwnerId = service?['user_id'] as String?;
      cancelledByProfessional =
          serviceOwnerId != null &&
          serviceOwnerId == currentUid &&
          communityUserId != null &&
          communityUserId != currentUid;

      if (cancelledByProfessional) {
        try {
          final scheduledDate = appointment['scheduled_date'] as String?;
          final scheduledTime = appointment['scheduled_time'] as String?;
          DateTime? scheduledAt;
          if ((scheduledDate ?? '').isNotEmpty &&
              (scheduledTime ?? '').isNotEmpty) {
            final dateParts = scheduledDate!.split('-');
            final timeParts = scheduledTime!.split(':');
            if (dateParts.length == 3 && timeParts.length >= 2) {
              final year = int.tryParse(dateParts[0]) ?? 1970;
              final month = int.tryParse(dateParts[1]) ?? 1;
              final day = int.tryParse(dateParts[2]) ?? 1;
              final hour = int.tryParse(timeParts[0]) ?? 0;
              final minute = int.tryParse(timeParts[1]) ?? 0;
              scheduledAt = DateTime(year, month, day, hour, minute);
            }
          }

          await _client.from('appointment_cancellation_messages').insert({
            'recipient_user_id': communityUserId,
            'message': 'Profissional cancelou o agendamento.',
            'scheduled_at': scheduledAt?.toIso8601String(),
            'professional_name': service?['nome_profissional'] as String?,
            'specialty': service?['categoria'] as String?,
            'location': service?['local'] as String?,
          });
        } catch (_) {}
      }
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

    // Enviar notificação push para o profissional
    if (serviceId != null) {
      await _enviarNotificacaoCancelamento(
        serviceId: serviceId,
        appointmentId: appointmentId,
        communityUserId: communityUserId,
      );
    }
  }

  Future<void> _enviarNotificacaoCancelamento({
    required String serviceId,
    required String appointmentId,
    required String? communityUserId,
  }) async {
    try {
      // Buscar informações do serviço e profissional
      final service = await _client
          .from('servicos')
          .select('user_id, nome_profissional, categoria')
          .eq('id', serviceId)
          .maybeSingle();

      if (service == null) return;

      final professionalId = service['user_id'] as String?;
      if (professionalId == null) return;

      // Buscar token FCM do profissional
      final professionalProfile = await _client
          .from('professional_profiles')
          .select('fcm_token')
          .eq('user_id', professionalId)
          .maybeSingle();

      final tokenFcm = professionalProfile?['fcm_token'] as String?;
      if (tokenFcm == null || tokenFcm.isEmpty) return;

      // Buscar nome do usuário que cancelou
      String userName = 'Um usuário';
      if (communityUserId != null) {
        final communityProfile = await _client
            .from('profiles')
            .select('full_name')
            .eq('id', communityUserId)
            .maybeSingle();
        userName = communityProfile?['full_name'] as String? ?? userName;
      }

      // Chamar Edge Function para enviar notificação
      await _client.functions.invoke(
        'enviar-notificacao',
        body: {
          'tokenFcm': tokenFcm,
          'titulo': 'Agendamento Cancelado',
          'corpo': '$userName cancelou um agendamento de ${service['categoria']}',
          'dados': {
            'tipo': 'cancelamento_agendamento',
            'appointment_id': appointmentId,
            'service_id': serviceId,
          },
        },
      );
    } catch (e) {
      // Não lançar erro - notificação é secundária
      print('Erro ao enviar notificação de cancelamento: $e');
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
