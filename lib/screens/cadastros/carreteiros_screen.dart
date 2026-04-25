import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class CarreteirosScreen extends StatelessWidget {
  const CarreteirosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final lista = provider.carreteiros;
      return Scaffold(
        appBar: AppBar(title: const Text('Carreteiros')),
        body: lista.isEmpty
            ? const Center(
                child: Text('Nenhum carreteiro cadastrado',
                    style: TextStyle(color: AppColors.textLight)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  final c = lista[i];
                  final caminhao = provider.getCaminhaoById(c.caminhaoId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.success,
                        child: Text(
                          c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(c.nome,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CNH: ${c.cnh.isNotEmpty ? c.cnh : "N/A"} • ${c.telefone}'),
                          if (caminhao != null)
                            Row(children: [
                              const Icon(Icons.local_shipping,
                                  size: 13, color: AppColors.info),
                              const SizedBox(width: 4),
                              Text(
                                '${caminhao.placa} — ${caminhao.marca} ${caminhao.modelo} (${caminhao.totalCompartimentos} bocas)',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.info),
                              ),
                            ])
                          else
                            const Text('Sem caminhão vinculado',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textLight)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (!c.ativo)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Chip(
                                label: Text('Inativo',
                                    style: TextStyle(fontSize: 10))),
                          ),
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppColors.primary),
                            onPressed: () => _openForm(context, c, provider)),
                        IconButton(
                            icon: const Icon(Icons.delete,
                                color: AppColors.error),
                            onPressed: () =>
                                _confirmDelete(context, provider, c)),
                      ]),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, null, context.read<AppProvider>()),
          icon: const Icon(Icons.add),
          label: const Text('Novo Carreteiro'),
        ),
      );
    });
  }

  void _openForm(BuildContext context, Carreteiro? c, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CarreiroForm(carreteiro: c, provider: provider),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, Carreteiro c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Carreteiro'),
        content: Text('Deseja excluir ${c.nome}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              provider.deleteCarreteiro(c.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class CarreiroForm extends StatefulWidget {
  final Carreteiro? carreteiro;
  final AppProvider provider;
  const CarreiroForm({super.key, this.carreteiro, required this.provider});
  @override
  State<CarreiroForm> createState() => _CarreiroFormState();
}

class _CarreiroFormState extends State<CarreiroForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome, _cpf, _cnh, _tel;
  String _caminhaoId = '';
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    final c = widget.carreteiro;
    _nome = TextEditingController(text: c?.nome ?? '');
    _cpf = TextEditingController(text: c?.cpf ?? '');
    _cnh = TextEditingController(text: c?.cnh ?? '');
    _tel = TextEditingController(text: c?.telefone ?? '');
    _caminhaoId = c?.caminhaoId ?? '';
    _ativo = c?.ativo ?? true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _cnh.dispose();
    _tel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caminhoes =
        widget.provider.caminhoes.where((c) => c.ativo).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.carreteiro == null
                        ? 'Novo Carreteiro'
                        : 'Editar Carreteiro',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Nome
              TextFormField(
                controller: _nome,
                decoration:
                    const InputDecoration(labelText: 'Nome Completo*'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),

              // CPF
              TextFormField(
                  controller: _cpf,
                  decoration: const InputDecoration(labelText: 'CPF')),
              const SizedBox(height: 12),

              // CNH
              TextFormField(
                  controller: _cnh,
                  decoration: const InputDecoration(labelText: 'CNH')),
              const SizedBox(height: 12),

              // Telefone
              TextFormField(
                  controller: _tel,
                  decoration:
                      const InputDecoration(labelText: 'Telefone')),
              const SizedBox(height: 12),

              // Caminhão vinculado
              DropdownButtonFormField<String>(
                value: _caminhaoId.isEmpty ? null : _caminhaoId,
                decoration: const InputDecoration(
                  labelText: 'Caminhão Vinculado',
                  prefixIcon:
                      Icon(Icons.local_shipping, color: AppColors.info),
                  helperText:
                      'Caminhão padrão que este motorista opera',
                ),
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('Nenhum (sem vínculo)')),
                  ...caminhoes.map((cam) => DropdownMenuItem(
                        value: cam.id,
                        child: Row(children: [
                          const Icon(Icons.local_shipping,
                              size: 16, color: AppColors.info),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${cam.placa} — ${cam.marca} ${cam.modelo} (${cam.totalCompartimentos} bocas)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      )),
                ],
                onChanged: (v) => setState(() => _caminhaoId = v ?? ''),
              ),
              const SizedBox(height: 12),

              // Ativo
              SwitchListTile(
                title: const Text('Ativo'),
                value: _ativo,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _ativo = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.carreteiro == null
                      ? 'Cadastrar'
                      : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final c = Carreteiro(
      id: widget.carreteiro?.id ?? generateId(),
      nome: _nome.text.trim(),
      cpf: _cpf.text.trim(),
      cnh: _cnh.text.trim(),
      telefone: _tel.text.trim(),
      caminhaoId: _caminhaoId,
      ativo: _ativo,
      dataCadastro: widget.carreteiro?.dataCadastro ?? DateTime.now(),
    );
    if (widget.carreteiro == null) {
      widget.provider.addCarreteiro(c);
    } else {
      widget.provider.updateCarreteiro(c);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.carreteiro == null
          ? 'Carreteiro cadastrado!'
          : 'Carreteiro atualizado!'),
      backgroundColor: AppColors.success,
    ));
  }
}
