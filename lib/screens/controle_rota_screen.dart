// ============================================================
// CONTROLE DE ROTA — Iniciar e finalizar rotas de coleta
// Vincula Rota + Motorista + Caminhão e registra horários
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';
import 'coleta/nova_coleta_screen.dart';

class ControleRotaScreen extends StatelessWidget {
  const ControleRotaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final emAndamento = provider.getRotasDiaEmAndamento();
      final hoje = provider.getRotasDiaHoje();
      final concluidas = hoje.where((r) => r.status == 'concluida').toList();

      return Scaffold(
        appBar: AppBar(title: const Text('Controle de Rota')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Banner de rotas em andamento ─────────────────────
            if (emAndamento.isNotEmpty) ...[
              ...emAndamento.map((rota) => _RotaEmAndamentoCard(rota: rota)),
              const SizedBox(height: 16),
            ],

            // ── Botão iniciar nova rota ───────────────────────────
            GestureDetector(
              onTap: () => _abrirIniciarRota(context, provider),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(children: [
                  Icon(Icons.play_circle_fill, color: Colors.white, size: 44),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Iniciar Nova Rota',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          'Selecione a rota e o motorista\npara começar a coleta do dia',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: Colors.white70, size: 16),
                ]),
              ),
            ),

            const SizedBox(height: 20),

            // ── Resumo do dia ─────────────────────────────────────
            Row(children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.directions_run,
                  label: 'Em andamento',
                  value: '${emAndamento.length}',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.check_circle,
                  label: 'Concluídas hoje',
                  value: '${concluidas.length}',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.list_alt,
                  label: 'Total hoje',
                  value: '${hoje.length}',
                  color: AppColors.info,
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Histórico do dia ──────────────────────────────────
            if (hoje.isNotEmpty) ...[
              const Text(
                'Rotas de Hoje',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              ...hoje.map((r) => _RotaDiaCard(rota: r, provider: provider)),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(children: [
                    Icon(Icons.route,
                        size: 64,
                        color: AppColors.textLight.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhuma rota iniciada hoje',
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Toque em "Iniciar Nova Rota" para começar',
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 12),
                    ),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _abrirIniciarRota(context, provider),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar Rota'),
          backgroundColor: AppColors.primary,
        ),
      );
    });
  }

  void _abrirIniciarRota(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IniciarRotaSheet(provider: provider),
    );
  }
}

