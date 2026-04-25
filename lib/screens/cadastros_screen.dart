import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/seed_service.dart';
import '../utils/app_theme.dart';
import 'cadastros/produtores_screen.dart';
import 'cadastros/tanques_screen.dart';
import 'cadastros/caminhoes_screen.dart';
import 'cadastros/carreteiros_screen.dart';
import 'cadastros/rotas_screen.dart';

class CadastrosScreen extends StatelessWidget {
  const CadastrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itens = [
      _CadastroItem(
        titulo: 'Produtores',
        descricao: 'Cadastrar e gerenciar produtores rurais',
        icon: Icons.person,
        color: AppColors.primary,
        screen: const ProdutoresScreen(),
      ),
      _CadastroItem(
        titulo: 'Tanques',
        descricao: 'Tanques individuais e coletivos',
        icon: Icons.storage,
        color: AppColors.accent,
        screen: const TanquesScreen(),
      ),
      _CadastroItem(
        titulo: 'Caminhões',
        descricao: 'Caminhões com 3 ou 4 compartimentos',
        icon: Icons.local_shipping,
        color: AppColors.info,
        screen: const CaminhoesScreen(),
      ),
      _CadastroItem(
        titulo: 'Carreteiros',
        descricao: 'Motoristas e coletores de leite',
        icon: Icons.badge,
        color: AppColors.success,
        screen: const CarreteirosScreen(),
      ),
      _CadastroItem(
        titulo: 'Rotas de Coleta',
        descricao: 'Configurar rotas e sequência de tanques',
        icon: Icons.route,
        color: const Color(0xFF7B1FA2),
        screen: const RotasScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restaurar dados de demonstração',
            onPressed: () => _confirmarRestauracao(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Banner informativo dos dados demo ─────────────────
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Dados de demonstração já carregados:\n'
                    '2 carreteiros · 2 caminhões · 10 produtores · 5 tanques · 2 rotas',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista de módulos de cadastro ──────────────────────
          ...List.generate(itens.length, (i) {
            final item = itens[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item.screen),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(item.icon, color: item.color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.titulo,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Text(item.descricao,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textLight)),
                        ],
                      )),
                      Icon(Icons.chevron_right, color: item.color),
                    ]),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // ── Botão restaurar dados demo ────────────────────────
          OutlinedButton.icon(
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Restaurar dados de demonstração'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textLight,
              side: BorderSide(
                  color: AppColors.textLight.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _confirmarRestauracao(context),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _confirmarRestauracao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar dados demo?'),
        content: const Text(
          'Isso vai adicionar de volta os dados de demonstração '
          '(produtores, tanques, rotas etc.) sem apagar os seus registros atuais.\n\n'
          'Caso os dados demo já existam, serão ignorados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await SeedService.reset();
      if (context.mounted) {
        await context.read<AppProvider>().loadAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados de demonstração restaurados com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

class _CadastroItem {
  final String titulo;
  final String descricao;
  final IconData icon;
  final Color color;
  final Widget screen;
  const _CadastroItem(
      {required this.titulo,
      required this.descricao,
      required this.icon,
      required this.color,
      required this.screen});
}
