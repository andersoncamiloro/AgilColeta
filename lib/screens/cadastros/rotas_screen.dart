import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class RotasScreen extends StatelessWidget {
  const RotasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final lista = provider.rotas;
      return Scaffold(
        appBar: AppBar(title: const Text('Rotas de Coleta')),
        body: lista.isEmpty
            ? const Center(child: Text('Nenhuma rota cadastrada', style: TextStyle(color: AppColors.textLight)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  final r = lista[i];
                  final carreteiro = provider.getCarreiroById(r.carreiroId);
                  final caminhao = provider.getCaminhaoById(r.caminhaoId);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.route, color: AppColors.primary),
                      ),
                      title: Text(r.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Cód: ${r.codigo} • ${r.tanqueIds.length} tanques'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (carreteiro != null)
                              _InfoChip(Icons.person, 'Carreteiro: ${carreteiro.nome}'),
                            if (caminhao != null)
                              _InfoChip(Icons.local_shipping, 'Caminhão: ${caminhao.placa}'),
                            if (r.descricao.isNotEmpty)
                              _InfoChip(Icons.info, r.descricao),
                            const SizedBox(height: 8),
                            const Text('Tanques na rota:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            ...r.tanqueIds.asMap().entries.map((entry) {
                              final tanque = provider.getTanqueById(entry.value);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    child: Center(child: Text('${entry.key + 1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(tanque?.nome ?? 'Tanque não encontrado',
                                      style: const TextStyle(fontSize: 13)),
                                ]),
                              );
                            }),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit), label: const Text('Editar'),
                                onPressed: () => _openForm(context, r),
                              )),
                              const SizedBox(width: 8),
                              Expanded(child: OutlinedButton.icon(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                label: const Text('Excluir', style: TextStyle(color: AppColors.error)),
                                onPressed: () => _confirmDelete(context, provider, r),
                              )),
                            ]),
                          ]),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, null),
          icon: const Icon(Icons.add),
          label: const Text('Nova Rota'),
        ),
      );
    });
  }

  void _openForm(BuildContext context, Rota? r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RotaForm(rota: r),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, Rota r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Rota'),
        content: Text('Deseja excluir a rota ${r.nome}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () { provider.deleteRota(r.id); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      Icon(icon, size: 14, color: AppColors.primary),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
    ]),
  );
}

class RotaForm extends StatefulWidget {
  final Rota? rota;
  const RotaForm({super.key, this.rota});
  @override
  State<RotaForm> createState() => _RotaFormState();
}

class _RotaFormState extends State<RotaForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nome, _codigo, _descricao;
  String _carreiroId = '';
  String _caminhaoId = '';
  List<String> _tanqueIds = [];

  @override
  void initState() {
    super.initState();
    final r = widget.rota;
    _nome = TextEditingController(text: r?.nome ?? '');
    _codigo = TextEditingController(text: r?.codigo ?? '');
    _descricao = TextEditingController(text: r?.descricao ?? '');
    _carreiroId = r?.carreiroId ?? '';
    _caminhaoId = r?.caminhaoId ?? '';
    _tanqueIds = List.from(r?.tanqueIds ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final carreteiros = provider.carreteiros.where((c) => c.ativo).toList();
    final caminhoes = provider.caminhoes.where((c) => c.ativo).toList();
    final tanques = provider.tanques.where((t) => t.ativo).toList();

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
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.rota == null ? 'Nova Rota' : 'Editar Rota',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const Divider(),
            const SizedBox(height: 8),
            TextFormField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome da Rota*'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _codigo, decoration: const InputDecoration(labelText: 'Código*'),
                validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _carreiroId.isEmpty ? null : _carreiroId,
              decoration: const InputDecoration(labelText: 'Carreteiro'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Selecione...')),
                ...carreteiros.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))),
              ],
              onChanged: (v) => setState(() => _carreiroId = v ?? ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _caminhaoId.isEmpty ? null : _caminhaoId,
              decoration: const InputDecoration(labelText: 'Caminhão'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Selecione...')),
                ...caminhoes.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.placa} - ${c.marca}'))),
              ],
              onChanged: (v) => setState(() => _caminhaoId = v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _descricao, decoration: const InputDecoration(labelText: 'Descrição'), maxLines: 2),
            const SizedBox(height: 12),
            const Text('Tanques na Rota (ordem de coleta)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (tanques.isEmpty)
              const Text('Nenhum tanque ativo cadastrado', style: TextStyle(color: AppColors.textLight))
            else
              Wrap(
                spacing: 8,
                children: tanques.map((t) {
                  final sel = _tanqueIds.contains(t.id);
                  final idx = _tanqueIds.indexOf(t.id);
                  return FilterChip(
                    label: Text(sel ? '${idx + 1}. ${t.nome}' : t.nome),
                    selected: sel,
                    onSelected: (v) => setState(() {
                      if (v) { _tanqueIds.add(t.id); } else { _tanqueIds.remove(t.id); }
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _save,
              child: Text(widget.rota == null ? 'Cadastrar' : 'Salvar'),
            )),
          ]),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final r = Rota(
      id: widget.rota?.id ?? generateId(),
      nome: _nome.text.trim(),
      codigo: _codigo.text.trim(),
      carreiroId: _carreiroId,
      caminhaoId: _caminhaoId,
      tanqueIds: _tanqueIds,
      descricao: _descricao.text.trim(),
      dataCadastro: widget.rota?.dataCadastro ?? DateTime.now(),
    );
    if (widget.rota == null) { provider.addRota(r); } else { provider.updateRota(r); }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.rota == null ? 'Rota cadastrada!' : 'Rota atualizada!'),
      backgroundColor: AppColors.success,
    ));
  }
}
