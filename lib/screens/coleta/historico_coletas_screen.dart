import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';
import 'nova_coleta_screen.dart';

// ============================================================
// HISTÓRICO DE COLETAS — exibe cada coleta com suas entregas
//                        por produtor (múltiplas datas)
// ============================================================

class HistoricoColetasScreen extends StatefulWidget {
  const HistoricoColetasScreen({super.key});

  @override
  State<HistoricoColetasScreen> createState() => _HistoricoColetasScreenState();
}

class _HistoricoColetasScreenState extends State<HistoricoColetasScreen> {
  String _rotaFiltro = '';
  String _tanqueFiltro = '';
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      var coletas = List<ColetaLeite>.from(provider.coletas);

      if (_rotaFiltro.isNotEmpty) {
        coletas = coletas.where((c) => c.rotaId == _rotaFiltro).toList();
      }
      if (_tanqueFiltro.isNotEmpty) {
        coletas = coletas.where((c) => c.tanqueId == _tanqueFiltro).toList();
      }
      if (_dataInicio != null) {
        coletas = coletas
            .where((c) =>
                c.dataHoraColeta.isAfter(_dataInicio!.subtract(const Duration(days: 1))))
            .toList();
      }
      if (_dataFim != null) {
        coletas = coletas
            .where(
                (c) => c.dataHoraColeta.isBefore(_dataFim!.add(const Duration(days: 1))))
            .toList();
      }
      coletas.sort((a, b) => b.dataHoraColeta.compareTo(a.dataHoraColeta));

      final totalLitros =
          coletas.where((c) => c.coletaRealizada).fold(0.0, (s, c) => s + c.quantidadeLitros);
      final totalEntregas = coletas.expand((c) => c.entregasProdutores).length;

      return Scaffold(
        appBar: AppBar(title: const Text('Histórico de Coletas')),
        body: Column(children: [
          // ── Filtros ───────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(children: [
              // Rota
              DropdownButtonFormField<String>(
                value: _rotaFiltro.isEmpty ? null : _rotaFiltro,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Rota',
                  isDense: true,
                  prefixIcon: Icon(Icons.route, color: AppColors.primary),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todas as rotas')),
                  ...provider.rotas.map((r) => DropdownMenuItem(value: r.id, child: Text(r.nome))),
                ],
                onChanged: (v) => setState(() => _rotaFiltro = v ?? ''),
              ),
              const SizedBox(height: 8),
              // Tanque
              DropdownButtonFormField<String>(
                value: _tanqueFiltro.isEmpty ? null : _tanqueFiltro,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Tanque',
                  isDense: true,
                  prefixIcon: Icon(Icons.storage, color: AppColors.accent),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos os tanques')),
                  ...provider.tanques
                      .where((t) => t.ativo)
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nome))),
                ],
                onChanged: (v) => setState(() => _tanqueFiltro = v ?? ''),
              ),
              const SizedBox(height: 8),
              // Datas
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                        _dataInicio != null ? formatDate(_dataInicio!) : 'Data Início',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: context,
                          initialDate: _dataInicio ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now());
                      if (d != null) setState(() => _dataInicio = d);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                        _dataFim != null ? formatDate(_dataFim!) : 'Data Fim',
                        style: const TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: context,
                          initialDate: _dataFim ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)));
                      if (d != null) setState(() => _dataFim = d);
                    },
                  ),
                ),
                if (_dataInicio != null ||
                    _dataFim != null ||
                    _rotaFiltro.isNotEmpty ||
                    _tanqueFiltro.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.error),
                    tooltip: 'Limpar filtros',
                    onPressed: () => setState(() {
                      _dataInicio = null;
                      _dataFim = null;
                      _rotaFiltro = '';
                      _tanqueFiltro = '';
                    }),
                  ),
              ]),
            ]),
          ),

          // ── Barra de totais ───────────────────────────────────
          if (coletas.isNotEmpty)
            Container(
              color: AppColors.primary.withValues(alpha: 0.07),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${coletas.length} coleta(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Row(children: [
                    const Icon(Icons.people, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text('$totalEntregas entrega(s)',
                        style:
                            const TextStyle(fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(width: 12),
                    Text(formatLitros(totalLitros),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ]),
                ],
              ),
            ),

          // ── Lista ─────────────────────────────────────────────
          Expanded(
            child: coletas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop_outlined,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Nenhuma coleta encontrada',
                            style: TextStyle(color: AppColors.textLight)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: coletas.length,
                    itemBuilder: (ctx, i) =>
                        _ColetaCard(coleta: coletas[i], provider: provider),
                  ),
          ),
        ]),
      );
    });
  }
}

