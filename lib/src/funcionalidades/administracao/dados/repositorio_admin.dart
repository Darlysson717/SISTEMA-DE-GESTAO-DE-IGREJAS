import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:excel/excel.dart';

const String superAdminEmail = 'darlison.pires.corporativo@gmail.com';

class AdminUser {
  final String userId;
  final String email;
  final String? fullName;
  final bool isActive;

  const AdminUser({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.isActive,
  });
}

class OrphanCleanupResult {
  final int totalFiles;
  final int orphanFiles;
  final int deletedFiles;

  const OrphanCleanupResult({
    required this.totalFiles,
    required this.orphanFiles,
    required this.deletedFiles,
  });
}

enum PublishRequestStatus { pending, approved, rejected }

PublishRequestStatus parsePublishRequestStatus(String value) {
  switch (value.trim().toLowerCase()) {
    case 'approved':
      return PublishRequestStatus.approved;
    case 'rejected':
      return PublishRequestStatus.rejected;
    default:
      return PublishRequestStatus.pending;
  }
}

class PublishRequest {
  final String id;
  final String userId;
  final String requesterName;
  final String serviceName;
  final PublishRequestStatus status;
  final DateTime createdAt;
  final String? requesterEmail;

  const PublishRequest({
    required this.id,
    required this.userId,
    required this.requesterName,
    required this.serviceName,
    required this.status,
    required this.createdAt,
    required this.requesterEmail,
  });
}

class PublishAccessState {
  final bool canPublish;
  final PublishRequest? latestRequest;
  final bool wasRevoked;
  final DateTime? revokedAt;

  const PublishAccessState({
    required this.canPublish,
    required this.latestRequest,
    required this.wasRevoked,
    required this.revokedAt,
  });
}

class AuthorizedPublisher {
  final String userId;
  final String email;
  final String? fullName;
  final bool isActive;
  final bool isSuperAdmin;

  const AuthorizedPublisher({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.isActive,
    required this.isSuperAdmin,
  });
}

class AdminRepository {
  final SupabaseClient _client;

  const AdminRepository(this._client);

  bool get isCurrentUserSuperAdmin {
    final email = _client.auth.currentUser?.email?.trim().toLowerCase();
    return email == superAdminEmail;
  }

  Future<bool> isCurrentUserAdmin() async {
    if (isCurrentUserSuperAdmin) {
      return true;
    }

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return false;
    }

    final row = await _client
        .from('app_admins')
        .select('user_id')
        .eq('user_id', uid)
        .eq('is_active', true)
        .maybeSingle();