// ── Card de rota em andamento (destaque) ──────────────────────
class _RotaEmAndamentoCard extends StatelessWidget {
  final RotaDia rota;
  const _RotaEmAndamentoCard({required this.rota});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final carreteiro = provider.getCarreiroById(rota.carreiroId);
      final caminhao = provider.getCaminhaoById(rota.caminhaoId);
      final coletasDaRota = provider.getColetasDaRota(rota.rotaId);
      final tanquesColetados =
          coletasDaRota.where((c) => c.coletaRealizada).length;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.directions_run,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('ROTA EM ANDAMENTO',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
                const Spacer(),
                if (rota.horaInicio != null)
                  Text(
                    'Início: ${formatTime(rota.horaInicio!)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(
                rota.nomeRota,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              if (carreteiro != null)
                Row(children: [
                  const Icon(Icons.badge, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(carreteiro.nome,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ]),
              if (caminhao != null)
                Row(children: [
                  const Icon(Icons.local_shipping,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                      '${caminhao.placa} — ${caminhao.totalCompartimentos} bocas',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _ProgressInfo(
                    label: 'Tanques coletados',
                    value: '$tanquesColetados/${rota.tanques.length}',
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () =>
                      _abrirFinalizarRota(context, rota, provider),
                  icon: const Icon(Icons.stop_circle, size: 16),
                  label: const Text('Finalizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NovaColetaScreen()),
                ),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Registrar Coleta',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(double.infinity, 36),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _abrirFinalizarRota(
      BuildContext context, RotaDia rota, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FinalizarRotaSheet(rota: rota, provider: provider),
    );
  }
}

// ── Card simples de rota do dia ───────────────────────────────
class _RotaDiaCard extends StatelessWidget {
  final RotaDia rota;
  final AppProvider provider;
  const _RotaDiaCard({required this.rota, required this.provider});

  @override
  Widget build(BuildContext context) {
    final carreteiro = provider.getCarreiroById(rota.carreiroId);
    final caminhao = provider.getCaminhaoById(rota.caminhaoId);

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (rota.status) {
      case 'em_andamento':
        statusColor = AppColors.accent;
        statusIcon = Icons.directions_run;
        statusLabel = 'Em andamento';
        break;
      case 'concluida':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusLabel = 'Concluída';
        break;
      default:
        statusColor = AppColors.textLight;
        statusIcon = Icons.schedule;
        statusLabel = 'Pendente';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(statusIcon, color: statusColor, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(rota.nomeRota,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          if (carreteiro != null)
            _InfoRow(
                icon: Icons.badge,
                text: carreteiro.nome,
                color: AppColors.primary),
          if (caminhao != null)
            _InfoRow(
                icon: Icons.local_shipping,
                text:
                    '${caminhao.placa} — ${caminhao.totalCompartimentos} bocas',
                color: AppColors.info),
          if (rota.horaInicio != null)
            _InfoRow(
                icon: Icons.play_arrow,
                text: 'Início: ${formatTime(rota.horaInicio!)}',
                color: AppColors.success),
          if (rota.horaFim != null)
            _InfoRow(
                icon: Icons.stop,
                text: 'Fim: ${formatTime(rota.horaFim!)}',
                color: AppColors.error),
          if (rota.observacoes.isNotEmpty)
            _InfoRow(
                icon: Icons.notes,
                text: rota.observacoes,
                color: AppColors.textLight),
          if (rota.status == 'em_andamento') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _abrirFinalizarRota(context, rota, provider),
                icon: const Icon(Icons.stop_circle, size: 16),
                label: const Text('Finalizar Rota'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  void _abrirFinalizarRota(
      BuildContext context, RotaDia rota, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FinalizarRotaSheet(rota: rota, provider: provider),
    );
  }
}

// ── Sheet: Iniciar Rota ───────────────────────────────────────
class _IniciarRotaSheet extends StatefulWidget {
  final AppProvider provider;
  const _IniciarRotaSheet({required this.provider});

  @override
  State<_IniciarRotaSheet> createState() => _IniciarRotaSheetState();
}

class _IniciarRotaSheetState extends State<_IniciarRotaSheet> {
  String _rotaId = '';
  String _carreiroId = '';
  String _caminhaoId = '';

  // Ao selecionar carreteiro, pré-preenche o caminhão vinculado
  void _onCarreiroChanged(String id) {
    final carreteiro = widget.provider.getCarreiroById(id);
    setState(() {
      _carreiroId = id;
      if (carreteiro != null && carreteiro.caminhaoId.isNotEmpty) {
        _caminhaoId = carreteiro.caminhaoId;
      }
    });
  }

  // Ao selecionar rota, pré-preenche carreteiro e caminhão padrão da rota
  void _onRotaChanged(String id) {
    final rota = widget.provider.getRotaById(id);
    setState(() {
      _rotaId = id;
      if (rota != null) {
        if (rota.carreiroId.isNotEmpty) {
          _onCarreiroChanged(rota.carreiroId);
        }
        if (rota.caminhaoId.isNotEmpty && _caminhaoId.isEmpty) {
          _caminhaoId = rota.caminhaoId;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rotas =
        widget.provider.rotas.where((r) => r.ativo).toList();
    final carreteiros =
        widget.provider.carreteiros.where((c) => c.ativo).toList();
    final caminhoes =
        widget.provider.caminhoes.where((c) => c.ativo).toList();

    final rotaSelecionada =
        _rotaId.isNotEmpty ? widget.provider.getRotaById(_rotaId) : null;
    final caminhaoSelecionado = _caminhaoId.isNotEmpty
        ? widget.provider.getCaminhaoById(_caminhaoId)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.play_circle_fill,
                      color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Iniciar Rota de Coleta',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      Text('Selecione a rota e o motorista',
                          style: TextStyle(
                              color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 24),

            // Rota
            DropdownButtonFormField<String>(
              value: _rotaId.isEmpty ? null : _rotaId,
              decoration: const InputDecoration(
                labelText: 'Rota de Coleta*',
                prefixIcon: Icon(Icons.route, color: AppColors.primary),
              ),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Selecione a rota...')),
                ...rotas.map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(r.nome,
                              overflow: TextOverflow.ellipsis),
                          Text(
                            '${r.tanqueIds.length} tanque(s) · ${r.descricao}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )),
              ],
              onChanged: (v) {
                if (v != null) _onRotaChanged(v);
              },
            ),
            const SizedBox(height: 14),

            // Motorista
            DropdownButtonFormField<String>(
              value: _carreiroId.isEmpty ? null : _carreiroId,
              decoration: const InputDecoration(
                labelText: 'Motorista (Carreteiro)*',
                prefixIcon: Icon(Icons.badge, color: AppColors.success),
              ),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Selecione o motorista...')),
                ...carreteiros.map((c) {
                  final cam = widget.provider.getCaminhaoById(c.caminhaoId);
                  return DropdownMenuItem(
                    value: c.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.nome, overflow: TextOverflow.ellipsis),
                        if (cam != null)
                          Text(
                            '${cam.placa} — ${cam.totalCompartimentos} bocas',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.info),
                          ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (v) {
                if (v != null) _onCarreiroChanged(v);
              },
            ),
            const SizedBox(height: 14),

            // Caminhão (pré-preenchido, mas editável)
            DropdownButtonFormField<String>(
              value: _caminhaoId.isEmpty ? null : _caminhaoId,
              decoration: const InputDecoration(
                labelText: 'Caminhão',
                prefixIcon:
                    Icon(Icons.local_shipping, color: AppColors.info),
                helperText: 'Preenchido automaticamente pelo motorista',
              ),
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Selecione o caminhão...')),
                ...caminhoes.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                          '${c.placa} — ${c.marca} ${c.modelo} (${c.totalCompartimentos} bocas)'),
                    )),
              ],
              onChanged: (v) => setState(() => _caminhaoId = v ?? ''),
            ),
            const SizedBox(height: 16),

            // Preview da rota selecionada
            if (rotaSelecionada != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text('Resumo da Rota',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      '${rotaSelecionada.tanqueIds.length} tanques na rota',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textDark),
                    ),
                    if (rotaSelecionada.descricao.isNotEmpty)
                      Text(
                        rotaSelecionada.descricao,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textLight),
                      ),
                    if (caminhaoSelecionado != null)
                      Text(
                        'Caminhão: ${caminhaoSelecionado.placa} — ${caminhaoSelecionado.totalCompartimentos} bocas disponíveis',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.info),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Botão iniciar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (_rotaId.isNotEmpty && _carreiroId.isNotEmpty)
                    ? () => _iniciar(context)
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Iniciar Rota Agora',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _iniciar(BuildContext context) {
    final rota = widget.provider.getRotaById(_rotaId);
    if (rota == null) return;

    final agora = DateTime.now();

    // Monta lista de tanques da rota com seus produtores
    final tanquesRota = rota.tanqueIds.asMap().entries.map((e) {
      final tanque = widget.provider.getTanqueById(e.value);
      return TanqueRota(
        tanqueId: e.value,
        nomeTanque: tanque?.nome ?? 'Tanque ${e.key + 1}',
        ordem: e.key + 1,
        produtorIds: tanque?.produtorIds ?? [],
      );
    }).toList();

    final rotaDia = RotaDia(
      id: generateId(),
      rotaId: _rotaId,
      nomeRota: rota.nome,
      data: agora,
      carreiroId: _carreiroId,
      caminhaoId: _caminhaoId,
      tanques: tanquesRota,
      status: 'em_andamento',
      horaInicio: agora,
      dataCriacao: agora,
    );

    widget.provider.addRotaDia(rotaDia);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Rota "${rota.nome}" iniciada às ${formatTime(agora)}!'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Sheet: Finalizar Rota ─────────────────────────────────────
class _FinalizarRotaSheet extends StatefulWidget {
  final RotaDia rota;
  final AppProvider provider;
  const _FinalizarRotaSheet({required this.rota, required this.provider});

  @override
  State<_FinalizarRotaSheet> createState() => _FinalizarRotaSheetState();
}

class _FinalizarRotaSheetState extends State<_FinalizarRotaSheet> {
  final _obsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _obsCtrl.text = widget.rota.observacoes;
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carreteiro =
        widget.provider.getCarreiroById(widget.rota.carreiroId);
    final caminhao =
        widget.provider.getCaminhaoById(widget.rota.caminhaoId);
    final coletasDaRota =
        widget.provider.getColetasDaRota(widget.rota.rotaId);
    final totalLitros = coletasDaRota
        .where((c) => c.coletaRealizada)
        .fold<double>(0, (sum, c) => sum + c.quantidadeLitros);
    final tanquesColetados =
        coletasDaRota.where((c) => c.coletaRealizada).length;
    final agora = DateTime.now();
    final duracao = widget.rota.horaInicio != null
        ? agora.difference(widget.rota.horaInicio!)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.stop_circle,
                      color: AppColors.accent, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Finalizar Rota',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      Text('Confirme para encerrar a coleta',
                          style: TextStyle(
                              color: AppColors.textLight, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 24),

            // Resumo da rota
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.rota.nomeRota,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  _ResumoRow(
                      icon: Icons.badge,
                      label: 'Motorista',
                      value: carreteiro?.nome ?? '—'),
                  _ResumoRow(
                      icon: Icons.local_shipping,
                      label: 'Caminhão',
                      value: caminhao != null
                          ? '${caminhao.placa} (${caminhao.totalCompartimentos} bocas)'
                          : '—'),
                  if (widget.rota.horaInicio != null)
                    _ResumoRow(
                        icon: Icons.play_arrow,
                        label: 'Início',
                        value: formatTime(widget.rota.horaInicio!)),
                  _ResumoRow(
                      icon: Icons.stop,
                      label: 'Fim',
                      value: formatTime(agora)),
                  if (duracao != null)
                    _ResumoRow(
                        icon: Icons.timer,
                        label: 'Duração',
                        value:
                            '${duracao.inHours}h ${duracao.inMinutes.remainder(60)}min'),
                  const Divider(height: 16),
                  _ResumoRow(
                      icon: Icons.storage,
                      label: 'Tanques coletados',
                      value:
                          '$tanquesColetados/${widget.rota.tanques.length}'),
                  _ResumoRow(
                      icon: Icons.water_drop,
                      label: 'Total coletado',
                      value: formatLitros(totalLitros)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Observações finais
            TextFormField(
              controller: _obsCtrl,
              decoration: const InputDecoration(
                labelText: 'Observações da Rota (opcional)',
                prefixIcon: Icon(Icons.notes, color: AppColors.textLight),
                border: OutlineInputBorder(),
                hintText:
                    'Ex: Estrada em mau estado no km 5, atraso por acidente...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Botão finalizar
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _finalizar(context, agora),
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirmar Finalização',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finalizar(BuildContext context, DateTime agora) {
    final rotaAtualizada = RotaDia(
      id: widget.rota.id,
      rotaId: widget.rota.rotaId,
      nomeRota: widget.rota.nomeRota,
      data: widget.rota.data,
      carreiroId: widget.rota.carreiroId,
      caminhaoId: widget.rota.caminhaoId,
      tanques: widget.rota.tanques,
      status: 'concluida',
      horaInicio: widget.rota.horaInicio,
      horaFim: agora,
      observacoes: _obsCtrl.text.trim(),
      dataCriacao: widget.rota.dataCriacao,
    );

    widget.provider.updateRotaDia(rotaAtualizada);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Rota finalizada às ${formatTime(agora)}! Coleta concluída.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoCard(
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
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label,
            style: const TextStyle(color: AppColors.textLight, fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _ProgressInfo extends StatelessWidget {
  final String label;
  final String value;
  const _ProgressInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18)),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _InfoRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: color),
                overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _ResumoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ResumoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textLight)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}
