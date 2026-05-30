// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/dominio/entidades/servico.dart';
import 'package:centro_social_app/src/funcionalidades/agendamentos/apresentacao/provedores/provedores_agendamentos.dart';

class OfferServiceForm extends ConsumerStatefulWidget {
  final Service? initialService;

  const OfferServiceForm({super.key, this.initialService});

  @override
  ConsumerState<OfferServiceForm> createState() => _OfferServiceFormState();
}

class _OfferServiceFormState extends ConsumerState<OfferServiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _nomeProfissionalController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _localController = TextEditingController();
  final _observacoesController = TextEditingController();

  final List<String> _horariosDisponiveis = [];
  int? _duracaoAtendimento; // em minutos

  final List<String> _diasSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  final List<int> _duracoesPossiveis = [15, 30, 45, 60, 90, 120]; // em minutos
  final List<bool> _diasSelecionados = List.filled(7, false);

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  String? _tipoAtendimento; // 'presencial' ou 'online'

  bool _isLoading = false;
  late final bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialService != null;
    if (_isEditing) {
      _prefillForm(widget.initialService!);
    }
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

    final selected = service.diasDisponiveis.map(_normalizeDay).toSet();
    for (int i = 0; i < _diasSemana.length; i++) {
      final day = _normalizeDay(_diasSemana[i]);
      _diasSelecionados[i] = selected.contains(day);
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

  @override
  void dispose() {
    _nomeController.dispose();
    _categoriaController.dispose();
    _nomeProfissionalController.dispose();
    _descricaoController.dispose();
    _telefoneController.dispose();
    _localController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      // Abrir configurações do app
      await openAppSettings();
      return false;
    } else {
      return false;
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar Imagem'),
          content: const Text('Escolha a origem da imagem:'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage(ImageSource.camera);
              },
              child: const Text('Câmera'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickImage(ImageSource.gallery);
              },
              child: const Text('Galeria'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      Permission permission;
      if (source == ImageSource.camera) {
        permission = Permission.camera;
      } else {
        permission = Permission.photos;
      }

      final hasPermission = await _requestPermission(permission);
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permissão necessária para acessar a imagem. Vá para configurações e conceda a permissão.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        print('DEBUG: Imagem selecionada: ${image.path}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _addHorario() async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Selecione horário de início',
    );

    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: startTime.hour + 1,
        minute: startTime.minute,
      ),
      helpText: 'Selecione horário de fim',
    );

    if (endTime == null) return;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (startMinutes >= endMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horário de fim deve ser após o início')),
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

  Future<void> _deleteStorageImageByUrl(String? imageUrl) async {
    final path = _extractStoragePathFromPublicUrl(imageUrl);
    if (path == null) {
      return;
    }

    await Supabase.instance.client.storage.from('servicos_images').remove([
      path,
    ]);
  }

  Future<void> _deleteStorageImageByPath(String? imagePath) async {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }

    await Supabase.instance.client.storage.from('servicos_images').remove([
      imagePath,
    ]);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_horariosDisponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um horário disponível'),
        ),
      );
      return;
    }

    if (_duracaoAtendimento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a duração do atendimento')),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário não logado. Faça login novamente.'),
        ),
      );
      return;
    }

    // Debug: mostrar userId
    print('DEBUG: UserID obtido: $userId');

    // Verificar se o perfil do usuário existe
    try {
      print('DEBUG: Verificando perfil na tabela profiles...');
      final profileCheck = await Supabase.instance.client
          .from('profiles')
          .select('id, email, full_name')
          .eq('id', userId)
          .maybeSingle();

      print('DEBUG: Resultado da verificação de perfil: $profileCheck');

      if (profileCheck == null) {
        print('DEBUG: Perfil não encontrado para userId: $userId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Perfil não encontrado (ID: $userId). Tente fazer logout e login novamente.',
            ),
          ),
        );
        return;
      }

      print('DEBUG: Perfil encontrado: ${profileCheck['email']}');
    } catch (profileError) {
      print('DEBUG: Erro ao verificar perfil: $profileError');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao verificar perfil: $profileError')),
      );
      return;
    }

    final diasSelecionados = _diasSemana
        .asMap()
        .entries
        .where((entry) => _diasSelecionados[entry.key])
        .map((entry) => entry.value)
        .toList();

    setState(() => _isLoading = true);

    final previousImageUrl = widget.initialService?.imagemProfissional;
    String? uploadedImagePath;
    bool servicePersisted = false;

    try {
      String? imageUrl = widget.initialService?.imagemProfissional;
      if (_selectedImage != null) {
        try {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '$userId/$timestamp.jpg';
          uploadedImagePath = fileName;
          await Supabase.instance.client.storage
              .from('servicos_images')
              .upload(fileName, _selectedImage!);

          imageUrl = Supabase.instance.client.storage
              .from('servicos_images')
              .getPublicUrl(fileName);
        } catch (imageError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Aviso: Não foi possível fazer upload da imagem. Serviço será publicado sem imagem. Erro: $imageError',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          imageUrl = _isEditing ? previousImageUrl : null;
          uploadedImagePath = null;
        }
      }

      // Verificação final antes do insert
      print('DEBUG: Verificação final - UserID: $userId');
      print(
        'DEBUG: Current session: ${Supabase.instance.client.auth.currentSession}',
      );

      final finalProfileCheck = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .single();

      print('DEBUG: Verificação final passou: ${finalProfileCheck['id']}');

      final payload = {
        'user_id': userId,
        'nome': _nomeController.text.trim(),
        'categoria': _categoriaController.text.trim(),
        'nome_profissional': _nomeProfissionalController.text.trim(),
        'imagem_profissional': imageUrl,
        'descricao': _descricaoController.text.trim(),
        'dias_disponiveis': diasSelecionados,
        'horarios': _horariosDisponiveis,
        'duracao_atendimento': _duracaoAtendimento,
        'tipo_atendimento': _tipoAtendimento,
        'local': _tipoAtendimento == 'presencial'
            ? _localController.text.trim()
            : null,
        'telefone': _telefoneController.text.trim(),
        'observacoes': _observacoesController.text.trim(),
      };

      if (_isEditing) {
        final updatedRows = await Supabase.instance.client
            .from('servicos')
            .update(payload)
            .eq('id', widget.initialService!.id)
            .eq('user_id', userId)
            .select();

        final updatedList = (updatedRows as List<dynamic>);
        if (updatedList.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nao foi possivel atualizar o servico.'),
              ),
            );
          }
          return;
        }

        final updatedService = Service.fromJson(
          updatedList.first as Map<String, dynamic>,
        );
        servicePersisted = true;

        if (_selectedImage != null &&
            previousImageUrl != null &&
            imageUrl != null &&
            previousImageUrl != imageUrl) {
          try {
            await _deleteStorageImageByUrl(previousImageUrl);
          } catch (deleteOldImageError) {
            print('DEBUG: Erro ao excluir imagem antiga: $deleteOldImageError');
          }
        }

        if (mounted) {
          ref.invalidate(myServicesProvider);
          ref.invalidate(publishedServicesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Servico atualizado com sucesso!')),
          );
          Navigator.of(context).pop(updatedService);
        }
      } else {
        await Supabase.instance.client.from('servicos').insert({
          ...payload,
          'status': 'ativo',
        });
        servicePersisted = true;

        ref.invalidate(myServicesProvider);
        ref.invalidate(publishedServicesProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servico publicado com sucesso!')),
        );

        // Limpar formulário ou navegar
        _formKey.currentState!.reset();
        _categoriaController.clear();
        _nomeProfissionalController.clear();
        _localController.clear();
        setState(() {
          _diasSelecionados.fillRange(0, 7, false);
          _tipoAtendimento = null;
          _horariosDisponiveis.clear();
          _duracaoAtendimento = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao enviar: $e')));
    } finally {
      if (!servicePersisted && uploadedImagePath != null) {
        try {
          await _deleteStorageImageByPath(uploadedImagePath);
        } catch (rollbackImageError) {
          print(
            'DEBUG: Erro ao remover imagem após falha de persistência: $rollbackImageError',
          );
        }
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do serviço'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeProfissionalController,
              decoration: const InputDecoration(
                labelText: 'Nome do profissional',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            const Text('Imagem do profissional'),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : (widget.initialService?.imagemProfissional != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.initialService!.imagemProfissional!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Text(
                                    'Nao foi possivel carregar a imagem',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Nenhuma imagem selecionada',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.image),
              label: const Text('Selecionar Imagem'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoriaController,
              decoration: const InputDecoration(labelText: 'Categoria'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição do serviço',
              ),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            const Text('Dias disponíveis'),
            ...List.generate(_diasSemana.length, (index) {
              return CheckboxListTile(
                title: Text(_diasSemana[index]),
                value: _diasSelecionados[index],
                onChanged: (value) =>
                    setState(() => _diasSelecionados[index] = value ?? false),
              );
            }),
            const SizedBox(height: 16),
            const Text('Horários disponíveis'),
            const SizedBox(height: 8),
            if (_horariosDisponiveis.isEmpty)
              const Text('Nenhum horário adicionado')
            else
              Column(
                children: _horariosDisponiveis.asMap().entries.map((entry) {
                  final index = entry.key;
                  final horario = entry.value;
                  return Card(
                    child: ListTile(
                      title: Text(horario),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeHorario(index),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addHorario,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Horário'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _duracaoAtendimento,
              decoration: const InputDecoration(
                labelText: 'Duração do atendimento',
              ),
              items: _duracoesPossiveis.map((duracao) {
                return DropdownMenuItem(
                  value: duracao,
                  child: Text('$duracao minutos'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _duracaoAtendimento = value),
              validator: (value) =>
                  value == null ? 'Selecione a duração do atendimento' : null,
            ),
            const SizedBox(height: 16),
            const Text('Atendimento'),
            RadioListTile<String>(
              title: const Text('Presencial'),
              value: 'presencial',
              groupValue: _tipoAtendimento,
              onChanged: (value) => setState(() => _tipoAtendimento = value),
            ),
            RadioListTile<String>(
              title: const Text('Online'),
              value: 'online',
              groupValue: _tipoAtendimento,
              onChanged: (value) => setState(() => _tipoAtendimento = value),
            ),
            if (_tipoAtendimento == 'presencial') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _localController,
                decoration: const InputDecoration(
                  labelText: 'Local de atendimento',
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Campo obrigatório para atendimento presencial'
                    : null,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _telefoneController,
              decoration: const InputDecoration(
                labelText: 'Telefone para contato',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações adicionais (opcional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Publicar Serviço'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
