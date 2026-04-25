import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class ProdutoresScreen extends StatefulWidget {
  const ProdutoresScreen({super.key});
  @override
  State<ProdutoresScreen> createState() => _ProdutoresScreenState();
}

class _ProdutoresScreenState extends State<ProdutoresScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final lista = provider.produtores
          .where((p) =>
              p.nome.toLowerCase().contains(_search.toLowerCase()) ||
              p.codigo.toLowerCase().contains(_search.toLowerCase()))
          .toList();

      return Scaffold(
        appBar: AppBar(
          title: const Text('Produtores'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _openForm(context, null),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar produtor...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off,
                              size: 64, color: AppColors.textLight),
                          SizedBox(height: 12),
                          Text('Nenhum produtor encontrado',
                              style: TextStyle(color: AppColors.textLight)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: lista.length,
                      itemBuilder: (ctx, i) {
                        final p = lista[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                p.nome.isNotEmpty
                                    ? p.nome[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(p.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Cód: ${p.codigo} • ${p.municipio}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!p.ativo)
                                  const Chip(
                                    label: Text('Inativo',
                                        style: TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.grey,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.primary),
                                  onPressed: () => _openForm(context, p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: AppColors.error),
                                  onPressed: () =>
                                      _confirmDelete(context, provider, p),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, null),
          icon: const Icon(Icons.add),
          label: const Text('Novo Produtor'),
        ),
      );
    });
  }

  void _openForm(BuildContext context, Produtor? produtor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProdutorForm(produtor: produtor),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, Produtor p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Produtor'),
        content: Text('Deseja excluir o produtor ${p.nome}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              provider.deleteProdutor(p.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class ProdutorForm extends StatefulWidget {
  final Produtor? produtor;
  const ProdutorForm({super.key, this.produtor});
  @override
  State<ProdutorForm> createState() => _ProdutorFormState();
}

class _ProdutorFormState extends State<ProdutorForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome, _codigo, _cpf, _tel, _municipio, _estado;
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    final p = widget.produtor;
    _nome = TextEditingController(text: p?.nome ?? '');
    _codigo = TextEditingController(text: p?.codigo ?? '');
    _cpf = TextEditingController(text: p?.cpfCnpj ?? '');
    _tel = TextEditingController(text: p?.telefone ?? '');
    _municipio = TextEditingController(text: p?.municipio ?? '');
    _estado = TextEditingController(text: p?.estado ?? '');
    _ativo = p?.ativo ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.produtor == null
                        ? 'Novo Produtor'
                        : 'Editar Produtor',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _field('Nome Completo*', _nome, required: true),
              const SizedBox(height: 12),
              _field('Código do Produtor*', _codigo, required: true),
              const SizedBox(height: 12),
              _field('CPF/CNPJ', _cpf),
              const SizedBox(height: 12),
              _field('Telefone', _tel),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field('Município', _municipio)),
                const SizedBox(width: 12),
                SizedBox(width: 80, child: _field('UF', _estado)),
              ]),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Ativo'),
                value: _ativo,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _ativo = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.produtor == null ? 'Cadastrar' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null
          : null,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final p = Produtor(
      id: widget.produtor?.id ?? generateId(),
      nome: _nome.text.trim(),
      codigo: _codigo.text.trim(),
      cpfCnpj: _cpf.text.trim(),
      telefone: _tel.text.trim(),
      municipio: _municipio.text.trim(),
      estado: _estado.text.trim(),
      ativo: _ativo,
      dataCadastro: widget.produtor?.dataCadastro ?? DateTime.now(),
    );
    if (widget.produtor == null) {
      provider.addProdutor(p);
    } else {
      provider.updateProdutor(p);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.produtor == null
            ? 'Produtor cadastrado!'
            : 'Produtor atualizado!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
