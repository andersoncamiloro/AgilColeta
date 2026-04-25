import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import 'coleta/nova_coleta_screen.dart';
import 'coleta/historico_coletas_screen.dart';

class ColetaScreen extends StatelessWidget {
  const ColetaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final coletasHoje = provider.getColetasDeHoje();
      final totalHoje = provider.getTotalLitrosHoje();
      final produtoresHoje = coletasHoje.expand((c) => c.entregasProdutores).length;

      return Scaffold(
        appBar: AppBar(title: const Text('Coleta de Leite')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Banner principal de ação ────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NovaColetaScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(children: [
                  Icon(Icons.add_circle, color: Colors.white, size: 44),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nova Coleta',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Registrar coleta com GPS, temperatura,\nalizarol e entregas dos produtores',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // ── Cards de resumo do dia ──────────────────────────
            Row(children: [
              Expanded(
                child: _ResumoCard(
                  icon: Icons.water_drop,
                  label: 'Litros hoje',
                  value: formatLitros(totalHoje),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResumoCard(
                  icon: Icons.local_shipping,
                  label: 'Coletas hoje',
                  value: '${coletasHoje.length}',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ResumoCard(
                  icon: Icons.people,
                  label: 'Produtores',
                  value: '$produtoresHoje',
                  color: AppColors.info,
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Como funciona ────────────────────────────────────
            Card(
              color: AppColors.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Como funciona o lançamento',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 13),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    _PassoItem(
                      numero: '1',
                      texto: 'Inicie a rota na aba "Rotas" — motorista e caminhão são preenchidos automaticamente',
                    ),
                    _PassoItem(
                      numero: '2',
                      texto: 'Selecione o tanque — os produtores vinculados aparecem automaticamente',
                    ),
                    _PassoItem(
                      numero: '3',
                      texto: 'Informe as medições do tanque: litros, régua, temperatura e alizarol',
                    ),
                    _PassoItem(
                      numero: '4',
                      texto: 'Informe a quantidade entregue por cada produtor',
                    ),
                    _PassoItem(
                      numero: '5',
                      texto: 'Selecione a boca do caminhão e salve — GPS e data/hora são registrados automaticamente',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Atalho para histórico ────────────────────────────
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Ver Histórico Completo de Coletas'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(14),
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoricoColetasScreen()),
              ),
            ),

            const SizedBox(height: 16),

            // ── Coletas de Hoje ──────────────────────────────────
            if (coletasHoje.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Coletas de Hoje',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const HistoricoColetasScreen()),
                    ),
                    icon: const Icon(Icons.history, size: 14),
                    label: const Text('Ver todas', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...coletasHoje.map((coleta) {
                final tanque = provider.getTanqueById(coleta.tanqueId);
                final nProdutores = coleta.entregasProdutores.length;
                return _ColetaHojeCard(
                  key: ValueKey(coleta.id),
                  coleta: coleta,
                  tanqueNome: tanque?.nome ?? 'Tanque desconhecido',
                  nProdutores: nProdutores,
                  onEditar: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NovaColetaScreen(coletaParaEditar: coleta),
                    ),
                  ),
                  onExcluir: () => _confirmarExclusao(
                      context, provider, coleta, tanque?.nome ?? 'Coleta'),
                );
              }),
            ],

            const SizedBox(height: 80),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NovaColetaScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nova Coleta'),
          backgroundColor: AppColors.accent,
        ),
      );
    });
  }

  void _confirmarExclusao(
    BuildContext context,
    AppProvider provider,
    ColetaLeite coleta,
    String nomeColeta,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Coleta'),
        content: Text(
            'Deseja excluir a coleta do tanque "$nomeColeta"?\nEsta ação não pode ser desfeita.'),
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
                content: Text('Coleta excluída com sucesso'),
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
// CARD DE COLETA DO DIA (com editar + excluir)
// ============================================================
class _ColetaHojeCard extends StatelessWidget {
  final ColetaLeite coleta;
  final String tanqueNome;
  final int nProdutores;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _ColetaHojeCard({
    super.key,
    required this.coleta,
    required this.tanqueNome,
    required this.nProdutores,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(children: [
          // Ícone de status
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (coleta.coletaRealizada ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              coleta.coletaRealizada ? Icons.check_circle : Icons.cancel,
              color: coleta.coletaRealizada ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Informações da coleta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tanqueNome,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  coleta.coletaRealizada
                      ? '${formatLitros(coleta.quantidadeLitros)} · $nProdutores produtor(es) · ${formatTime(coleta.dataHoraColeta)}'
                      : 'Não coletado: ${coleta.motivoNaoColeta}',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textLight),
                  overflow: TextOverflow.ellipsis,
                ),
                if (coleta.coletaRealizada) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    _AlizarolBadge(coleta.alizarol),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Boca ${coleta.compartimentoCaminhao}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.info,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),

          // Botão editar
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onEditar,
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: AppColors.primary, size: 18),
            ),
          ),

          // Botão excluir
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onExcluir,
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 18),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────

class _ResumoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ResumoCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _PassoItem extends StatelessWidget {
  final String numero;
  final String texto;
  final bool isLast;
  const _PassoItem(
      {required this.numero, required this.texto, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: Center(
            child: Text(numero,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
        ),
      ]),
    );
  }
}

class _AlizarolBadge extends StatelessWidget {
  final ResultadoAlizarol alizarol;
  const _AlizarolBadge(this.alizarol);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (alizarol) {
      case ResultadoAlizarol.normal:
        color = AppColors.success;
        break;
      case ResultadoAlizarol.suspeito:
        color = AppColors.warning;
        break;
      default:
        color = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${alizarol.emoji} ${alizarol.label}',
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