// ============================================================
// CARD DE COLETA NO HISTÓRICO
// ============================================================
class _ColetaCard extends StatelessWidget {
  final ColetaLeite coleta;
  final AppProvider provider;
  const _ColetaCard({required this.coleta, required this.provider});

  @override
  Widget build(BuildContext context) {
    final tanque = provider.getTanqueById(coleta.tanqueId);
    final rota = provider.getRotaById(coleta.rotaId);
    final carreteiro = provider.getCarreiroById(coleta.carreiroId);
    final caminhao = provider.getCaminhaoById(coleta.caminhaoId);

    Color alizarolColor;
    switch (coleta.alizarol) {
      case ResultadoAlizarol.normal:
        alizarolColor = AppColors.success;
        break;
      case ResultadoAlizarol.suspeito:
        alizarolColor = AppColors.warning;
        break;
      default:
        alizarolColor = AppColors.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (coleta.coletaRealizada ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            coleta.coletaRealizada ? Icons.check_circle : Icons.cancel,
            color: coleta.coletaRealizada ? AppColors.success : AppColors.error,
            size: 22,
          ),
        ),
        title: Text(
          tanque?.nome ?? 'Tanque desconhecido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            coleta.coletaRealizada
                ? '${formatLitros(coleta.quantidadeLitros)} • ${formatDateTime(coleta.dataHoraColeta)}'
                : 'Não coletado • ${formatDate(coleta.dataHoraColeta)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (rota != null)
            Text(
              'Rota: ${rota.nome}',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
        ]),
        trailing: coleta.coletaRealizada
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: alizarolColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${coleta.alizarol.emoji} ${coleta.alizarol.label}',
                  style: TextStyle(
                      color: alizarolColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10),
                ),
              )
            : null,

        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Dados gerais ───────────────────────────────────
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (carreteiro != null)
                  _InfoChip(Icons.badge, carreteiro.nome),
                if (caminhao != null)
                  _InfoChip(Icons.local_shipping,
                      '${caminhao.placa} • Boca ${coleta.compartimentoCaminhao}'),
                if (coleta.latitude != null)
                  _InfoChip(Icons.gps_fixed,
                      formatLatLng(coleta.latitude, coleta.longitude)),
                _InfoChip(Icons.access_time, formatDateTime(coleta.dataHoraColeta)),
              ]),

              if (coleta.coletaRealizada) ...[
                const SizedBox(height: 12),

                // ── Medições em destaque ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MedicaoItem(
                        icon: Icons.water_drop,
                        label: 'Total',
                        value: formatLitros(coleta.quantidadeLitros),
                        color: AppColors.primary,
                      ),
                      _MedicaoItem(
                        icon: Icons.straighten,
                        label: 'Régua',
                        value: '${coleta.valorRegua}',
                        color: AppColors.accent,
                      ),
                      _MedicaoItem(
                        icon: Icons.thermostat,
                        label: 'Temp.',
                        value: formatTemp(coleta.temperatura),
                        color: AppColors.info,
                      ),
                      _MedicaoItem(
                        icon: Icons.science,
                        label: 'Alizarol',
                        value: coleta.alizarol.label,
                        color: alizarolColor,
                      ),
                    ],
                  ),
                ),

                // ── Observações de qualidade ───────────────────────
                if (coleta.observacoesQualidade.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.rate_review, color: AppColors.warning, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          coleta.observacoesQualidade,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ]),
                  ),
                ],

                // ── Entregas dos produtores ────────────────────────
                const SizedBox(height: 14),
                _EntregasProdutoresHistorico(
                  coleta: coleta,
                  provider: provider,
                ),
              ] else ...[
                // Não coletado
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber, color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Motivo: ${coleta.motivoNaoColeta}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              ],

              // Botão editar
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar Coleta'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NovaColetaScreen(coletaParaEditar: coleta),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                    label: const Text('Excluir', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Coleta'),
        content: const Text('Deseja excluir esta coleta? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteColeta(coleta.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Coleta excluída'),
                backgroundColor: AppColors.error,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SEÇÃO DE ENTREGAS DOS PRODUTORES NO HISTÓRICO
