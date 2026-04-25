import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class TanquesScreen extends StatefulWidget {
  const TanquesScreen({super.key});
  @override
  State<TanquesScreen> createState() => _TanquesScreenState();
}

class _TanquesScreenState extends State<TanquesScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final lista = provider.tanques
          .where((t) =>
              t.nome.toLowerCase().contains(_search.toLowerCase()) ||
              t.codigo.toLowerCase().contains(_search.toLowerCase()))
          .toList();

      return Scaffold(
        appBar: AppBar(title: const Text('Tanques')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar tanque...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const Center(
                      child: Text('Nenhum tanque cadastrado',
                          style: TextStyle(color: AppColors.textLight)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: lista.length,
                      itemBuilder: (ctx, i) {
                        final t = lista[i];
                        final produtores = provider.getProdutoresDeTanque(t.id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (t.tipo == TipoTanque.individual
                                        ? AppColors.primary
                                        : AppColors.accent)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                t.tipo == TipoTanque.individual
                                    ? Icons.person
                                    : Icons.group,
                                color: t.tipo == TipoTanque.individual
                                    ? AppColors.primary
                                    : AppColors.accent,
                              ),
                            ),
                            title: Text(t.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${t.tipo == TipoTanque.individual ? "Individual" : "Coletivo"} • ${t.capacidade.toStringAsFixed(0)} L • ${produtores.length} produtores'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (t.localizacao.isNotEmpty)
                                      _InfoRow(
                                          Icons.location_on, t.localizacao),
                                    if (t.latitude != null)
                                      _InfoRow(Icons.gps_fixed,
                                          formatLatLng(t.latitude, t.longitude)),
                                    const SizedBox(height: 8),
                                    const Text('Produtores vinculados:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    const SizedBox(height: 4),
                                    if (produtores.isEmpty)
                                      const Text('Nenhum produtor vinculado',
                                          style: TextStyle(
                                              color: AppColors.textLight,
                                              fontSize: 12))
                                    else
                                      Wrap(
                                        spacing: 6,
                                        children: produtores
                                            .map((p) => Chip(
                                                  label: Text(p.nome,
                                                      style: const TextStyle(
                                                          fontSize: 11)),
                                                  avatar: CircleAvatar(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    child: Text(
                                                      p.nome[0],
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10),
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    const SizedBox(height: 12),
                                    Row(children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Editar'),
                                          onPressed: () =>
                                              _openForm(context, t),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.delete,
                                              color: AppColors.error),
                                          label: const Text('Excluir',
                                              style: TextStyle(
                                                  color: AppColors.error)),
                                          onPressed: () => _confirmDelete(
                                              context, provider, t),
                                        ),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                            ],
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
          label: const Text('Novo Tanque'),
        ),
      );
    });
  }

  void _openForm(BuildContext context, Tanque? tanque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TanqueForm(tanque: tanque),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, Tanque t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Tanque'),
        content: Text('Deseja excluir o tanque ${t.nome}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              provider.deleteTanque(t.id);
              Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Icon(icon, size: 14, color: AppColors.textLight),
          const SizedBox(width: 4),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textLight))),
        ]),
      );
}

class TanqueForm extends StatefulWidget {
  final Tanque? tanque;
  const TanqueForm({super.key, this.tanque});
  @override
  State<TanqueForm> createState() => _TanqueFormState();
}

class _TanqueFormState extends State<TanqueForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome, _codigo, _capacidade, _localizacao;
  TipoTanque _tipo = TipoTanque.individual;
  List<String> _produtorsSelecionados = [];
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    final t = widget.tanque;
    _nome = TextEditingController(text: t?.nome ?? '');
    _codigo = TextEditingController(text: t?.codigo ?? '');
    _capacidade = TextEditingController(
        text: t?.capacidade.toStringAsFixed(0) ?? '');
    _localizacao = TextEditingController(text: t?.localizacao ?? '');
    _tipo = t?.tipo ?? TipoTanque.individual;
    _produtorsSelecionados = List.from(t?.produtorIds ?? []);
    _ativo = t?.ativo ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final produtores = provider.produtores.where((p) => p.ativo).toList();

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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  widget.tanque == null ? 'Novo Tanque' : 'Editar Tanque',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const Divider(),
              const SizedBox(height: 8),
              _field('Nome do Tanque*', _nome, required: true),
              const SizedBox(height: 12),
              _field('Código*', _codigo, required: true),
              const SizedBox(height: 12),
              _field('Capacidade (L)', _capacidade,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field('Localização / Endereço', _localizacao),
              const SizedBox(height: 12),
              const Text('Tipo do Tanque',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(children: [
                Expanded(
                  child: RadioListTile<TipoTanque>(
                    title: const Text('Individual'),
                    value: TipoTanque.individual,
                    groupValue: _tipo,
                    onChanged: (v) => setState(() => _tipo = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<TipoTanque>(
                    title: const Text('Coletivo'),
                    value: TipoTanque.coletivo,
                    groupValue: _tipo,
                    onChanged: (v) => setState(() => _tipo = v!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              const Text('Produtores Vinculados',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (produtores.isEmpty)
                const Text('Nenhum produtor ativo cadastrado',
                    style: TextStyle(color: AppColors.textLight))
              else
                Wrap(
                  spacing: 8,
                  children: produtores.map((p) {
                    final sel = _produtorsSelecionados.contains(p.id);
                    return FilterChip(
                      label: Text(p.nome),
                      selected: sel,
                      onSelected: (v) => setState(() {
                        if (v) {
                          _produtorsSelecionados.add(p.id);
                        } else {
                          _produtorsSelecionados.remove(p.id);
                        }
                      }),
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
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
                  child:
                      Text(widget.tanque == null ? 'Cadastrar' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {bool required = false,
      TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null
          : null,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final t = Tanque(
      id: widget.tanque?.id ?? generateId(),
      nome: _nome.text.trim(),
      codigo: _codigo.text.trim(),
      tipo: _tipo,
      capacidade: double.tryParse(_capacidade.text) ?? 0,
      localizacao: _localizacao.text.trim(),
      produtorIds: _produtorsSelecionados,
      ativo: _ativo,
      dataCadastro: widget.tanque?.dataCadastro ?? DateTime.now(),
    );
    if (widget.tanque == null) {
      provider.addTanque(t);
    } else {
      provider.updateTanque(t);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.tanque == null
            ? 'Tanque cadastrado!'
            : 'Tanque atualizado!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
