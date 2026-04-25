import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class RotaDiaScreen extends StatefulWidget {
  const RotaDiaScreen({super.key});
  @override
  State<RotaDiaScreen> createState() => _RotaDiaScreenState();
}

class _RotaDiaScreenState extends State<RotaDiaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota do Dia'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Hoje'),
            Tab(icon: Icon(Icons.download), text: 'Receber Dados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RotasHojeTab(),
          _ReceberDadosTab(),
        ],
      ),
    );
  }
}

// ---- Aba: Rotas de Hoje ----
class _RotasHojeTab extends StatelessWidget {
  const _RotasHojeTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final rotasHoje = provider.getRotasDiaHoje();

      return rotasHoje.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.route, size: 72, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  const Text('Nenhuma rota para hoje',
                      style: TextStyle(fontSize: 18, color: AppColors.textLight)),
                  const SizedBox(height: 8),
                  const Text('Use a aba "Receber Dados" para importar\na rota do dia do servidor ERP',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Rota Manual'),
                    onPressed: () => _criarRotaManual(context, provider),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rotasHoje.length,
              itemBuilder: (ctx, i) {
                final rota = rotasHoje[i];
                return _RotaDiaCard(rota: rota, provider: provider);
              },
            );
    });
  }

  void _criarRotaManual(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RotaDiaForm(),
    );
  }
}

class _RotaDiaCard extends StatelessWidget {
  final RotaDia rota;
  final AppProvider provider;
  const _RotaDiaCard({required this.rota, required this.provider});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (rota.status) {
      case 'em_andamento':
        statusColor = AppColors.warning;
        statusLabel = 'Em andamento';
        statusIcon = Icons.directions_car;
        break;
      case 'concluida':
        statusColor = AppColors.success;
        statusLabel = 'Concluída';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = AppColors.info;
        statusLabel = 'Pendente';
        statusIcon = Icons.schedule;
    }

    final carreteiro = provider.getCarreiroById(rota.carreiroId);
    final caminhao = provider.getCaminhaoById(rota.caminhaoId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.route, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(rota.nomeRota,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(statusIcon, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (carreteiro != null)
                  _InfoRow(Icons.person, 'Carreteiro: ${carreteiro.nome}'),
                if (caminhao != null)
                  _InfoRow(Icons.local_shipping, 'Caminhão: ${caminhao.placa} (${caminhao.totalCompartimentos} comp.)'),
                _InfoRow(Icons.calendar_today, 'Data: ${formatDate(rota.data)}'),
                const Divider(),
                const Text('Tanques na Rota:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...rota.tanques.asMap().entries.map((entry) {
                  final tanqueRota = entry.value;
                  final tanque = provider.getTanqueById(tanqueRota.tanqueId);
                  final produtores = tanqueRota.produtorIds
                      .map((id) => provider.getProdutorById(id))
                      .whereType<Produtor>()
                      .toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 24, height: 24,
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: Center(child: Text('${tanqueRota.ordem}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          tanque?.nome ?? tanqueRota.nomeTanque,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tanque?.tipo == TipoTanque.individual ? 'Individual' : 'Coletivo',
                            style: const TextStyle(fontSize: 10, color: AppColors.primary),
                          ),
                        ),
                      ]),
                      if (produtores.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          children: produtores.map((p) => Chip(
                            label: Text(p.nome, style: const TextStyle(fontSize: 10)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.all(0),
                            visualDensity: VisualDensity.compact,
                          )).toList(),
                        ),
                      ],
                    ]),
                  );
                }),
                const SizedBox(height: 8),
                // Botões de Ação
                if (rota.status == 'pendente')
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Rota'),
                      onPressed: () => _atualizarStatus(context, provider, rota, 'em_andamento'),
                    )),
                  ])
                else if (rota.status == 'em_andamento')
                  Row(children: [
                    Expanded(child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Concluir Rota'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () => _atualizarStatus(context, provider, rota, 'concluida'),
                    )),
                  ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _atualizarStatus(BuildContext context, AppProvider provider, RotaDia rota, String novoStatus) {
    final novaRota = RotaDia(
      id: rota.id,
      rotaId: rota.rotaId,
      nomeRota: rota.nomeRota,
      data: rota.data,
      carreiroId: rota.carreiroId,
      caminhaoId: rota.caminhaoId,
      tanques: rota.tanques,
      status: novoStatus,
      dataCriacao: rota.dataCriacao,
    );
    provider.addRotaDia(novaRota);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(novoStatus == 'em_andamento' ? 'Rota iniciada!' : 'Rota concluída!'),
      backgroundColor: novoStatus == 'concluida' ? AppColors.success : AppColors.warning,
    ));
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
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
    ]),
  );
}

// ---- Aba: Receber Dados ----
class _ReceberDadosTab extends StatefulWidget {
  const _ReceberDadosTab();
  @override
  State<_ReceberDadosTab> createState() => _ReceberDadosTabState();
}

