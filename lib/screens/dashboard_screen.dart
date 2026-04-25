import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class DashboardScreen extends StatelessWidget {
  /// Callback para mudar a aba selecionada no HomeScreen.
  /// Índices: 0=Dashboard, 1=Rotas, 2=Coleta, 3=Cadastros, 4=Exportar
  final void Function(int index) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final stats = provider.getEstatisticas();
        final coletasHoje = provider.getColetasDeHoje();
        final rotasHoje = provider.getRotasDiaHoje();

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: AppColors.headerGradient,
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.water_drop,
                                        color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Agil Coleta',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Gestão de Coleta de Leite',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                formatDate(DateTime.now()),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${formatLitros(stats['totalLitrosHoje'])} coletados hoje',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Cards de Estatísticas
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _StatCard(
                            title: 'Coletas Hoje',
                            value: '${stats['coletasHoje']}',
                            icon: Icons.local_shipping,
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            title: 'Total do Mês',
                            value: formatLitros(stats['totalLitrosMes']),
                            icon: Icons.water_drop,
                            color: AppColors.accent,
                          ),
                          _StatCard(
                            title: 'Produtores',
                            value: '${stats['totalProdutores']}',
                            icon: Icons.person,
                            color: AppColors.info,
                          ),
                          _StatCard(
                            title: 'Tanques',
                            value: '${stats['totalTanques']}',
                            icon: Icons.storage,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Ações Rápidas
                      const Text(
                        'Ações Rápidas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Nova Coleta',
                              icon: Icons.add_circle,
                              gradient: AppColors.accentGradient,
                              onTap: () => _navegarParaColeta(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _QuickActionButton(
                              label: 'Rota do Dia',
                              icon: Icons.route,
                              gradient: AppColors.primaryGradient,
                              onTap: () => _navegarParaRotaDia(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Coletas de Hoje
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Coletas de Hoje',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${coletasHoje.length} registros',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (coletasHoje.isEmpty)
                        _EmptyCard(
                          icon: Icons.water_drop_outlined,
                          message: 'Nenhuma coleta registrada hoje',
                        )
                      else
                        ...coletasHoje.take(5).map((coleta) {
                          final tanque =
                              provider.getTanqueById(coleta.tanqueId);
                          return _ColetaCard(
                            coleta: coleta,
                            tanqueNome: tanque?.nome ?? 'Tanque não encontrado',
                          );
                        }),

                      const SizedBox(height: 20),

                      // Rotas do Dia
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rotas do Dia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '${rotasHoje.length} rotas',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (rotasHoje.isEmpty)
                        _EmptyCard(
                          icon: Icons.route,
                          message:
                              'Nenhuma rota programada para hoje\nUse "Rota do Dia" para receber dados',
                        )
                      else
                        ...rotasHoje.map((rota) => _RotaDiaCard(rota: rota)),

                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navegarParaColeta(BuildContext context) {
    onNavigate(2); // índice 2 = aba Coleta
  }

  void _navegarParaRotaDia(BuildContext context) {
    onNavigate(1); // índice 1 = aba Rotas
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColetaCard extends StatelessWidget {
  final dynamic coleta;
  final String tanqueNome;

  const _ColetaCard({required this.coleta, required this.tanqueNome});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: coleta.coletaRealizada
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            coleta.coletaRealizada ? Icons.check_circle : Icons.cancel,
            color:
                coleta.coletaRealizada ? AppColors.success : AppColors.error,
          ),
        ),
        title: Text(
          tanqueNome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          coleta.coletaRealizada
              ? '${formatLitros(coleta.quantidadeLitros)} • ${formatTime(coleta.dataHoraColeta)}'
              : 'Não coletado: ${coleta.motivoNaoColeta}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: coleta.coletaRealizada
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAlizarolColor(coleta.alizarol)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  coleta.alizarol.label,
                  style: TextStyle(
                    color: _getAlizarolColor(coleta.alizarol),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Color _getAlizarolColor(dynamic alizarol) {
    switch (alizarol.name) {
      case 'normal':
        return AppColors.success;
      case 'suspeito':
        return AppColors.warning;
      default:
        return AppColors.error;
    }
  }
}

class _RotaDiaCard extends StatelessWidget {
  final dynamic rota;
  const _RotaDiaCard({required this.rota});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    switch (rota.status) {
      case 'em_andamento':
        statusColor = AppColors.warning;
        statusLabel = 'Em andamento';
        break;
      case 'concluida':
        statusColor = AppColors.success;
        statusLabel = 'Concluída';
        break;
      default:
        statusColor = AppColors.info;
        statusLabel = 'Pendente';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.route, color: AppColors.primary),
        ),
        title: Text(rota.nomeRota,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${rota.tanques.length} tanques programados'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textLight),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
