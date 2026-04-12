import 'dart:io';

import 'package:centro_social_app/src/funcionalidades/eventos/dados/repositorio_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/provedores/provedores_eventos.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/componentes/card_feed_evento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum _EventLocationType { presencial, online, hibrido }

class AnnounceEventPage extends ConsumerStatefulWidget {
  final AppEvent? initialEvent;

  const AnnounceEventPage({super.key, this.initialEvent});

  @override
  ConsumerState<AnnounceEventPage> createState() => _AnnounceEventPageState();
}

class _AnnounceEventPageState extends ConsumerState<AnnounceEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _streamLinkController = TextEditingController();
  final _shortSummaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxSeatsController = TextEditingController();
  final _volunteerCountController = TextEditingController();
  final _volunteerDetailsController = TextEditingController();
  final _externalRegistrationLinkController = TextEditingController();
  final _accessibilityController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactEmailController = TextEditingController();

  final List<String> _categories = [
    'Culto',
    'Acao social',
    'Palestra',
    'Oficina',
    'Encontro comunitario',
    'Campanha',
    'Outro',
  ];

  final List<String> _repetitionOptions = [
    'Sem repeticao',
    'Semanal',
    'Mensal',
  ];

  final List<String> _audienceOptions = [
    'Criancas',
    'Jovens',
    'Adultos',
    'Familias',
    'Comunidade geral',
    'Voluntarios',
  ];

  String? _selectedCategory;
  String _selectedRepetition = 'Sem repeticao';
  final Set<String> _selectedAudiences = {};

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _allDay = false;
  _EventLocationType _locationType = _EventLocationType.presencial;
  bool _isPaidEvent = false;
  bool _requiresRegistration = false;
  bool _allowVolunteers = false;
  bool _schedulePublication = false;
  DateTime? _publicationDate;
  TimeOfDay? _publicationTime;

  XFile? _coverImage;
  final List<XFile> _galleryImages = [];
  String? _existingCoverImageUrl;
  List<String> _existingGalleryImagesUrls = [];
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialEvent != null;

  int get _requiredFieldsTotal => 8;

  int get _requiredFieldsDone {
    var completed = 0;
    if (_nameController.text.trim().isNotEmpty) completed++;
    if ((_selectedCategory ?? '').trim().isNotEmpty) completed++;
    if (_startDate != null) completed++;
    if (_endDate != null) completed++;
    if (_shortSummaryController.text.trim().isNotEmpty) completed++;
    if (_descriptionController.text.trim().isNotEmpty) completed++;
    if (_contactNameController.text.trim().isNotEmpty) completed++;
    if (_contactPhoneController.text.trim().isNotEmpty) completed++;
    return completed;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _prefillFromInitialEvent(widget.initialEvent!);
    } else {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day);
    }

    _attachCompletionListeners();
  }

  void _prefillFromInitialEvent(AppEvent event) {
    _nameController.text = event.nome;
    _selectedCategory = event.categoria;
    _selectedAudiences
      ..clear()
      ..addAll(event.publicoAlvo);
    _startDate = DateTime(
      event.dataInicio.year,
      event.dataInicio.month,
      event.dataInicio.day,
    );
    _endDate = DateTime(
      event.dataFim.year,
      event.dataFim.month,
      event.dataFim.day,
    );
    _startTime = _parseSqlTime(event.horaInicio);
    _endTime = _parseSqlTime(event.horaFim);
    _allDay = event.diaInteiro;
    _selectedRepetition = _fromSqlRepetition(event.repeticao);
    _locationType = _fromTipoLocal(event.tipoLocal);
    _addressController.text = event.endereco ?? '';
    _streamLinkController.text = event.linkTransmissao ?? '';
    _shortSummaryController.text = event.resumoCurto;
    _descriptionController.text = event.descricao;
    _existingCoverImageUrl = event.imagemCapaUrl;
    _existingGalleryImagesUrls = List<String>.from(event.galeriaImagensUrls);
    _isPaidEvent = event.eventoPago;
    _maxSeatsController.text = event.limiteVagas?.toString() ?? '';
    _requiresRegistration = event.requerInscricao;
    _externalRegistrationLinkController.text = event.linkInscricao ?? '';
    _allowVolunteers = event.permitirVoluntarios;
    _volunteerCountController.text =
        event.quantidadeVoluntarios?.toString() ?? '';
    _volunteerDetailsController.text = event.atividadesVoluntarios ?? '';
    _accessibilityController.text = event.acessibilidade ?? '';
    _contactNameController.text = event.contatoNome;
    _contactPhoneController.text = event.contatoTelefone;
    _contactEmailController.text = event.contatoEmail ?? '';

    _schedulePublication =
        event.status == 'agendado' || event.agendarPublicacao;
    if (event.publicadoEm != null) {
      _publicationDate = DateTime(
        event.publicadoEm!.year,
        event.publicadoEm!.month,
        event.publicadoEm!.day,
      );
      _publicationTime = TimeOfDay(
        hour: event.publicadoEm!.hour,
        minute: event.publicadoEm!.minute,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _streamLinkController.dispose();
    _shortSummaryController.dispose();
    _descriptionController.dispose();
    _maxSeatsController.dispose();
    _volunteerCountController.dispose();
    _volunteerDetailsController.dispose();
    _externalRegistrationLinkController.dispose();
    _accessibilityController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    super.dispose();
  }

  void _attachCompletionListeners() {
    final controllers = [
      _nameController,
      _shortSummaryController,
      _descriptionController,
      _contactNameController,
      _contactPhoneController,
    ];

    for (final controller in controllers) {
      controller.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ANUNCIAR EVENTO')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(context),
              const SizedBox(height: 16),
              _buildMainInfoSection(),
              const SizedBox(height: 12),
              _buildDateTimeSection(context),
              const SizedBox(height: 12),
              _buildLocationSection(),
              const SizedBox(height: 12),
              _buildDescriptionSection(),
              const SizedBox(height: 12),
              _buildMediaSection(),
              const SizedBox(height: 12),
              _buildRegistrationSection(),
              const SizedBox(height: 12),
              _buildVolunteersSection(),
              const SizedBox(height: 12),
              _buildAccessibilitySection(),
              const SizedBox(height: 12),
              _buildPublicationSection(context),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publique seu evento no mural da comunidade',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Preencha os campos principais e depois finalize em Publicar.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: _requiredFieldsDone / _requiredFieldsTotal,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 8),
            Text(
              '$_requiredFieldsDone de $_requiredFieldsTotal campos obrigatorios preenchidos',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfoSection() {
    return _sectionCard(
      title: 'Informacoes principais',
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nome do evento *',
              hintText: 'Ex: Feira Solidaria de Inverno',
            ),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Categoria *'),
            items: _categories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Selecione uma categoria';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Publico-alvo',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _audienceOptions.map((audience) {
              final selected = _selectedAudiences.contains(audience);
              return FilterChip(
                label: Text(audience),
                selected: selected,
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedAudiences.add(audience);
                    } else {
                      _selectedAudiences.remove(audience);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    return _sectionCard(
      title: 'Data e horario',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Evento de dia inteiro'),
            value: _allDay,
            onChanged: (value) => setState(() => _allDay = value),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: true),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    _startDate == null
                        ? 'Data inicio *'
                        : _formatDate(_startDate!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isStart: false),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    _endDate == null ? 'Data fim *' : _formatDate(_endDate!),
                  ),
                ),
              ),
            ],
          ),
          if (!_allDay) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: true),
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(
                      _startTime == null
                          ? 'Hora inicio'
                          : _startTime!.format(context),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: const Icon(Icons.timelapse_outlined),
                    label: Text(
                      _endTime == null ? 'Hora fim' : _endTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedRepetition,
            decoration: const InputDecoration(labelText: 'Repeticao'),
            items: _repetitionOptions
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRepetition = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _sectionCard(
      title: 'Local',
      child: Column(
        children: [
          SegmentedButton<_EventLocationType>(
            segments: const [
              ButtonSegment(
                value: _EventLocationType.presencial,
                label: Text('Presencial'),
              ),
              ButtonSegment(
                value: _EventLocationType.online,
                label: Text('Online'),
              ),
              ButtonSegment(
                value: _EventLocationType.hibrido,
                label: Text('Hibrido'),
              ),
            ],
            selected: {_locationType},
            onSelectionChanged: (value) {
              setState(() => _locationType = value.first);
            },
          ),
          const SizedBox(height: 12),
          if (_locationType != _EventLocationType.online)
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Endereco (presencial)',
                hintText: 'Rua, numero, bairro',
              ),
            ),
          if (_locationType == _EventLocationType.hibrido)
            const SizedBox(height: 12),
          if (_locationType != _EventLocationType.presencial)
            TextFormField(
              controller: _streamLinkController,
              decoration: const InputDecoration(
                labelText: 'Link da transmissao',
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _sectionCard(
      title: 'Descricao',
      child: Column(
        children: [
          TextFormField(
            controller: _shortSummaryController,
            decoration: const InputDecoration(
              labelText: 'Resumo curto *',
              hintText: 'Texto que aparece no card do evento',
            ),
            maxLength: 120,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descricao completa *',
            ),
            minLines: 4,
            maxLines: 8,
            validator: _requiredValidator,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return _sectionCard(
      title: 'Midia',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => _pickImage(isCover: true),
            icon: const Icon(Icons.image_outlined),
            label: Text(
              _coverImage == null
                  ? 'Selecionar capa do evento'
                  : 'Trocar capa selecionada',
            ),
          ),
          if (_coverImage != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_coverImage!.path),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ] else if (_existingCoverImageUrl?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _existingCoverImageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(isCover: false),
            icon: const Icon(Icons.collections_outlined),
            label: const Text('Adicionar imagens a galeria'),
          ),
          const SizedBox(height: 8),
          Text(
            'Galeria: ${_existingGalleryImagesUrls.length + _galleryImages.length} imagem(ns)',
          ),
          if (_existingGalleryImagesUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _existingGalleryImagesUrls.map((url) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _existingGalleryImagesUrls.remove(url);
                          });
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          if (_galleryImages.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _galleryImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _galleryImages.removeAt(index);
                          });
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegistrationSection() {
    return _sectionCard(
      title: 'Inscricao e vagas',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Evento pago'),
            value: _isPaidEvent,
            onChanged: (value) => setState(() => _isPaidEvent = value),
          ),
          TextFormField(
            controller: _maxSeatsController,
            decoration: const InputDecoration(
              labelText: 'Limite de vagas',
              hintText: 'Ex: 80',
            ),
            keyboardType: TextInputType.number,
            validator: _optionalPositiveIntValidator,
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Necessita inscricao previa'),
            value: _requiresRegistration,
            onChanged: (value) => setState(() => _requiresRegistration = value),
          ),
          if (_requiresRegistration)
            TextFormField(
              controller: _externalRegistrationLinkController,
              decoration: const InputDecoration(
                labelText: 'Link externo de inscricao',
                hintText: 'https://...',
              ),
              keyboardType: TextInputType.url,
            ),
        ],
      ),
    );
  }

  Widget _buildVolunteersSection() {
    return _sectionCard(
      title: 'Voluntariado',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Permitir voluntarios'),
            subtitle: const Text(
              'Ative se o evento precisar de apoio para organizacao.',
            ),
            value: _allowVolunteers,
            onChanged: (value) => setState(() => _allowVolunteers = value),
          ),
          if (_allowVolunteers) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _volunteerCountController,
              decoration: const InputDecoration(
                labelText: 'Quantidade de voluntarios (opcional)',
                hintText: 'Ex: 10',
              ),
              keyboardType: TextInputType.number,
              validator: _optionalPositiveIntValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _volunteerDetailsController,
              decoration: const InputDecoration(
                labelText: 'Atividades para voluntarios',
                hintText: 'Ex: recepcao, apoio logistica, cadastro',
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccessibilitySection() {
    return _sectionCard(
      title: 'Acessibilidade e contato',
      child: Column(
        children: [
          TextFormField(
            controller: _accessibilityController,
            decoration: const InputDecoration(
              labelText: 'Recursos de acessibilidade (opcional)',
              hintText: 'Ex: rampa, interprete de Libras, legenda',
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactNameController,
            decoration: const InputDecoration(labelText: 'Responsavel *'),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactPhoneController,
            decoration: const InputDecoration(
              labelText: 'Telefone de contato *',
            ),
            keyboardType: TextInputType.phone,
            validator: _requiredValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contactEmailController,
            decoration: const InputDecoration(labelText: 'E-mail de contato'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isNotEmpty &&
                  (!text.contains('@') || !text.contains('.'))) {
                return 'Informe um e-mail valido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationSection(BuildContext context) {
    return _sectionCard(
      title: 'Publicacao',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Agendar publicacao'),
            value: _schedulePublication,
            onChanged: (value) {
              setState(() {
                _schedulePublication = value;
                if (!value) {
                  _publicationDate = null;
                  _publicationTime = null;
                }
              });
            },
          ),
          if (_schedulePublication)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickPublicationDate,
                    child: Text(
                      _publicationDate == null
                          ? 'Data publicacao'
                          : _formatDate(_publicationDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickPublicationTime,
                    child: Text(
                      _publicationTime == null
                          ? 'Hora publicacao'
                          : _publicationTime!.format(context),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _onPreview,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Pre-visualizar'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _onPublish,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_outlined),
          label: Text(
            _isSubmitting
                ? 'Enviando...'
                : (_isEditing ? 'Salvar alteracoes' : 'Publicar evento'),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }

  String? _optionalPositiveIntValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return null;
    }

    final parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) {
      return 'Informe um numero inteiro maior que zero';
    }

    return null;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = selected;
        }
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 10, minute: 0)),
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _startTime = selected;
      } else {
        _endTime = selected;
      }
    });
  }

  Future<void> _pickImage({required bool isCover}) async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        if (isCover) {
          _coverImage = image;
        } else if (_galleryImages.length < 8) {
          _galleryImages.add(image);
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel selecionar a imagem.')),
      );
    }
  }

  Future<void> _pickPublicationDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _publicationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _publicationDate = selected);
    }
  }

  Future<void> _pickPublicationTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _publicationTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (selected != null) {
      setState(() => _publicationTime = selected);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  Future<void> _onPreview() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null ||
        (_selectedCategory ?? '').trim().isEmpty) {
      return;
    }

    final previewEvent = AppEvent(
      id: widget.initialEvent?.id ?? 'preview',
      userId: widget.initialEvent?.userId ?? '',
      nome: _nameController.text.trim(),
      categoria: (_selectedCategory ?? '').trim(),
      publicoAlvo: _selectedAudiences.toList(),
      dataInicio: _startDate!,
      dataFim: _endDate!,
      horaInicio: _startTime == null
          ? null
          : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
      horaFim: _endTime == null
          ? null
          : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00',
      diaInteiro: _allDay,
      repeticao: _toSqlRepetition(_selectedRepetition),
      tipoLocal: _locationType.name,
      endereco: _addressController.text.trim(),
      linkTransmissao: _streamLinkController.text.trim(),
      resumoCurto: _shortSummaryController.text.trim(),
      descricao: _descriptionController.text.trim(),
      imagemCapaUrl: _existingCoverImageUrl,
      galeriaImagensUrls: _existingGalleryImagesUrls,
      eventoPago: _isPaidEvent,
      limiteVagas: _parsePositiveInt(_maxSeatsController.text),
      requerInscricao: _requiresRegistration,
      linkInscricao: _externalRegistrationLinkController.text.trim(),
      permitirVoluntarios: _allowVolunteers,
      quantidadeVoluntarios: _parsePositiveInt(_volunteerCountController.text),
      atividadesVoluntarios: _volunteerDetailsController.text.trim(),
      acessibilidade: _accessibilityController.text.trim(),
      contatoNome: _contactNameController.text.trim(),
      contatoTelefone: _contactPhoneController.text.trim(),
      contatoEmail: _contactEmailController.text.trim(),
      agendarPublicacao: _schedulePublication,
      publicadoEm: _combinePublicationDateTime(),
      status: _schedulePublication ? 'agendado' : 'publicado',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: EventFeedCard(
              event: previewEvent,
              onPrimaryAction: () => Navigator.of(context).pop(),
              primaryActionLabel: 'Fechar previa',
            ),
          ),
        );
      },
    );
  }

  Future<void> _onPublish() async {
    await _persistEvent(mode: EventPersistenceMode.publish);
  }

  Future<void> _persistEvent({required EventPersistenceMode mode}) async {
    if (!_validateBeforePersist(mode: mode)) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(eventsRepositoryProvider);
      await repository.saveEvent(
        input: _buildEventUpsertInput(),
        mode: mode,
        existingEvent: widget.initialEvent,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento salvo com sucesso.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao salvar evento: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _validateBeforePersist({required EventPersistenceMode mode}) {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione as datas de inicio e fim do evento.'),
        ),
      );
      return false;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A data de fim nao pode ser antes da data de inicio.'),
        ),
      );
      return false;
    }

    if (mode == EventPersistenceMode.publish && _schedulePublication) {
      if (_publicationDate == null || _publicationTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Defina data e hora para agendar a publicacao.'),
          ),
        );
        return false;
      }
    }

    return true;
  }

  EventUpsertInput _buildEventUpsertInput() {
    return EventUpsertInput(
      nome: _nameController.text.trim(),
      categoria: (_selectedCategory ?? '').trim(),
      publicoAlvo: _selectedAudiences.toList(),
      dataInicio: _startDate!,
      dataFim: _endDate!,
      horaInicio: _allDay || _startTime == null
          ? null
          : TimeOfDaySql(hour: _startTime!.hour, minute: _startTime!.minute),
      horaFim: _allDay || _endTime == null
          ? null
          : TimeOfDaySql(hour: _endTime!.hour, minute: _endTime!.minute),
      diaInteiro: _allDay,
      repeticao: _toSqlRepetition(_selectedRepetition),
      tipoLocal: _locationType.name,
      endereco: _locationType == _EventLocationType.online
          ? null
          : _addressController.text.trim(),
      linkTransmissao: _locationType == _EventLocationType.presencial
          ? null
          : _streamLinkController.text.trim(),
      resumoCurto: _shortSummaryController.text.trim(),
      descricao: _descriptionController.text.trim(),
      eventoPago: _isPaidEvent,
      limiteVagas: _parsePositiveInt(_maxSeatsController.text),
      requerInscricao: _requiresRegistration,
      linkInscricao: _externalRegistrationLinkController.text.trim(),
      permitirVoluntarios: _allowVolunteers,
      quantidadeVoluntarios: _allowVolunteers
          ? _parsePositiveInt(_volunteerCountController.text)
          : null,
      atividadesVoluntarios: _allowVolunteers
          ? _volunteerDetailsController.text.trim()
          : null,
      acessibilidade: _accessibilityController.text.trim(),
      contatoNome: _contactNameController.text.trim(),
      contatoTelefone: _contactPhoneController.text.trim(),
      contatoEmail: _contactEmailController.text.trim(),
      agendarPublicacao: _schedulePublication,
      dataPublicacao: _combinePublicationDateTime(),
      imagemCapa: _coverImage,
      galeriaImagensExistentes: _existingGalleryImagesUrls,
      galeriaImagens: List<XFile>.from(_galleryImages),
    );
  }

  DateTime? _combinePublicationDateTime() {
    if (_publicationDate == null || _publicationTime == null) {
      return null;
    }

    return DateTime(
      _publicationDate!.year,
      _publicationDate!.month,
      _publicationDate!.day,
      _publicationTime!.hour,
      _publicationTime!.minute,
    );
  }

  String _toSqlRepetition(String value) {
    switch (value) {
      case 'Semanal':
        return 'semanal';
      case 'Mensal':
        return 'mensal';
      default:
        return 'sem_repeticao';
    }
  }

  String _fromSqlRepetition(String value) {
    switch (value) {
      case 'semanal':
        return 'Semanal';
      case 'mensal':
        return 'Mensal';
      default:
        return 'Sem repeticao';
    }
  }

  _EventLocationType _fromTipoLocal(String value) {
    switch (value) {
      case 'online':
        return _EventLocationType.online;
      case 'hibrido':
        return _EventLocationType.hibrido;
      default:
        return _EventLocationType.presencial;
    }
  }

  TimeOfDay? _parseSqlTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  int? _parsePositiveInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}
