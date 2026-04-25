import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class EntregasProdutorScreen extends StatefulWidget {
  const EntregasProdutorScreen({super.key});
  @override
  State<EntregasProdutorScreen> createState() => _EntregasProdutorScreenState();
}

class _EntregasProdutorScreenState extends State<EntregasProdutorScreen> {
  String _tanqueId = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final tanques = provider.tanques.where((t) => t.ativo).toList();
      final entregas = _tanqueId.isEmpty
          ? provider.entregas
          : provider.getEntregasDeTanque(_tanqueId);

      // Agrupar por produtor
      final Map<String, List<EntregaProdutor>> porProdutor = {};
      for (final e in entregas) {
        porProdutor.putIfAbsent(e.produtorId, () => []).add(e);
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Entregas por Produtor'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _openForm(context, null),
            ),
          ],
        ),
        body: Column(
          children: [
            // Filtro por Tanque
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                value: _tanqueId.isEmpty ? null : _tanqueId,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Tanque',
                  prefixIcon: Icon(Icons.storage, color: AppColors.primary),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos os tanques')),
                  ...tanques.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome))),
                ],
                onChanged: (v) => setState(() => _tanqueId = v ?? ''),
              ),
            ),

            // Resumo Total
            if (_tanqueId.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.water_drop, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Total no tanque: ${formatLitros(entregas.fold(0.0, (s, e) => s + e.quantidadeLitros))}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],

            Expanded(
              child: porProdutor.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: AppColors.textLight),
                          SizedBox(height: 12),
                          Text('Nenhuma entrega registrada', style: TextStyle(color: AppColors.textLight)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: porProdutor.keys.length,
                      itemBuilder: (ctx, i) {
                        final produtorId = porProdutor.keys.elementAt(i);
                        final produtor = provider.getProdutorById(produtorId);
                        final entregasProdutor = porProdutor[produtorId]!;
                        final totalProdutor = entregasProdutor.fold(0.0, (s, e) => s + e.quantidadeLitros);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                produtor != null && produtor.nome.isNotEmpty
                                    ? produtor.nome[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              produtor?.nome ?? 'Produtor não encontrado',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${entregasProdutor.length} entrega(s) • ${formatLitros(totalProdutor)}',
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                formatLitros(totalProdutor),
                                style: const TextStyle(
                                  color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12,
                                ),
                              ),
                            ),
                            children: [
                              ...entregasProdutor.map((e) {
                                final tanque = provider.getTanqueById(e.tanqueId);
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                                  leading: const Icon(Icons.calendar_today, size: 18, color: AppColors.textLight),
                                  title: Text(formatDate(e.dataEntrega)),
                                  subtitle: e.observacao.isNotEmpty ? Text(e.observacao, style: const TextStyle(fontSize: 12)) : null,
                                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      Text(formatLitros(e.quantidadeLitros),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      Text(tanque?.nome ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                                    ]),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                                      onPressed: () => _openForm(context, e),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18, color: AppColors.error),
                                      onPressed: () => _confirmDelete(context, provider, e),
                                    ),
                                  ]),
                                );
                              }),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: Text('Adicionar entrega para ${produtor?.nome ?? ""}'),
                                  onPressed: () => _openForm(context, null, produtorIdInicial: produtorId),
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
          label: const Text('Nova Entrega'),
        ),
      );
    });
  }

  void _openForm(BuildContext context, EntregaProdutor? entrega, {String? produtorIdInicial}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EntregaForm(
        entrega: entrega,
        produtorIdInicial: produtorIdInicial ?? (entrega?.produtorId ?? ''),
        tanqueIdInicial: _tanqueId.isNotEmpty ? _tanqueId : (entrega?.tanqueId ?? ''),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, EntregaProdutor e) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Entrega'),
        content: Text('Excluir entrega de ${formatLitros(e.quantidadeLitros)} em ${formatDate(e.dataEntrega)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () { provider.deleteEntrega(e.id); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

class EntregaForm extends StatefulWidget {
  final EntregaProdutor? entrega;
  final String produtorIdInicial;
  final String tanqueIdInicial;
  const EntregaForm({super.key, this.entrega, this.produtorIdInicial = '', this.tanqueIdInicial = ''});
  @override
  State<EntregaForm> createState() => _EntregaFormState();
}

class _EntregaFormState extends State<EntregaForm> {
  final _formKey = GlobalKey<FormState>();
  String _produtorId = '';
  String _tanqueId = '';
  DateTime _dataEntrega = DateTime.now();
  final _litrosCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final e = widget.entrega;
    _produtorId = e?.produtorId ?? widget.produtorIdInicial;
    _tanqueId = e?.tanqueId ?? widget.tanqueIdInicial;
    _dataEntrega = e?.dataEntrega ?? DateTime.now();
    _litrosCtrl.text = e != null ? e.quantidadeLitros.toStringAsFixed(1) : '';
    _obsCtrl.text = e?.observacao ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final produtores = provider.produtores.where((p) => p.ativo).toList();
    final tanques = provider.tanques.where((t) => t.ativo).toList();

    // Filtrar produtores do tanque selecionado
    final produtoresDoTanque = _tanqueId.isNotEmpty
        ? provider.getProdutoresDeTanque(_tanqueId)
        : produtores;

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
              Text(widget.entrega == null ? 'Nova Entrega' : 'Editar Entrega',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const Divider(),
            const SizedBox(height: 8),

            // Seleção de Tanque
            DropdownButtonFormField<String>(
              value: _tanqueId.isEmpty ? null : _tanqueId,
              decoration: const InputDecoration(labelText: 'Tanque*'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Selecione o tanque...')),
                ...tanques.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome))),
              ],
              onChanged: (v) => setState(() { _tanqueId = v ?? ''; _produtorId = ''; }),
              validator: (v) => (v == null || v.isEmpty) ? 'Selecione um tanque' : null,
            ),
            const SizedBox(height: 12),

            // Seleção de Produtor
            DropdownButtonFormField<String>(
              value: _produtorId.isEmpty ? null : _produtorId,
              decoration: const InputDecoration(labelText: 'Produtor*'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Selecione o produtor...')),
                ...produtoresDoTanque.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.nome} (Cód: ${p.codigo})'),
                    )),
              ],
              onChanged: (v) => setState(() => _produtorId = v ?? ''),
              validator: (v) => (v == null || v.isEmpty) ? 'Selecione um produtor' : null,
            ),
            const SizedBox(height: 12),

            // Data de Entrega
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: Text('Data de Entrega: ${formatDate(_dataEntrega)}'),
              trailing: const Icon(Icons.edit, color: AppColors.primary),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _dataEntrega,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (d != null) setState(() => _dataEntrega = d);
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _litrosCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantidade (Litros)*',
                prefixIcon: Icon(Icons.water_drop, color: AppColors.primary),
                suffixText: 'L',
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Informe a quantidade' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _obsCtrl,
              decoration: const InputDecoration(labelText: 'Observação'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _save,
              child: Text(widget.entrega == null ? 'Registrar Entrega' : 'Salvar'),
            )),
          ]),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final e = EntregaProdutor(
      id: widget.entrega?.id ?? generateId(),
      produtorId: _produtorId,
      tanqueId: _tanqueId,
      dataEntrega: _dataEntrega,
      quantidadeLitros: double.tryParse(_litrosCtrl.text) ?? 0,
      observacao: _obsCtrl.text.trim(),
    );
    if (widget.entrega == null) { provider.addEntrega(e); } else { provider.updateEntrega(e); }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(widget.entrega == null ? 'Entrega registrada!' : 'Entrega atualizada!'),
      backgroundColor: AppColors.success,
    ));
  }
}