class _ReceberDadosTabState extends State<_ReceberDadosTab> {
  final _urlCtrl = TextEditingController(text: 'https://erp.suaempresa.com.br/api/coleta/rota-do-dia');
  bool _loading = false;
  String _statusMsg = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Receber Dados do ERP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 8),
        const Text('Configure o endpoint do servidor ERP para receber os dados da rota, tanques e produtores do dia.',
            style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Configuração do Servidor', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL do Servidor ERP',
                  prefixIcon: Icon(Icons.link, color: AppColors.primary),
                  hintText: 'https://erp.empresa.com.br/api/coleta/rota',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download),
                  label: Text(_loading ? 'Recebendo...' : 'Receber Dados da Rota'),
                  onPressed: _loading ? null : () => _receberDados(context),
                ),
              ),
              if (_statusMsg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusMsg.startsWith('✅')
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statusMsg,
                      style: TextStyle(
                        color: _statusMsg.startsWith('✅') ? AppColors.success : AppColors.error,
                      )),
                ),
              ],
            ]),
          ),
        ),

        const SizedBox(height: 20),

        // Formato esperado
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.code, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Formato JSON Esperado', style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '{\n'
                  '  "id": "rota_001",\n'
                  '  "rotaId": "uuid-da-rota",\n'
                  '  "nomeRota": "Rota Norte",\n'
                  '  "data": "2024-01-15T00:00:00.000Z",\n'
                  '  "carreiroId": "uuid-carreteiro",\n'
                  '  "caminhaoId": "uuid-caminhao",\n'
                  '  "tanques": [\n'
                  '    {\n'
                  '      "tanqueId": "uuid-tanque",\n'
                  '      "nomeTanque": "Tanque Família Silva",\n'
                  '      "ordem": 1,\n'
                  '      "produtorIds": ["p1", "p2"]\n'
                  '    }\n'
                  '  ],\n'
                  '  "status": "pendente"\n'
                  '}',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 20),

        // Criar manualmente
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Criar Rota Manual', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Crie manualmente a rota do dia sem depender do servidor ERP.',
                  style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Criar Rota do Dia Manualmente'),
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _RotaDiaForm(),
                ),
              )),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _receberDados(BuildContext context) async {
    setState(() { _loading = true; _statusMsg = ''; });
    // Simulação de recebimento (em produção, usar http package)
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _loading = false;
      _statusMsg = '❌ Não foi possível conectar ao servidor. Verifique a URL e tente novamente.\n\nDica: O servidor ERP deve expor um endpoint REST que retorne os dados da rota no formato JSON esperado.';
    });
  }
}

// ---- Form Criação Manual de Rota do Dia ----
class _RotaDiaForm extends StatefulWidget {
  const _RotaDiaForm();
  @override
  State<_RotaDiaForm> createState() => _RotaDiaFormState();
}

class _RotaDiaFormState extends State<_RotaDiaForm> {
  String _rotaId = '';
  DateTime _data = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final rotas = provider.rotas.where((r) => r.ativo).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Criar Rota do Dia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
        const Divider(),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _rotaId.isEmpty ? null : _rotaId,
          decoration: const InputDecoration(labelText: 'Rota*'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Selecione a rota...')),
            ...rotas.map((r) => DropdownMenuItem(value: r.id, child: Text(r.nome))),
          ],
          onChanged: (v) => setState(() => _rotaId = v ?? ''),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today, color: AppColors.primary),
          title: Text('Data: ${formatDate(_data)}'),
          trailing: const Icon(Icons.edit, color: AppColors.primary),
          onTap: () async {
            final d = await showDatePicker(context: context,
              initialDate: _data, firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 30)));
            if (d != null) setState(() => _data = d);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _rotaId.isEmpty ? null : () => _criar(context, provider),
          child: const Text('Criar Rota do Dia'),
        )),
      ]),
    );
  }

  void _criar(BuildContext context, AppProvider provider) {
    final rota = provider.getRotaById(_rotaId);
    if (rota == null) return;

    final tanques = rota.tanqueIds.asMap().entries.map((e) {
      final tanque = provider.getTanqueById(e.value);
      return TanqueRota(
        tanqueId: e.value,
        nomeTanque: tanque?.nome ?? '',
        ordem: e.key + 1,
        produtorIds: tanque?.produtorIds ?? [],
      );
    }).toList();

    final rotaDia = RotaDia(
      id: generateId(),
      rotaId: rota.id,
      nomeRota: rota.nome,
      data: _data,
      carreiroId: rota.carreiroId,
      caminhaoId: rota.caminhaoId,
      tanques: tanques,
      status: 'pendente',
      dataCriacao: DateTime.now(),
    );
    provider.addRotaDia(rotaDia);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rota do dia criada!'), backgroundColor: AppColors.success),
    );
  }
}
