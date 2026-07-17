// ignore_for_file: use_build_context_synchronously

import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/nucleo/notificacoes/servico_notificacoes.dart';
import 'package:centro_social_app/src/nucleo/utilitarios/imagem_selecionada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfferServiceForm extends ConsumerStatefulWidget {
  final Service? initialService;

  const OfferServiceForm({super.key, this.initialService});

  @override
  ConsumerState<OfferServiceForm> createState() => _OfferServiceFormState();
}

class _OfferServiceFormState extends ConsumerState<OfferServiceForm> {
  final ServicoNotificacoes _notificacoes = ServicoNotificacoes();
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKeyStep1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyStep2 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyStep3 = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _nomeProfissionalController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _localController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  final List<String> _horariosDisponiveis = <String>[];
  final List<String> _diasSemana = <String>[
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  final List<int> _duracoesPossiveis = <int>[15, 30, 45, 60, 90, 120];
  final List<bool> _diasSelecionados = List<bool>.filled(7, false);
  final List<DateTime> _datasEspecificas = <DateTime>[];

  int _currentStep = 0;
  final int _totalSteps = 3;
  int? _duracaoAtendimento;
  String? _tipoAtendimento;
  ImagemSelecionada? _selectedImage;
  String? _existingImageUrl;
  late final bool _isEditing;
  final ImagePicker _picker = ImagePicker();

  /// 'dias_semana' ou 'datas_especificas'
  String _tipoDisponibilidade = 'dias_semana';

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialService != null;
    if (_isEditing) {
      _prefillForm(widget.initialService!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomeController.dispose();
    _categoriaController.dispose();
    _nomeProfissionalController.dispose();
    _descricaoController.dispose();
    _telefoneController.dispose();
    _localController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _prefillForm(Service service) {
    _nomeController.text = service.nome;
    _categoriaController.text = service.categoria;
    _nomeProfissionalController.text = service.nomeProfissional;
    _descricaoController.text = service.descricao;
    _telefoneController.text = service.telefone;
    _localController.text = service.local ?? '';
    _observacoesController.text = service.observacoes ?? '';
    _tipoAtendimento = service.tipoAtendimento;
    _duracaoAtendimento = service.duracaoAtendimento;
    _horariosDisponiveis
      ..clear()
      ..addAll(service.horarios);
    _existingImageUrl = service.imagemProfissional;

    // Carregar dias da semana
    final selected = service.diasDisponiveis.map(_normalizeDay).toSet();
    for (var i = 0; i < _diasSemana.length; i++) {
      final day = _normalizeDay(_diasSemana[i]);
      _diasSelecionados[i] = selected.contains(day);
    }

    // Carregar datas específicas se existirem
    if (service.datasEspecificas != null && service.datasEspecificas!.isNotEmpty) {
      _tipoDisponibilidade = 'datas_especificas';
      _datasEspecificas
        ..clear()
        ..addAll(service.datasEspecificas!);
    }
  }

  String _normalizeDay(String value) {
    final lower = value.toLowerCase().trim();
    if (lower.startsWith('seg')) return 'seg';
    if (lower.startsWith('ter')) return 'ter';
    if (lower.startsWith('qua')) return 'qua';
    if (lower.startsWith('qui')) return 'qui';
    if (lower.startsWith('sex')) return 'sex';
    if (lower.startsWith('sab') || lower.startsWith('sáb')) return 'sab';
    if (lower.startsWith('dom')) return 'dom';
    return lower;
  }

  void _nextStep() {
    bool isValid = false;
    if (_currentStep == 0) {
      isValid = _formKeyStep1.currentState?.validate() ?? false;
    } else if (_currentStep == 1) {
      if (_tipoDisponibilidade == 'dias_semana') {
        final hasSelectedDay = _diasSelecionados.any((selected) => selected);
        if (_horariosDisponiveis.isEmpty || !hasSelectedDay) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecione pelo menos um dia e adicione pelo menos um horário disponível.')),
          );
          return;
        }
      } else {
        if (_datasEspecificas.isEmpty || _horariosDisponiveis.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicione pelo menos uma data específica e um horário disponível.')),
          );
          return;
        }
      }

      isValid = _formKeyStep2.currentState?.validate() ?? false;
    } else if (_currentStep == 2) {
      isValid = _formKeyStep3.currentState?.validate() ?? false;
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios antes de avançar.')),
      );
      return;
    }

    if (_currentStep < _totalSteps - 1) {
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image != null) {
        final selecionada = await ImagemSelecionada.deXFile(image);
        if (!mounted) return;
        setState(() {
          _selectedImage = selecionada;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar imagem'),
          content: const Text('Escolha a origem da imagem do profissional.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.gallery);
              },
              child: const Text('Galeria'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
              },
              child: const Text('Câmera'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addHorario() async {
    final startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Selecione horário de início',
    );

    if (startTime == null) return;

    final endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
      helpText: 'Selecione horário de fim',
    );

    if (endTime == null) return;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O horário de fim deve ser após o início.')),
      );
      return;
    }

    final horario = '${startTime.format(context)}-${endTime.format(context)}';
    setState(() {
      _horariosDisponiveis.add(horario);
    });
  }

