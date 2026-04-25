import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

class CaminhoesScreen extends StatelessWidget {
  const CaminhoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final lista = provider.caminhoes;
      return Scaffold(
        appBar: AppBar(title: const Text('Caminhões')),
        body: lista.isEmpty
            ? const Center(
                child: Text('Nenhum caminhão cadastrado',
                    style: TextStyle(color: AppColors.textLight)))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: lista.length,
                itemBuilder: (ctx, i) {
                  final c = lista[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.local_shipping,
                            color: AppColors.primary),
                      ),
                      title: Text(c.placa,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${c.marca} ${c.modelo} • ${c.totalCompartimentos} compartimentos'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: AppColors.primary),
                            onPressed: () => _openForm(context, c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: AppColors.error),
                            onPressed: () =>
                                _confirmDelete(context, provider, c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(context, null),
          icon: const Icon(Icons.add),
          label: const Text('Novo Caminhão'),
        ),
      );
    });
  }

  void _openForm(BuildContext context, Caminhao? c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CaminhaoForm(caminhao: c),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, Caminhao c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Caminhão'),
        content: Text('Deseja excluir o caminhão ${c.placa}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              provider.deleteCaminhao(c.id);
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

class CaminhaoForm extends StatefulWidget {
  final Caminhao? caminhao;
  const CaminhaoForm({super.key, this.caminhao});
  @override
  State<CaminhaoForm> createState() => _CaminhaoFormState();
}

class _CaminhaoFormState extends State<CaminhaoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _placa, _modelo, _marca;
  NumeroCompartimentos _compartimentos = NumeroCompartimentos.tres;
  List<TextEditingController> _capacidades = [];

  @override
  void initState() {
    super.initState();
    final c = widget.caminhao;
    _placa = TextEditingController(text: c?.placa ?? '');
    _modelo = TextEditingController(text: c?.modelo ?? '');
    _marca = TextEditingController(text: c?.marca ?? '');
    _compartimentos = c?.compartimentos ?? NumeroCompartimentos.tres;
    _initCapacidades();
  }

  void _initCapacidades() {
    final n = _compartimentos == NumeroCompartimentos.tres ? 3 : 4;
    _capacidades = List.generate(n, (i) {
      final cap = widget.caminhao?.capacidadeCompartimentos;
      return TextEditingController(
          text: (cap != null && i < cap.length)
              ? cap[i].toStringAsFixed(0)
              : '');
    });
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
                      widget.caminhao == null
                          ? 'Novo Caminhão'
                          : 'Editar Caminhão',
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
              _field('Placa*', _placa, required: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field('Marca', _marca)),
                const SizedBox(width: 12),
                Expanded(child: _field('Modelo', _modelo)),
              ]),
              const SizedBox(height: 12),
              const Text('Número de Compartimentos',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Row(children: [
                Expanded(
                  child: RadioListTile<NumeroCompartimentos>(
                    title: const Text('3 compartimentos'),
                    value: NumeroCompartimentos.tres,
                    groupValue: _compartimentos,
                    onChanged: (v) {
                      setState(() {
                        _compartimentos = v!;
                        _initCapacidades();
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<NumeroCompartimentos>(
                    title: const Text('4 compartimentos'),
                    value: NumeroCompartimentos.quatro,
                    groupValue: _compartimentos,
                    onChanged: (v) {
                      setState(() {
                        _compartimentos = v!;
                        _initCapacidades();
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              const Text('Capacidade por Compartimento (L)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              ...List.generate(_capacidades.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: _capacidades[i],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Compartimento ${i + 1} (L)',
                    prefixIcon: Icon(Icons.storage,
                        color: AppColors.primary.withValues(alpha: 0.7)),
                  ),
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(
                      widget.caminhao == null ? 'Cadastrar' : 'Salvar'),
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
    final caps = _capacidades
        .map((c) => double.tryParse(c.text) ?? 0)
        .toList();
    final cam = Caminhao(
      id: widget.caminhao?.id ?? generateId(),
      placa: _placa.text.trim().toUpperCase(),
      modelo: _modelo.text.trim(),
      marca: _marca.text.trim(),
      compartimentos: _compartimentos,
      capacidadeCompartimentos: caps,
      dataCadastro: widget.caminhao?.dataCadastro ?? DateTime.now(),
    );
    if (widget.caminhao == null) {
      provider.addCaminhao(cam);
    } else {
      provider.updateCaminhao(cam);
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.caminhao == null
            ? 'Caminhão cadastrado!'
            : 'Caminhão atualizado!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
