import 'package:centro_social_app/src/nucleo/utilitarios/imagem_selecionada.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../eventos/dados/repositorio_eventos.dart';
import '../../../eventos/dominio/entidades/evento_app.dart';

class AnnounceEventPage extends StatefulWidget {
  final dynamic initialEvent;

  const AnnounceEventPage({Key? key, this.initialEvent}) : super(key: key);

  @override
  State<AnnounceEventPage> createState() => _AnnounceEventPageState();
}

class _AnnounceEventPageState extends State<AnnounceEventPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Chaves de validação para cada uma das janelas
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();
  final _formKeyStep4 = GlobalKey<FormState>();

  // --- ESTADOS E CONTROLADORES DOS CAMPOS ---
  
  // Janela 1: Informações Básicas
  final TextEditingController _nomeEventoController = TextEditingController();
  String? _categoriaSelecionada;
  final List<String> _publicosAlvo = ['Crianças', 'Jovens', 'Adultos', 'Famílias', 'Comunidade geral', 'Voluntários'];
  final List<String> _publicosSelecionados = [];
  final TextEditingController _descricaoController = TextEditingController();

  // Janela 2: Data, Horário e Local
  bool _isDiaInteiro = false;
  DateTime _dataInicio = DateTime(2026, 7, 2);
  DateTime _dataFim = DateTime(2026, 7, 2);
  TimeOfDay? _horaInicio;
  TimeOfDay? _horaFim;
  String _repeticaoSelecionada = 'Sem repeticao';
  String _formatoLocal = 'Presencial'; 
  final TextEditingController _enderecoController = TextEditingController();

  // Janela 3: Mídia, Inscrições e Vagas
  bool _isEventoPago = false;
  bool _necessitaInscricaoPrevia = false;
  final TextEditingController _limiteVagasController = TextEditingController();
  ImagemSelecionada? _capaImagem;
  List<ImagemSelecionada> _imagensGaleria = [];
  String? _capaImagemUrlExistente;
  List<String> _imagensGaleriaUrlsExistentes = [];

  // Janela 4: Voluntariado, Acessibilidade e Contato
  bool _permitirVoluntarios = false;
  bool _agendarPublicacao = false;
  final TextEditingController _acessibilidadeController = TextEditingController();
  final TextEditingController _responsavelController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _toSnakeCase(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char.toUpperCase() == char && char.toLowerCase() != char && i > 0) {
        buffer.write('_');
      }
      buffer.write(char.toLowerCase());
    }
    return buffer.toString();
  }

  AppEvent? _resolveExistingEvent() {
    if (widget.initialEvent == null) return null;
    if (widget.initialEvent is AppEvent) {
      return widget.initialEvent as AppEvent;
    }
    if (widget.initialEvent is Map) {
      final map = Map<String, dynamic>.from(widget.initialEvent as Map);
      return AppEvent.fromJson(map);
    }
    return null;
  }

  dynamic _getEventValue(String key) {
    if (widget.initialEvent == null) return null;

    if (widget.initialEvent is Map) {
      final map = widget.initialEvent as Map;
      if (map.containsKey(key)) return map[key];
      final snakeKey = _toSnakeCase(key);
      if (map.containsKey(snakeKey)) return map[snakeKey];
      return null;
    }

    final event = widget.initialEvent;
    switch (key) {
      case 'nome':
        return event.nome;
      case 'descricao':
        return event.descricao;
      case 'categoria':
        return event.categoria;
      case 'publicoAlvo':
        return event.publicoAlvo;
      case 'dataInicio':
        return event.dataInicio;
      case 'dataFim':
        return event.dataFim;
      case 'horaInicio':
        return event.horaInicio;
      case 'horaFim':
        return event.horaFim;
      case 'diaInteiro':
        return event.diaInteiro;
      case 'repeticao':
        return event.repeticao;
      case 'tipoLocal':
        return event.tipoLocal;
      case 'endereco':
        return event.endereco;
      case 'eventoPago':
        return event.eventoPago;
      case 'limiteVagas':
        return event.limiteVagas;
      case 'requerInscricao':
        return event.requerInscricao;
      case 'permitirVoluntarios':
        return event.permitirVoluntarios;
      case 'agendarPublicacao':
        return event.agendarPublicacao;
      case 'acessibilidade':
        return event.acessibilidade;
      case 'contatoNome':
        return event.contatoNome;
      case 'contatoTelefone':
        return event.contatoTelefone;
      case 'contatoEmail':
        return event.contatoEmail;
      case 'imagemCapaUrl':
        return event.imagemCapaUrl;
      case 'galeriaImagensUrls':
        return event.galeriaImagensUrls;
      default:
        return null;
    }
  }

  String _getStringValue(String key, {String fallback = ''}) {
    final value = _getEventValue(key);
    if (value == null) return fallback;
    return value.toString();
  }

  bool _getBoolValue(String key, {bool fallback = false}) {
    final value = _getEventValue(key);
    if (value is bool) return value;
    return fallback;
  }

  int? _getIntValue(String key) {
    final value = _getEventValue(key);
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _getDateValue(String key) {
    final value = _getEventValue(key);
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;

    final normalized = value.trim();
    final parts = normalized.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _normalizeRepeticao(String? value) {
    final normalized = (value ?? '').toLowerCase();
    switch (normalized) {
      case 'sem_repeticao':
      case 'sem repeticao':
      case 'sem repetição':
        return 'Sem repeticao';
      case 'diario':
      case 'diário':
        return 'Diário';
      case 'semanal':
        return 'Semanal';
      case 'mensal':
        return 'Mensal';
      default:
        return 'Sem repeticao';
    }
  }

  String _normalizeTipoLocal(String? value) {
    final normalized = (value ?? '').toLowerCase();
    switch (normalized) {
      case 'online':
        return 'Online';
      case 'hibrido':
      case 'híbrido':
        return 'Híbrido';
      case 'presencial':
      default:
        return 'Presencial';
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialEvent == null) return;

    _nomeEventoController.text = _getStringValue('nome');
    _descricaoController.text = _getStringValue('descricao');
    _categoriaSelecionada = _getStringValue('categoria');

    final publicoAlvo = _getEventValue('publicoAlvo');
    if (publicoAlvo is List) {
      _publicosSelecionados
        ..clear()
        ..addAll(publicoAlvo.whereType().map((item) => item.toString()));
    } else if (publicoAlvo is List<String>) {
      _publicosSelecionados
        ..clear()
        ..addAll(publicoAlvo);
    } else if (publicoAlvo is List<dynamic>) {
      _publicosSelecionados
        ..clear()
        ..addAll(publicoAlvo.map((item) => item.toString()));
    }

    final dataInicio = _getDateValue('dataInicio');
    final dataFim = _getDateValue('dataFim');
    if (dataInicio != null) _dataInicio = dataInicio;
    if (dataFim != null) _dataFim = dataFim;

    final horaInicio = _parseTimeOfDay(_getStringValue('horaInicio'));
    final horaFim = _parseTimeOfDay(_getStringValue('horaFim'));
    if (horaInicio != null) _horaInicio = horaInicio;
    if (horaFim != null) _horaFim = horaFim;

    _isDiaInteiro = _getBoolValue('diaInteiro');
    _repeticaoSelecionada = _normalizeRepeticao(_getStringValue('repeticao'));
    _formatoLocal = _normalizeTipoLocal(_getStringValue('tipoLocal'));
    _enderecoController.text = _getStringValue('endereco');

    _isEventoPago = _getBoolValue('eventoPago');
    _necessitaInscricaoPrevia = _getBoolValue('requerInscricao');
    _limiteVagasController.text = _getIntValue('limiteVagas')?.toString() ?? '';

    _permitirVoluntarios = _getBoolValue('permitirVoluntarios');
    _agendarPublicacao = _getBoolValue('agendarPublicacao');
    _acessibilidadeController.text = _getStringValue('acessibilidade');
    _responsavelController.text = _getStringValue('contatoNome');
    _telefoneController.text = _getStringValue('contatoTelefone');
    _emailController.text = _getStringValue('contatoEmail');

    final coverUrl = _getEventValue('imagemCapaUrl');
    if (coverUrl is String && coverUrl.isNotEmpty) {
      _capaImagemUrlExistente = coverUrl;
    }

    final galleryUrls = _getEventValue('galeriaImagensUrls');
    if (galleryUrls is List) {
      _imagensGaleriaUrlsExistentes = galleryUrls
          .whereType<String>()
          .where((url) => url.trim().isNotEmpty)
          .toList();
    } else if (galleryUrls is List<String>) {
      _imagensGaleriaUrlsExistentes = galleryUrls.where((url) => url.trim().isNotEmpty).toList();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomeEventoController.dispose();
    _descricaoController.dispose();
    _enderecoController.dispose();
    _limiteVagasController.dispose();
    _acessibilidadeController.dispose();
    _responsavelController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _nextStep() {
    bool isValid = false;

    // Step 0 (Etapa 1): Validações rigorosas para informações básicas
    if (_currentStep == 0) {
      final formIsValid = _formKeyStep1.currentState?.validate() ?? false;
      final categorySelected = _categoriaSelecionada != null && _categoriaSelecionada!.isNotEmpty;
      final audienceSelected = _publicosSelecionados.isNotEmpty;

      if (!formIsValid || !categorySelected || !audienceSelected) {
        final errorMessages = <String>[];
        if (!categorySelected) errorMessages.add('categoria');
        if (!audienceSelected) errorMessages.add('público-alvo');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor, selecione a ${errorMessages.join(" e a ")} antes de avançar',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      isValid = true;
    } else if (_currentStep == 1) {
      isValid = _formKeyStep2.currentState?.validate() ?? false;
    } else if (_currentStep == 2) {
      isValid = _formKeyStep3.currentState?.validate() ?? false;
    } else if (_currentStep == 3) {
      isValid = _formKeyStep4.currentState?.validate() ?? false;
    }

    if (isValid && _currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _selecionarCapa() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final selecionada = await ImagemSelecionada.deXFile(image);
      if (!mounted) return;
      setState(() {
        _capaImagem = selecionada;
      });
    }
  }

  Future<void> _selecionarGaleria() async {
    final picker = ImagePicker();
    final imagens = await picker.pickMultiImage();

    if (imagens.isNotEmpty) {
      final selecionadas = await Future.wait(
        imagens.map(ImagemSelecionada.deXFile),
      );
      if (!mounted) return;
      setState(() {
        _imagensGaleria.addAll(selecionadas);
      });
    }
  }

  Future<void> _publicarEvento() async {
    // Validar o formulário do step 4 (último passo)
    if (_formKeyStep4.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Verificar se pelo menos um público-alvo foi selecionado
    if (_publicosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um público-alvo'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Verificar categoria
    if (_categoriaSelecionada == null || _categoriaSelecionada!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria para o evento'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Mostrar loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF536194)),
            ),
          ),
        );
      },
    );

    try {
      // Obter instância do Supabase e criar repositório
      final supabaseClient = Supabase.instance.client;
      final eventsRepository = EventsRepository(supabaseClient);
      final existingEvent = _resolveExistingEvent();

      // Converter horários para TimeOfDaySql se necessário
      TimeOfDaySql? horaInicio;
      TimeOfDaySql? horaFim;

      if (!_isDiaInteiro) {
        if (_horaInicio != null) {
          horaInicio = TimeOfDaySql(hour: _horaInicio!.hour, minute: _horaInicio!.minute);
        }
        if (_horaFim != null) {
          horaFim = TimeOfDaySql(hour: _horaFim!.hour, minute: _horaFim!.minute);
        }
      }

      // Converter o limite de vagas se preenchido
      int? limiteVagas;
      if (_limiteVagasController.text.isNotEmpty) {
        limiteVagas = int.tryParse(_limiteVagasController.text);
      }

      // Criar input para o evento
      final eventInput = EventUpsertInput(
        nome: _nomeEventoController.text.trim(),
        categoria: _categoriaSelecionada!,
        publicoAlvo: _publicosSelecionados,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        horaInicio: horaInicio,
        horaFim: horaFim,
        diaInteiro: _isDiaInteiro,
        repeticao: _repeticaoSelecionada.toLowerCase().replaceAll(' ', '_'),
        tipoLocal: _formatoLocal.toLowerCase(),
        endereco: _formatoLocal == 'Online' ? null : (_enderecoController.text.trim().isEmpty ? null : _enderecoController.text.trim()),
        linkTransmissao: _formatoLocal == 'Online' ? _enderecoController.text.trim() : null,
        resumoCurto: _descricaoController.text.length > 100 
          ? '${_descricaoController.text.substring(0, 100)}...' 
          : _descricaoController.text,
        descricao: _descricaoController.text.trim(),
        eventoPago: _isEventoPago,
        limiteVagas: limiteVagas,
        requerInscricao: _necessitaInscricaoPrevia,
        linkInscricao: _necessitaInscricaoPrevia ? null : null,
        permitirVoluntarios: _permitirVoluntarios,
        quantidadeVoluntarios: _permitirVoluntarios ? null : null,
        atividadesVoluntarios: null,
        acessibilidade: _acessibilidadeController.text.trim().isEmpty 
          ? null 
          : _acessibilidadeController.text.trim(),
        contatoNome: _responsavelController.text.trim(),
        contatoTelefone: _telefoneController.text.trim(),
        contatoEmail: _emailController.text.trim().isEmpty 
          ? null 
          : _emailController.text.trim(),
        agendarPublicacao: _agendarPublicacao,
        dataPublicacao: _agendarPublicacao ? DateTime.now().add(const Duration(days: 1)) : null,
        imagemCapa: _capaImagem,
        galeriaImagensExistentes: existingEvent?.galeriaImagensUrls ?? const [],
        galeriaImagens: _imagensGaleria,
      );

      // Salvar evento no repositório
      await eventsRepository.saveEvent(
        input: eventInput,
        mode: EventPersistenceMode.publish,
        existingEvent: existingEvent,
      );

      // Fechar loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Mostrar sucesso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingEvent != null
                  ? 'Evento atualizado com sucesso!'
                  : 'Evento publicado com sucesso!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Aguardar um pouco e depois voltar
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } on AuthException catch (e) {
      // Fechar loading dialog
      if (mounted) Navigator.of(context).pop();

      // Erro de autenticação
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de autenticação: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PostgrestException catch (e) {
      // Fechar loading dialog
      if (mounted) Navigator.of(context).pop();

      // Erro do banco de dados
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar evento: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Fechar loading dialog
      if (mounted) Navigator.of(context).pop();

      // Erro genérico
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar evento: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: _currentStep == 0 ? () => Navigator.pop(context) : _previousStep,
        ),
        title: const Text('Anunciar Evento', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Indicador de Progresso unificado
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Publique seu evento no mural da comunidade',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Preencha os campos principais e depois finalize em Publicar.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF536194)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Etapa ${_currentStep + 1} de $_totalSteps',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF536194)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Janelas Deslizantes
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentStep = page;
                });
              },
              children: [
                _buildStep1Basicos(),
                _buildStep2Localizacao(),
                _buildStep3MidiaVagas(),
                _buildStep4ContatoPublicacao(),
              ],
            ),
          ),

          // Painel de Ações Inferior Fixo
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildStep1Basicos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKeyStep1,
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Informações principais',
              children: [
                TextFormField(
                  controller: _nomeEventoController,
                  decoration: const InputDecoration(labelText: 'Nome do evento *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Insira o nome do evento' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _categoriaSelecionada,
                  decoration: const InputDecoration(labelText: 'Categoria *', border: OutlineInputBorder()),
                  items: ['Social', 'Cultural', 'Esportivo', 'Religioso', 'Educacional'].map((String category) {
                    return DropdownMenuItem<String>(value: category, child: Text(category));
                  }).toList(),
                  onChanged: (value) => setState(() => _categoriaSelecionada = value),
                  validator: (value) => value == null ? 'Selecione uma categoria' : null,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Público-alvo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _publicosAlvo.map((publico) {
                    final isSelected = _publicosSelecionados.contains(publico);
                    return FilterChip(
                      label: Text(publico),
                      selected: isSelected,
                      selectedColor: const Color(0xFF536194).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF536194),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _publicosSelecionados.add(publico);
                          } else {
                            _publicosSelecionados.remove(publico);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            _buildSectionCard(
              title: 'Descrição',
              children: [
                TextFormField(
                  controller: _descricaoController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Descrição completa *', border: OutlineInputBorder(), alignLabelWithHint: true),
                  validator: (value) => value == null || value.isEmpty ? 'Insira a descrição do evento' : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Localizacao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKeyStep2,
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Data e horário',
              children: [
                SwitchListTile(
                  title: const Text('Evento de dia inteiro', style: TextStyle(fontSize: 14)),
                  value: _isDiaInteiro,
                  activeColor: const Color(0xFF536194),
                  onChanged: (value) => setState(() => _isDiaInteiro = value),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}'),
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: _dataInicio, firstDate: DateTime(2026), lastDate: DateTime(2030));
                          if (date != null) setState(() => _dataInicio = date);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text('${_dataFim.day}/${_dataFim.month}/${_dataFim.year}'),
                        onPressed: () async {
                          final date = await showDatePicker(context: context, initialDate: _dataFim, firstDate: DateTime(2026), lastDate: DateTime(2030));
                          if (date != null) setState(() => _dataFim = date);
                        },
                      ),
                    ),
                  ],
                ),
                if (!_isDiaInteiro) const SizedBox(height: 8),
                if (!_isDiaInteiro)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(_horaInicio?.format(context) ?? 'Hora início'),
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (time != null) setState(() => _horaInicio = time);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(_horaFim?.format(context) ?? 'Hora fim'),
                          onPressed: () async {
                            final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (time != null) setState(() => _horaFim = time);
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _repeticaoSelecionada,
                  decoration: const InputDecoration(labelText: 'Repetição', border: OutlineInputBorder()),
                  items: ['Sem repeticao', 'Diário', 'Semanal', 'Mensal'].map((String rep) {
                    return DropdownMenuItem<String>(value: rep, child: Text(rep));
                  }).toList(),
                  onChanged: (value) => setState(() => _repeticaoSelecionada = value!),
                ),
              ],
            ),
            _buildSectionCard(
              title: 'Local',
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return ToggleButtons(
                      isSelected: [_formatoLocal == 'Presencial', _formatoLocal == 'Online', _formatoLocal == 'Híbrido'],
                      onPressed: (index) {
                        setState(() {
                          if (index == 0) _formatoLocal = 'Presencial';
                          if (index == 1) _formatoLocal = 'Online';
                          if (index == 2) _formatoLocal = 'Híbrido';
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      constraints: BoxConstraints.expand(width: (constraints.maxWidth - 4) / 3, height: 40),
                      selectedColor: const Color(0xFF536194),
                      fillColor: const Color(0xFF536194).withOpacity(0.1),
                      children: const [Text('Presencial'), Text('Online'), Text('Híbrido')],
                    );
                  }
                ),
                if (_formatoLocal != 'Online') const SizedBox(height: 16),
                if (_formatoLocal != 'Online')
                  TextFormField(
                    controller: _enderecoController,
                    decoration: const InputDecoration(labelText: 'Endereço (presencial) *', border: OutlineInputBorder()),
                    validator: (value) => _formatoLocal != 'Online' && (value == null || value.isEmpty) ? 'Insira o endereço do local' : null,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3MidiaVagas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKeyStep3,
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Mídia',
              children: [
                if (_capaImagem != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _capaImagem!.bytes,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else if (_capaImagemUrlExistente != null && _capaImagemUrlExistente!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _capaImagemUrlExistente!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.image),
                        label: const Text('Selecionar capa'),
                        onPressed: _selecionarCapa,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.collections),
                        label: const Text('Galeria'),
                        onPressed: _selecionarGaleria,
                      ),
                    ),
                  ],
                ),
                if (_capaImagem != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _capaImagem!.nome,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0F766E)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Galeria: ${_imagensGaleria.length} imagem(ns)',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ),
                if (_imagensGaleria.isNotEmpty || _imagensGaleriaUrlsExistentes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _imagensGaleria.isNotEmpty
                          ? _imagensGaleria.length
                          : _imagensGaleriaUrlsExistentes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (_imagensGaleria.isNotEmpty) {
                          final image = _imagensGaleria[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              image.bytes,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          );
                        }

                        final imageUrl = _imagensGaleriaUrlsExistentes[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            _buildSectionCard(
              title: 'Inscrição e vagas',
              children: [
                SwitchListTile(
                  title: const Text('Evento pago', style: TextStyle(fontSize: 14)),
                  value: _isEventoPago,
                  activeColor: const Color(0xFF536194),
                  onChanged: (value) => setState(() => _isEventoPago = value),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _limiteVagasController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Limite de vagas', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Necessita inscrição prévia', style: TextStyle(fontSize: 14)),
                  value: _necessitaInscricaoPrevia,
                  activeColor: const Color(0xFF536194),
                  onChanged: (value) => setState(() => _necessitaInscricaoPrevia = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4ContatoPublicacao() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Form(
        key: _formKeyStep4,
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Voluntariado',
              children: [
                SwitchListTile(
                  title: const Text('Permitir voluntários', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Ative se o evento precisar de apoio para organização.', style: TextStyle(fontSize: 12)),
                  value: _permitirVoluntarios,
                  activeColor: const Color(0xFF536194),
                  onChanged: (value) => setState(() => _permitirVoluntarios = value),
                ),
              ],
            ),
            _buildSectionCard(
              title: 'Acessibilidade e contato',
              children: [
                TextFormField(
                  controller: _acessibilidadeController,
                  decoration: const InputDecoration(labelText: 'Recursos de acessibilidade (opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _responsavelController,
                  decoration: const InputDecoration(labelText: 'Responsável *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Insira o responsável' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telefone de contato *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Insira o telefone' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail de contato', border: OutlineInputBorder()),
                ),
              ],
            ),
            _buildSectionCard(
              title: 'Publicação',
              children: [
                SwitchListTile(
                  title: const Text('Agendar publicação', style: TextStyle(fontSize: 14)),
                  value: _agendarPublicacao,
                  activeColor: const Color(0xFF536194),
                  onChanged: (value) => setState(() => _agendarPublicacao = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF536194)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Voltar', style: TextStyle(color: Color(0xFF536194), fontWeight: FontWeight.bold)),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (isLastStep) {
                    // Executa salvamento assíncrono no Supabase
                    _publicarEvento();
                  } else {
                    _nextStep();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF536194),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: Text(
                  isLastStep ? 'Publicar Evento' : 'Avançar',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}