  void _removeHorario(int index) {
    setState(() {
      _horariosDisponiveis.removeAt(index);
    });
  }

  Future<void> _adicionarDataEspecifica() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Selecione uma data disponível',
    );

    if (date == null) return;

    // Verificar se a data já foi adicionada
    final alreadyAdded = _datasEspecificas.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);

    if (alreadyAdded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta data já foi adicionada.')),
        );
      }
      return;
    }

    setState(() {
      _datasEspecificas.add(date);
      // Ordenar as datas
      _datasEspecificas.sort((a, b) => a.compareTo(b));
    });
  }

  void _removerDataEspecifica(int index) {
    setState(() {
      _datasEspecificas.removeAt(index);
    });
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

    return Uri.decodeComponent(segments.sublist(bucketIndex + 1).join('/'));
  }

  Future<void> _deleteStorageImageByUrl(String? imageUrl) async {
    final path = _extractStoragePathFromPublicUrl(imageUrl);
    if (path == null) return;

    await Supabase.instance.client.storage.from('servicos_images').remove([path]);
  }

  Future<void> _submitForm() async {
    if (!_formKeyStep3.currentState!.validate()) {
      return;
    }

    if (_duracaoAtendimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a duração do atendimento.')),
      );
      return;
    }

    if (_tipoAtendimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo de atendimento.')),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado.')),
      );
      return;
    }

    final previousImageUrl = widget.initialService?.imagemProfissional;
    final diasSelecionados = _diasSemana
        .asMap()
        .entries
        .where((entry) => _diasSelecionados[entry.key])
        .map((entry) => entry.value)
        .toList();

    // Formatar datas específicas como strings ISO (YYYY-MM-DD)
    final datasEspecificasStr = _datasEspecificas
        .map((d) => DateFormat('yyyy-MM-dd').format(d))
        .toList();

    String? imageUrl = previousImageUrl;
    String? uploadedImagePath;
    bool persisted = false;

    try {
      if (_selectedImage != null) {
        final imagem = _selectedImage!;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '$userId/$timestamp.${imagem.extensao}';
        uploadedImagePath = fileName;

        await Supabase.instance.client.storage
            .from('servicos_images')
            .uploadBinary(
              fileName,
              imagem.bytes,
              fileOptions: FileOptions(contentType: imagem.contentType),
            );

        imageUrl = Supabase.instance.client.storage
            .from('servicos_images')
            .getPublicUrl(fileName);
      }

      final payload = {
        'user_id': userId,
        'nome': _nomeController.text.trim(),
        'categoria': _categoriaController.text.trim(),
        'nome_profissional': _nomeProfissionalController.text.trim(),
        'imagem_profissional': imageUrl,
        'descricao': _descricaoController.text.trim(),
        'dias_disponiveis': diasSelecionados,
        'datas_especificas':
            _tipoDisponibilidade == 'datas_especificas' ? datasEspecificasStr : null,
        'horarios': _horariosDisponiveis,
        'duracao_atendimento': _duracaoAtendimento,
        'tipo_atendimento': _tipoAtendimento,
        'local': _tipoAtendimento == 'presencial'
            ? _localController.text.trim()
            : null,
        'telefone': _telefoneController.text.trim(),
        'observacoes': _observacoesController.text.trim(),
      };

      if (_isEditing && widget.initialService != null) {
        final rows = await Supabase.instance.client
            .from('servicos')
            .update(payload)
            .eq('id', widget.initialService!.id)
            .eq('user_id', userId)
            .select();

        final updatedList = rows as List<dynamic>;
        if (updatedList.isEmpty) {
          throw Exception('Não foi possível atualizar o serviço.');
        }

        final updatedService = Service.fromJson(updatedList.first as Map<String, dynamic>);
        persisted = true;

        if (_selectedImage != null && previousImageUrl != null && previousImageUrl.isNotEmpty) {
          try {
            await _deleteStorageImageByUrl(previousImageUrl);
          } catch (_) {}
        }

        if (mounted) {
          ref.invalidate(myServicesProvider);
          ref.invalidate(publishedServicesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviço atualizado com sucesso!')),
          );
          Navigator.of(context).pop(updatedService);
        }
      } else {
        await Supabase.instance.client.from('servicos').insert({
          ...payload,
          'status': 'ativo',
        });
        persisted = true;

        await _notificacoes.enviarParaTodos(
          titulo: 'Novo serviço disponível',
          corpo: '${_nomeController.text.trim()} agora está disponível.',
          dados: {
            'tipo': 'service_published',
            'service_name': _nomeController.text.trim(),
          },
        );

        if (mounted) {
          ref.invalidate(myServicesProvider);
          ref.invalidate(publishedServicesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Serviço publicado com sucesso!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar serviço: $e')),
        );
      }
    } finally {
      if (!persisted && uploadedImagePath != null) {
        try {
          await Supabase.instance.client.storage.from('servicos_images').remove([uploadedImagePath]);
        } catch (_) {}
      }
    }
  }

  Widget _buildProgressHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Publique ou edite seu serviço de forma segura',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Organize os dados principais, disponibilidade e contato em etapas claras.',
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
      ],
    );
  }

  Widget _buildStep1Dados() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Form(
          key: _formKeyStep1,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do serviço *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome do serviço' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoriaController,
                decoration: const InputDecoration(labelText: 'Categoria *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Informe a categoria' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeProfissionalController,
                decoration: const InputDecoration(labelText: 'Nome do profissional *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome do profissional' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Descrição *', border: OutlineInputBorder(), alignLabelWithHint: true),
                validator: (value) => value == null || value.trim().isEmpty ? 'Descreva o serviço' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Disponibilidade() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Form(
          key: _formKeyStep2,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seletor de tipo de disponibilidade
              const Text('Tipo de disponibilidade', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'dias_semana',
                    label: Text('Dias da semana'),
                    icon: Icon(Icons.calendar_view_week),
                  ),
                  ButtonSegment(
                    value: 'datas_especificas',
                    label: Text('Datas específicas'),
                    icon: Icon(Icons.calendar_today),
                  ),
                ],
                selected: {_tipoDisponibilidade},
                onSelectionChanged: (selected) {
                  setState(() => _tipoDisponibilidade = selected.first);
                },
              ),
              const SizedBox(height: 16),

              // Conteúdo baseado no tipo selecionado
              if (_tipoDisponibilidade == 'dias_semana') ...[
                const Text('Dias disponíveis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(_diasSemana.length, (index) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_diasSemana[index]),
                    value: _diasSelecionados[index],
                    onChanged: (value) => setState(() => _diasSelecionados[index] = value ?? false),
                  );
                }),
              ] else ...[
                const Text('Datas específicas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_datasEspecificas.isEmpty)
                  const Text('Nenhuma data adicionada.', style: TextStyle(color: Color(0xFF64748B)))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _datasEspecificas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final date = entry.value;
                      return Chip(
                        label: Text(DateFormat('dd/MM/yyyy').format(date)),
                        onDeleted: () => _removerDataEspecifica(index),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _adicionarDataEspecifica,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar data'),
                ),
              ],

              const SizedBox(height: 16),
              const Text('Horários disponíveis', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_horariosDisponiveis.isEmpty)
                const Text('Nenhum horário adicionado.', style: TextStyle(color: Color(0xFF64748B)))
              else
                Column(
                  children: _horariosDisponiveis.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Card(
                      child: ListTile(
                        title: Text(entry.value),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeHorario(index),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addHorario,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar horário'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _duracaoAtendimento,
                decoration: const InputDecoration(labelText: 'Duração do atendimento *', border: OutlineInputBorder()),
                items: _duracoesPossiveis.map((d) => DropdownMenuItem(value: d, child: Text('$d minutos'))).toList(),
                onChanged: (value) => setState(() => _duracaoAtendimento = value),
                validator: (value) => value == null ? 'Selecione a duração' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep3ContatoMidia() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Form(
          key: _formKeyStep3,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Imagem do profissional', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_selectedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _selectedImage!.bytes,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _existingImageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8))),
                    ),
                  ),
                )
              else
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(child: Text('Nenhuma imagem selecionada', style: TextStyle(color: Color(0xFF64748B)))),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Selecionar imagem'),
                ),
              ),
              const SizedBox(height: 16),
              FormField<String>(
                initialValue: _tipoAtendimento,
                validator: (value) => (value == null || value.isEmpty) ? 'Selecione o tipo de atendimento' : null,
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tipo de atendimento', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      RadioListTile<String>(
                        title: const Text('Presencial'),
                        value: 'presencial',
                        groupValue: _tipoAtendimento,
                        onChanged: (value) {
                          setState(() => _tipoAtendimento = value);
                          field.didChange(value);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Online'),
                        value: 'online',
                        groupValue: _tipoAtendimento,
                        onChanged: (value) {
                          setState(() => _tipoAtendimento = value);
                          field.didChange(value);
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            field.errorText ?? 'Selecione o tipo de atendimento',
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (_tipoAtendimento == 'presencial') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _localController,
                  decoration: const InputDecoration(labelText: 'Local de atendimento *', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o local' : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone para contato *', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Informe o telefone' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacoesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Observações (opcional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        _buildProgressHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [
                _buildStep1Dados(),
                _buildStep2Disponibilidade(),
                _buildStep3ContatoMidia(),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    child: const Text('Voltar'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _currentStep < _totalSteps - 1 ? _nextStep : _submitForm,
                  child: Text(_currentStep < _totalSteps - 1 ? 'Avançar' : 'Publicar Serviço'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}