// Agrupa por produtor e lista todas as datas de entrega
// ============================================================
class _EntregasProdutoresHistorico extends StatelessWidget {
  final ColetaLeite coleta;
  final AppProvider provider;

  const _EntregasProdutoresHistorico({required this.coleta, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (coleta.entregasProdutores.isEmpty) {
      return const Row(children: [
        Icon(Icons.people_outline, size: 14, color: AppColors.textLight),
        SizedBox(width: 6),
        Text('Nenhuma entrega individual registrada',
            style: TextStyle(fontSize: 12, color: AppColors.textLight)),
      ]);
    }

    // Agrupar entregas por produtor
    final Map<String, List<EntregaProdutor>> porProdutor = {};
    for (final ep in coleta.entregasProdutores) {
      porProdutor.putIfAbsent(ep.produtorId, () => []).add(ep);
    }

    final totalEntregas = coleta.entregasProdutores.fold(0.0, (s, e) => s + e.quantidadeLitros);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Cabeçalho da seção
      Row(children: [
        const Icon(Icons.people, color: AppColors.accent, size: 16),
        const SizedBox(width: 6),
        Text(
          'Entregas por Produtor (${porProdutor.length} produtor(es), ${coleta.entregasProdutores.length} lançamento(s))',
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
        ),
        const Spacer(),
        Text(
          formatLitros(totalEntregas),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.accent, fontSize: 13),
        ),
      ]),

      const SizedBox(height: 8),

      // Lista de produtores com suas entregas
      ...porProdutor.entries.map((entry) {
        final prod = provider.getProdutorById(entry.key);
        final entregas = entry.value;
        final totalProdutor = entregas.fold(0.0, (s, e) => s + e.quantidadeLitros);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(children: [
            // Cabeçalho do produtor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    prod != null && prod.nome.isNotEmpty ? prod.nome[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      prod?.nome ?? 'Produtor desconhecido',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (prod != null && prod.codigo.isNotEmpty)
                      Text('Cód: ${prod.codigo}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatLitros(totalProdutor),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ]),
            ),

            // Linhas de entrega (cada data)
            if (entregas.length == 1) ...[
              // Se só tem uma entrega, exibe na mesma linha
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(children: [
                  const Icon(Icons.calendar_today, size: 13, color: AppColors.textLight),
                  const SizedBox(width: 6),
                  Text(
                    formatDate(entregas[0].dataEntrega),
                    style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                  ),
                  if (entregas[0].observacao.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: AppColors.textLight)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entregas[0].observacao,
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ]),
              ),
            ] else ...[
              // Múltiplas entregas: exibe cada uma
              const Divider(height: 1, indent: 12, endIndent: 12),
              ...entregas.asMap().entries.map((e) {
                final idx = e.key;
                final ep = e.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: idx % 2 == 0 ? Colors.transparent : Colors.grey.shade50,
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${idx + 1}ª',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_today, size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(ep.dataEntrega),
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                    ),
                    if (ep.observacao.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          ep.observacao,
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else
                      const Spacer(),
                    Text(
                      formatLitros(ep.quantidadeLitros),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ]),
                );
              }),
              const SizedBox(height: 4),
            ],
          ]),
        );
      }),
    ]);
  }
}

// ── Widgets auxiliares ────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      );
}

class _MedicaoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MedicaoItem(
      {required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
      ]);
}