    return row != null;
  }

  Future<List<AdminUser>> listAdmins() async {
    if (!isCurrentUserSuperAdmin) {
      final currentEmail = _client.auth.currentUser?.email ?? '';
      final currentUserId = _client.auth.currentUser?.id ?? '';
      return [
        AdminUser(
          userId: currentUserId,
          email: currentEmail,
          fullName:
              _client.auth.currentUser?.userMetadata?['full_name'] as String?,
          isActive: true,
        ),
      ];
    }

    final rows = await _client
        .from('app_admins')
        .select('''
          user_id,
          is_active,
          profiles:profiles!app_admins_user_id_fkey(
            email,
            full_name
          )
        ''')
        .eq('is_active', true)
        .order('created_at');

    final admins = <AdminUser>[];

    if (isCurrentUserSuperAdmin) {
      final me = _client.auth.currentUser;
      if (me != null && me.email != null) {
        admins.add(
          AdminUser(
            userId: me.id,
            email: me.email!,
            fullName: me.userMetadata?['full_name'] as String?,
            isActive: true,
          ),
        );
      }
    }

    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      final profile = map['profiles'] as Map<String, dynamic>?;
      final email = (profile?['email'] as String?) ?? '';

      if (email.trim().toLowerCase() == superAdminEmail) {
        continue;
      }

      admins.add(
        AdminUser(
          userId: map['user_id'] as String,
          email: email,
          fullName: profile?['full_name'] as String?,
          isActive: (map['is_active'] as bool?) ?? true,
        ),
      );
    }

    return admins;
  }

  Future<int> countAuthenticatedUsers() async {
    final result = await _client.rpc('get_authenticated_users_count');

    if (result is num) {
      return result.toInt();
    }

    if (result is String) {
      return int.parse(result);
    }

    throw Exception('Não foi possível obter o total de usuários autenticados.');
  }

  Future<void> addAdminByEmail(String email) async {
    if (!isCurrentUserSuperAdmin) {
      throw Exception('Apenas o super administrador pode adicionar admins.');
    }

    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw Exception('Informe um e-mail válido.');
    }

    if (normalized == superAdminEmail) {
      return;
    }

    final profile = await _client
        .from('profiles')
        .select('id, email')
        .eq('email', normalized)
        .maybeSingle();

    if (profile == null) {
      throw Exception('Usuário não encontrado em profiles para esse e-mail.');
    }

    final uid = _client.auth.currentUser!.id;

    await _client.from('app_admins').upsert({
      'user_id': profile['id'],
      'is_active': true,
      'created_by': uid,
    }, onConflict: 'user_id');
  }

  Future<void> removeAdmin(String userId) async {
    if (!isCurrentUserSuperAdmin) {
      throw Exception('Apenas o super administrador pode remover admins.');
    }

    if (userId == _client.auth.currentUser?.id) {
      throw Exception('Não é possível remover o próprio super administrador.');
    }

    await _client.from('app_admins').delete().eq('user_id', userId);
  }

  Future<PublishAccessState> getCurrentUserPublishAccess() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const PublishAccessState(
        canPublish: false,
        latestRequest: null,
        wasRevoked: false,
        revokedAt: null,
      );
    }

    bool canPublish = false;
    bool wasRevoked = false;
    DateTime? revokedAt;
    try {
      final permission = await _client
          .from('service_publish_permissions')
          .select('is_active, revoked_at')
          .eq('user_id', uid)
          .limit(1)
          .maybeSingle();
      canPublish = (permission?['is_active'] as bool?) ?? false;
      final revokedAtRaw = permission?['revoked_at'] as String?;
      revokedAt = DateTime.tryParse(revokedAtRaw ?? '');
      wasRevoked = !canPublish && revokedAt != null;
    } catch (_) {
      final approvedRequest = await _client
          .from('service_publish_requests')
          .select('id')
          .eq('user_id', uid)
          .eq('status', 'approved')
          .limit(1)
          .maybeSingle();
      canPublish = approvedRequest != null;
    }

    final latestRow = await _client
        .from('service_publish_requests')
        .select('id, user_id, requester_name, service_name, status, created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return PublishAccessState(
      canPublish: canPublish,
      latestRequest: latestRow == null ? null : _mapPublishRequest(latestRow),
      wasRevoked: wasRevoked,
      revokedAt: revokedAt,
    );
  }

  Future<void> submitPublishRequest({
    required String requesterName,
    required String serviceName,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Usuário não autenticado.');
    }

    final cleanName = requesterName.trim();
    final cleanService = serviceName.trim();
    if (cleanName.isEmpty || cleanService.isEmpty) {
      throw Exception('Informe nome e serviço.');
    }

    final hasActivePermission = await _client
        .from('service_publish_permissions')
        .select('user_id')
        .eq('user_id', uid)
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (hasActivePermission != null) {
      return;
    }

    final pending = await _client
        .from('service_publish_requests')
        .select('id')
        .eq('user_id', uid)
        .eq('status', 'pending')
        .limit(1)
        .maybeSingle();

    if (pending != null) {
      await _client
          .from('service_publish_requests')
          .update({'requester_name': cleanName, 'service_name': cleanService})
          .eq('id', pending['id'] as String)
          .eq('user_id', uid)
          .eq('status', 'pending');
      return;
    }

    await _client.from('service_publish_requests').insert({
      'user_id': uid,
      'requester_name': cleanName,
      'service_name': cleanService,
      'status': 'pending',
    });
  }

  Future<List<PublishRequest>> listPendingPublishRequests() async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      return [];
    }

    final rows = await _client
        .from('service_publish_requests')
        .select('''
          id,
          user_id,
          requester_name,
          service_name,
          status,
          created_at,
          requester_profile:profiles!service_publish_requests_user_id_fkey(
            email
          )
        ''')
        .eq('status', 'pending')
        .order('created_at', ascending: true);

    return (rows as List<dynamic>)
        .map((row) => _mapPublishRequest(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<AuthorizedPublisher>> listAuthorizedPublishers() async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      return [];
    }

    final rows = await _client
        .from('service_publish_permissions')
        .select('''
          user_id,
          is_active,
          profiles:profiles!service_publish_permissions_user_id_fkey(
            email,
            full_name
          )
        ''')
        .eq('is_active', true)
        .order('granted_at', ascending: true);

    return (rows as List<dynamic>).map((row) {
      final map = row as Map<String, dynamic>;
      final profile = map['profiles'] as Map<String, dynamic>?;
      final email = (profile?['email'] as String?) ?? '';
      return AuthorizedPublisher(
        userId: map['user_id'] as String,
        email: email,
        fullName: profile?['full_name'] as String?,
        isActive: (map['is_active'] as bool?) ?? false,
        isSuperAdmin: email.trim().toLowerCase() == superAdminEmail,
      );
    }).toList();
  }

  Future<void> revokePublishPermission(String userId) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      throw Exception('Acesso negado.');
    }

    final profile = await _client
        .from('profiles')
        .select('email')
        .eq('id', userId)
        .maybeSingle();
    final targetEmail = (profile?['email'] as String?)?.trim().toLowerCase();
    if (targetEmail == superAdminEmail) {
      throw Exception(
        'A permissão do super administrador não pode ser revogada.',
      );
    }

    final reviewerId = _client.auth.currentUser?.id;

    await _client
        .from('service_publish_permissions')
        .update({
          'is_active': false,
          'revoked_by': reviewerId,
          'revoked_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_active', true);
  }

  Future<void> reviewPublishRequest({
    required String requestId,
    required bool approved,
  }) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      throw Exception('Acesso negado.');
    }

    final reviewerId = _client.auth.currentUser?.id;

    final requestRow = await _client
        .from('service_publish_requests')
        .select('id, user_id')
        .eq('id', requestId)
        .maybeSingle();

    if (requestRow == null) {
      throw Exception('Solicitação não encontrada.');
    }

    final requestUserId = requestRow['user_id'] as String;

    await _client
        .from('service_publish_requests')
        .update({
          'status': approved ? 'approved' : 'rejected',
          'reviewed_by': reviewerId,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('status', 'pending');

    if (approved) {
      await _client.from('service_publish_permissions').upsert({
        'user_id': requestUserId,
        'is_active': true,
        'granted_by': reviewerId,
        'granted_at': DateTime.now().toIso8601String(),
        'revoked_by': null,
        'revoked_at': null,
      }, onConflict: 'user_id');
    }
  }

  Future<OrphanCleanupResult> cleanupOrphanServiceImages() async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      throw Exception('Acesso negado.');
    }

    final preview = await _client.rpc('get_orphan_service_images');
    final previewMap = preview as Map<String, dynamic>?;
    if (previewMap == null) {
      throw Exception('Resposta inválida ao listar imagens órfãs.');
    }

    final totalFiles = (previewMap['total_files'] as num?)?.toInt() ?? 0;
    final orphanRaw = previewMap['orphan_paths'] as List<dynamic>? ?? const [];
    final orphanPaths =
        orphanRaw
            .map((item) => item.toString())
            .where((path) => path.isNotEmpty)
            .toList()
          ..sort();

    var deleted = 0;
    const chunkSize = 100;
    for (var i = 0; i < orphanPaths.length; i += chunkSize) {
      final chunk = orphanPaths.skip(i).take(chunkSize).toList();
      await _client.storage.from('servicos_images').remove(chunk);
      deleted += chunk.length;
    }

    return OrphanCleanupResult(
      totalFiles: totalFiles,
      orphanFiles: orphanPaths.length,
      deletedFiles: deleted,
    );
  }

  PublishRequest _mapPublishRequest(Map<String, dynamic> map) {
    final requesterProfile = map['requester_profile'] as Map<String, dynamic>?;
    return PublishRequest(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      requesterName: (map['requester_name'] as String?) ?? '',
      serviceName: (map['service_name'] as String?) ?? '',
      status: parsePublishRequestStatus(
        (map['status'] as String?) ?? 'pending',
      ),
      createdAt:
          DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      requesterEmail: requesterProfile?['email'] as String?,
    );
  }

  Future<String> exportAppointmentsReport() async {
    final now = DateTime.now();
    final start = (now.month == 1)
        ? DateTime(now.year - 1, 12, 1)
        : DateTime(now.year, now.month - 1, 1);
    final end = now;

    final rows = await _client
        .from('appointments')
        .select(
          'id, created_at, user_id, service_id, scheduled_time, scheduled_date, status',
        )
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at', ascending: true);

    final rowsList = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    final serviceIds = <String>{};
    final profileIds = <String>{};

    for (final r in rowsList) {
      final sid = r['service_id'] as String?;
      final uid = r['user_id'] as String?;
      if (sid != null && sid.isNotEmpty) serviceIds.add(sid);
      if (uid != null && uid.isNotEmpty) profileIds.add(uid);
    }

    // Fetch services
    Map<String, Map<String, dynamic>> servicesById = {};
    if (serviceIds.isNotEmpty) {
      final svcRows = await _client
          .from('servicos')
          .select('id, categoria, nome_profissional, user_id')
          .inFilter('id', serviceIds.toList());
      for (final s in (svcRows as List<dynamic>)) {
        final m = s as Map<String, dynamic>;
        servicesById[m['id'] as String] = m;
        final owner = m['user_id'] as String?;
        if (owner != null && owner.isNotEmpty) profileIds.add(owner);
      }
    }

    // Fetch profiles for community users and professionals
    final profilesById = <String, String>{};
    if (profileIds.isNotEmpty) {
      final profRows = await _client
          .from('profiles')
          .select('id, full_name, email')
          .inFilter('id', profileIds.toList());
      for (final p in (profRows as List<dynamic>)) {
        final m = p as Map<String, dynamic>;
        final id = m['id'] as String;
        final name =
            (m['full_name'] as String?) ?? (m['email'] as String?) ?? '';
        profilesById[id] = name;
      }
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'DATA DA SOLICITAÇÃO;NOME;SOLICITAÇÃO;PROFISSIONAL;HORÁRIO AGENDADO;DIA AGENDADO;DIA DA SEMANA;STATUS',
    );

    for (final map in rowsList) {
      final createdRaw = (map['created_at'] as String?) ?? '';
      final created = _formatDateOnly(createdRaw);
      final uid = (map['user_id'] as String?) ?? '';
      final sid = (map['service_id'] as String?) ?? '';
      final scheduledTime = (map['scheduled_time'] as String?) ?? '';
      final scheduledDate = (map['scheduled_date'] as String?) ?? '';
      final statusRaw = (map['status'] as String?) ?? '';

      final communityName = profilesById[uid] ?? 'Sem nome';
      final service = servicesById[sid];
      final solicitation = service == null
          ? 'Serviço'
          : (service['categoria'] as String?) ?? 'Serviço';
      final professional = service == null
          ? ''
          : (service['nome_profissional'] as String?) ??
                profilesById[service['user_id'] as String] ??
                '';

      final dayOfWeek = _weekdayLabelFromDateString(scheduledDate);
      final status = statusRaw.toLowerCase().contains('cancel')
          ? 'cancelado'
          : (statusRaw.toLowerCase().contains('conclu') ||
                statusRaw.toLowerCase().contains('complete'))
          ? 'concluido'
          : statusRaw;

      buffer.writeln(
        '${_escapeCsvField(created)};${_escapeCsvField(communityName)};${_escapeCsvField(solicitation)};${_escapeCsvField(professional)};${_escapeCsvField(scheduledTime)};${_escapeCsvField(scheduledDate)};${_escapeCsvField(dayOfWeek)};${_escapeCsvField(status)}',
      );
    }

    return buffer.toString();
  }

  String _weekdayLabelFromDateString(String date) {
    try {
      if (date.isEmpty) return '';
      final parts = date.split('-');
      if (parts.length < 3) return '';
      final y = int.tryParse(parts[0]) ?? 1970;
      final m = int.tryParse(parts[1]) ?? 1;
      final d = int.tryParse(parts[2]) ?? 1;
      final dt = DateTime(y, m, d);
      switch (dt.weekday) {
        case DateTime.monday:
          return 'Segunda';
        case DateTime.tuesday:
          return 'Terça';
        case DateTime.wednesday:
          return 'Quarta';
        case DateTime.thursday:
          return 'Quinta';
        case DateTime.friday:
          return 'Sexta';
        case DateTime.saturday:
          return 'Sábado';
        case DateTime.sunday:
          return 'Domingo';
      }
    } catch (_) {}
    return '';
  }

  String _formatDateOnly(String datetime) {
    if (datetime.isEmpty) return '';
    if (datetime.contains('T')) return datetime.split('T').first;
    if (datetime.contains(' ')) return datetime.split(' ').first;
    return datetime;
  }

  String _escapeCsvField(String field) {
    if (field.contains(';') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Future<List<int>> exportEventsSummaryXlsx() async {
    final now = DateTime.now();
    final start = (now.month == 1)
        ? DateTime(now.year - 1, 12, 1)
        : DateTime(now.year, now.month - 1, 1);
    final end = now;

    // Load events created in the window
    final eventRows = await _client
        .from('eventos')
        .select(
          'id, nome, status, categoria, evento_pago, permitir_voluntarios, requer_inscricao, limite_vagas, data_inicio, data_fim, created_at',
        )
        .gte('created_at', start.toIso8601String())
        .lte('created_at', end.toIso8601String())
        .order('created_at', ascending: true);

    final events = (eventRows as List<dynamic>)
        .map((r) => r as Map<String, dynamic>)
        .toList();

    final eventIds = events
        .map((e) => e['id'] as String)
        .where((id) => id.isNotEmpty)
        .toList();

    // Load registration stats
    final registrationStatsByEvent = <String, Map<String, int>>{};
    if (eventIds.isNotEmpty) {
      final regs = await _client
          .from('event_registrations')
          .select('event_id, interesse')
          .inFilter('event_id', eventIds);

      for (final r in (regs as List<dynamic>)) {
        final map = r as Map<String, dynamic>;
        final eid = (map['event_id'] as String?)?.trim() ?? '';
        if (eid.isEmpty) continue;
        final interest =
            (map['interesse'] as String?)?.trim().toLowerCase() ?? '';
        final stats = registrationStatsByEvent.putIfAbsent(
          eid,
          () => {'total': 0, 'participants': 0, 'volunteers': 0},
        );
        stats['total'] = (stats['total'] ?? 0) + 1;
        if (interest == 'voluntario' || interest == 'volunteer') {
          stats['volunteers'] = (stats['volunteers'] ?? 0) + 1;
        } else {
          stats['participants'] = (stats['participants'] ?? 0) + 1;
        }
      }
    }

    // Aggregate metrics
    final statusCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    var eventsWithRegistrations = 0;
    var eventsWithVolunteers = 0;
    var paidEvents = 0;
    var totalRegistrations = 0;
    var totalParticipants = 0;
    var totalVolunteers = 0;

    for (final e in events) {
      final status = (e['status'] as String?) ?? 'Sem status';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      final category = ((e['categoria'] as String?) ?? '').trim();
      final catKey = category.isEmpty ? 'Sem categoria' : category;
      categoryCounts[catKey] = (categoryCounts[catKey] ?? 0) + 1;

      final isPaid = (e['evento_pago'] as bool?) ?? false;
      if (isPaid) paidEvents += 1;

      final allowsVolunteers = (e['permitir_voluntarios'] as bool?) ?? false;
      if (allowsVolunteers) eventsWithVolunteers += 1;

      final stats = registrationStatsByEvent[e['id'] as String];
      if (stats != null && (stats['total'] ?? 0) > 0) {
        eventsWithRegistrations += 1;
        totalRegistrations += (stats['total'] ?? 0);
        totalParticipants += (stats['participants'] ?? 0);
        totalVolunteers += (stats['volunteers'] ?? 0);
      }
    }

    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet();
    if (defaultName != null && defaultName != 'Resumo') {
      excel.rename(defaultName, 'Resumo');
    }

    final sheet = excel['Resumo'];

    sheet.appendRow([TextCellValue('Relatório de Eventos')]);
    sheet.appendRow(const [null]);
    sheet.appendRow([TextCellValue('Indicador'), TextCellValue('Valor')]);

    final metricRows = <List<CellValue?>>[
      [TextCellValue('Total de eventos'), IntCellValue(events.length)],
      [
        TextCellValue('Eventos com inscrição'),
        IntCellValue(eventsWithRegistrations),
      ],
      [TextCellValue('Eventos pagos'), IntCellValue(paidEvents)],
      [
        TextCellValue('Eventos com voluntarios'),
        IntCellValue(eventsWithVolunteers),
      ],
      [TextCellValue('Total de inscricoes'), IntCellValue(totalRegistrations)],
      [
        TextCellValue('Total de participantes'),
        IntCellValue(totalParticipants),
      ],
      [TextCellValue('Total de voluntarios'), IntCellValue(totalVolunteers)],
    ];

    for (final row in metricRows) {
      sheet.appendRow(row);
    }

    sheet.appendRow(const [null]);
    sheet.appendRow([TextCellValue('Eventos por status'), null]);
    sheet.appendRow([TextCellValue('Status'), TextCellValue('Quantidade')]);
    for (final entry in statusCounts.entries) {
      sheet.appendRow([TextCellValue(entry.key), IntCellValue(entry.value)]);
    }

    sheet.appendRow(const [null]);
    sheet.appendRow([TextCellValue('Eventos por categoria'), null]);
    sheet.appendRow([TextCellValue('Categoria'), TextCellValue('Quantidade')]);
    final categories = categoryCounts.keys.toList()..sort();
    for (final c in categories) {
      sheet.appendRow([TextCellValue(c), IntCellValue(categoryCounts[c] ?? 0)]);
    }

    // --- Aba detalhada 'Eventos' ---
    final eventsSheet = excel['Eventos'];
    eventsSheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Nome'),
      TextCellValue('Categoria'),
      TextCellValue('Pago'),
      TextCellValue('Permite Voluntários'),
      TextCellValue('Requer Inscrição'),
      TextCellValue('Limite Vagas'),
      TextCellValue('Data Início'),
      TextCellValue('Data Fim'),
      TextCellValue('Criado Em'),
      TextCellValue('Status'),
      TextCellValue('Inscrições Totais'),
      TextCellValue('Participantes'),
      TextCellValue('Voluntários'),
    ]);

    for (final e in events) {
      final id = (e['id'] as String?) ?? '';
      final name = (e['nome'] as String?) ?? '';
      final category = (e['categoria'] as String?) ?? '';
      final paid = ((e['evento_pago'] as bool?) ?? false) ? 'Sim' : 'Não';
      final allowsVol = ((e['permitir_voluntarios'] as bool?) ?? false)
          ? 'Sim'
          : 'Não';
      final requiresReg = ((e['requer_inscricao'] as bool?) ?? false)
          ? 'Sim'
          : 'Não';
      final limit = (e['limite_vagas'] is int)
          ? IntCellValue(e['limite_vagas'] as int)
          : null;
      final dataInicio = (e['data_inicio'] as String?) ?? '';
      final dataFim = (e['data_fim'] as String?) ?? '';
      final createdAt = (e['created_at'] as String?) ?? '';
      final status = (e['status'] as String?) ?? '';

      final stats =
          registrationStatsByEvent[id] ??
          {'total': 0, 'participants': 0, 'volunteers': 0};
      final total = (stats['total'] ?? 0);
      final participants = (stats['participants'] ?? 0);
      final volunteers = (stats['volunteers'] ?? 0);

      final row = <CellValue?>[
        TextCellValue(id),
        TextCellValue(name),
        TextCellValue(category),
        TextCellValue(paid),
        TextCellValue(allowsVol),
        TextCellValue(requiresReg),
        limit,
        TextCellValue(dataInicio),
        TextCellValue(dataFim),
        TextCellValue(createdAt),
        TextCellValue(status),
        IntCellValue(total),
        IntCellValue(participants),
        IntCellValue(volunteers),
      ];

      eventsSheet.appendRow(row);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Não foi possível gerar XLSX.');
    return bytes;
  }
}
