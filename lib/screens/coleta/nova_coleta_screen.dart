import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/helpers.dart';

// ============================================================
// NOVA COLETA
// - Rota / Motorista / Caminhão herdados da rota em andamento
// - GPS capturado automaticamente ao salvar
// - Apenas 1 coleta por tanque (por dia)
// - Apenas 1 entrega por produtor por data
// ============================================================

class NovaColetaScreen extends StatefulWidget {
  final ColetaLeite? coletaParaEditar;
  const NovaColetaScreen({super.key, this.coletaParaEditar});

  @override
  State<NovaColetaScreen> createState() => _NovaColetaScreenState();
}

class _NovaColetaScreenState extends State<NovaColetaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Rota em andamento (preenchida automaticamente)
  RotaDia? _rotaDia;
  String _rotaId = '';
  String _tanqueId = '';
  String _caminhaoId = '';
  String _carreiroId = '';
  // Data/hora: null em nova coleta (gerada ao salvar), preenchida na edição
  DateTime? _dataHoraOriginal;

  // GPS (capturado ao salvar)
  double? _lat;
  double? _lng;

  // Dados do tanque
  final _litrosCtrl = TextEditingController();
  final _reguaCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  ResultadoAlizarol _alizarol = ResultadoAlizarol.normal;
  int _compartimento = 1;

  // Status
  bool _coletaRealizada = true;
  final _motivoCtrl = TextEditingController();
  final _obsQualCtrl = TextEditingController();

  // Entregas dos produtores: Map<produtorId, lista de entradas>
  final Map<String, List<_EntradaEntrega>> _entregasPorProdutor = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _inicializar());
  }

  void _inicializar() {
    final provider = context.read<AppProvider>();

    if (widget.coletaParaEditar != null) {
      // ── Modo edição ──────────────────────────────────────
      final e = widget.coletaParaEditar!;
      _rotaId = e.rotaId;
      _tanqueId = e.tanqueId;
      _caminhaoId = e.caminhaoId;
      _carreiroId = e.carreiroId;
      _dataHoraOriginal = e.dataHoraColeta;
      _lat = e.latitude;
      _lng = e.longitude;
      _litrosCtrl.text = e.quantidadeLitros.toStringAsFixed(1);
      _reguaCtrl.text = e.valorRegua.toStringAsFixed(1);
      _tempCtrl.text = e.temperatura > 0 ? e.temperatura.toStringAsFixed(1) : '';
      _alizarol = e.alizarol;
      _compartimento = e.compartimentoCaminhao;
      _coletaRealizada = e.coletaRealizada;
      _motivoCtrl.text = e.motivoNaoColeta;
      _obsQualCtrl.text = e.observacoesQualidade;
      for (final ep in e.entregasProdutores) {
        _entregasPorProdutor.putIfAbsent(ep.produtorId, () => []).add(
          _EntradaEntrega(
            id: ep.id,
            litrosCtrl: TextEditingController(
                text: ep.quantidadeLitros.toStringAsFixed(1)),
            obsCtrl: TextEditingController(text: ep.observacao),
            dataEntrega: ep.dataEntrega,
          ),
        );
      }
      // Tenta recuperar a rota em andamento correspondente
      _rotaDia = provider.rotasDia
          .where((r) => r.rotaId == _rotaId && r.status == 'em_andamento')
          .firstOrNull;
    } else {
      // ── Modo novo: herda rota em andamento ───────────────
      final emAndamento = provider.getRotasDiaEmAndamento();
      if (emAndamento.isNotEmpty) {
        _rotaDia = emAndamento.first;
        _rotaId = _rotaDia!.rotaId;
        _caminhaoId = _rotaDia!.caminhaoId;
        _carreiroId = _rotaDia!.carreiroId;
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _litrosCtrl.dispose();
    _reguaCtrl.dispose();
    _tempCtrl.dispose();
    _motivoCtrl.dispose();
    _obsQualCtrl.dispose();
    for (final lista in _entregasPorProdutor.values) {
      for (final e in lista) {
        e.litrosCtrl.dispose();
        e.obsCtrl.dispose();
      }
    }
    super.dispose();
  }

  // Reinicia entradas ao trocar de tanque
  void _onTanqueChanged(String novoTanqueId, AppProvider provider) {
    for (final lista in _entregasPorProdutor.values) {
      for (final e in lista) {
        e.litrosCtrl.dispose();
        e.obsCtrl.dispose();
      }
    }
    _entregasPorProdutor.clear();
    if (novoTanqueId.isNotEmpty) {
      for (final p in provider.getProdutoresDeTanque(novoTanqueId)) {
        _entregasPorProdutor[p.id] = [
          _EntradaEntrega(
            id: generateId(),
            litrosCtrl: TextEditingController(),
            obsCtrl: TextEditingController(),
            dataEntrega: _dataHoraOriginal ?? DateTime.now(),
          )
        ];
      }
    }
    setState(() => _tanqueId = novoTanqueId);
  }

  double get _totalLitrosProdutores {
    double t = 0;
    for (final lista in _entregasPorProdutor.values) {
      for (final e in lista) {
        t += double.tryParse(e.litrosCtrl.text) ?? 0;
      }
    }
    return t;
  }

  // Captura GPS silenciosamente (sem UI de loading)
  Future<void> _capturarGpsSilencioso() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;
    } catch (_) {
      // GPS não disponível (web/emulador): deixa nulo
    }
  }

  // Valida se já existe coleta para esse tanque hoje
  bool _tanqueJaColetadoHoje(AppProvider provider) {
    if (_tanqueId.isEmpty) return false;
    final hoje = _dataHoraOriginal ?? DateTime.now();
    final existente = provider.coletas.where((c) {
      if (c.tanqueId != _tanqueId) return false;
      if (widget.coletaParaEditar != null && c.id == widget.coletaParaEditar!.id) return false;
      final d = c.dataHoraColeta;
      return d.year == hoje.year && d.month == hoje.month && d.day == hoje.day;
    });
    return existente.isNotEmpty;
  }

  // Valida entrega duplicada produtor+data
  // Verifica duplicatas dentro da coleta atual E em outras coletas já salvas
  List<String> _validarEntregasDuplicadas() {
    final provider = context.read<AppProvider>();
    final erros = <String>[];
    final coletaEditandoId = widget.coletaParaEditar?.id;

    for (final entry in _entregasPorProdutor.entries) {
      final produtorId = entry.key;
      final novasEntradas = entry.value
          .where((e) => (double.tryParse(e.litrosCtrl.text) ?? 0) > 0)
          .toList();

      // 1) Duplicatas dentro da própria coleta (mesma data duas vezes)
      final datasNovas = novasEntradas
          .map((e) => '${e.dataEntrega.year}-${e.dataEntrega.month.toString().padLeft(2, '0')}-${e.dataEntrega.day.toString().padLeft(2, '0')}')
          .toList();
      final datasUnicas = datasNovas.toSet();
      if (datasNovas.length != datasUnicas.length) {
        final produtor = provider.getProdutorById(produtorId);
        if (!erros.contains(produtor?.nome ?? produtorId)) {
          erros.add('${produtor?.nome ?? produtorId} (data duplicada na coleta)');
        }
        continue;
      }

      // 2) Duplicatas em outras coletas já salvas (mesma data em outra coleta)
      final entregasJaSalvas = provider.coletas
          .where((c) => c.id != coletaEditandoId)
          .expand((c) => c.entregasProdutores)
          .where((e) => e.produtorId == produtorId)
          .toList();

      for (final novaEntrada in novasEntradas) {
        final chaveNova =
            '${novaEntrada.dataEntrega.year}-${novaEntrada.dataEntrega.month.toString().padLeft(2, '0')}-${novaEntrada.dataEntrega.day.toString().padLeft(2, '0')}';
        final jaSalva = entregasJaSalvas.any((e) {
          final d = e.dataEntrega;
          final chave =
              '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          return chave == chaveNova;
        });
        if (jaSalva) {
          final produtor = provider.getProdutorById(produtorId);
          final nome = produtor?.nome ?? produtorId;
          if (!erros.contains(nome)) {
            erros.add('$nome (já possui entrega em ${novaEntrada.dataEntrega.day.toString().padLeft(2, '0')}/${novaEntrada.dataEntrega.month.toString().padLeft(2, '0')})');
          }
          break;
        }
      }
    }
    return erros;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final temRotaAtiva = _rotaDia != null;
      final rota = provider.getRotaById(_rotaId);
      final tanquesDaRota = rota != null
          ? rota.tanqueIds
              .map((id) => provider.getTanqueById(id))
              .whereType<Tanque>()
              .toList()
          : <Tanque>[];
      final caminhao = provider.getCaminhaoById(_caminhaoId);
      final carreteiro = provider.getCarreiroById(_carreiroId);
      final totalComp = caminhao?.totalCompartimentos ?? 3;
      final produtoresTanque = _tanqueId.isNotEmpty
          ? provider.getProdutoresDeTanque(_tanqueId)
          : <Produtor>[];
      final totalProd = _totalLitrosProdutores;
      final tanqueJaColetado = _tanqueJaColetadoHoje(provider);

      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
              widget.coletaParaEditar == null ? 'Nova Coleta' : 'Editar Coleta'),
          actions: [
            TextButton.icon(
              onPressed: () => _salvar(context, provider),
              icon: const Icon(Icons.save, color: Colors.white, size: 18),
              label:
                  const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ══ BANNER: Rota em andamento ══════════════════════
              if (temRotaAtiva) ...[
                _RotaAtivaBanner(
                  rotaDia: _rotaDia!,
                  rota: rota,
                  carreteiro: carreteiro,
                  caminhao: caminhao,
                ),
                const SizedBox(height: 12),
              ] else if (widget.coletaParaEditar == null) ...[
                _SemRotaBanner(
                  onIniciarRota: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
              ],

              // ══ SEÇÃO 1: IDENTIFICAÇÃO ══════════════════════════
              _SectionCard(
                title: 'Identificação da Coleta',
                icon: Icons.assignment_outlined,
                children: [
                  // Data/hora (somente leitura em edição; gerada ao salvar em nova coleta)
                  if (_dataHoraOriginal != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(children: [
                        const Icon(Icons.access_time, color: AppColors.textLight, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Registrado em: ${formatDateTime(_dataHoraOriginal!)}',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.lock_outline, color: AppColors.textLight, size: 14),
                      ]),
                    ),
                  if (_dataHoraOriginal != null) const SizedBox(height: 12),

                  // GPS: apenas indicador (capturado ao salvar)
                  _GpsIndicator(lat: _lat, lng: _lng),
                  const SizedBox(height: 12),

                  // Tanque (único campo editável — rota já vem preenchida)
                  DropdownButtonFormField<String>(
                    value: _tanqueId.isEmpty ? null : _tanqueId,
                    decoration: const InputDecoration(
                      labelText: 'Tanque*',
                      prefixIcon:
                          Icon(Icons.storage, color: AppColors.primary),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: '', child: Text('Selecione o tanque...')),
                      ...tanquesDaRota.map((t) {
                        // Verificar se já foi coletado hoje
                        final jaColetado = provider.coletas.any((c) {
                          if (c.tanqueId != t.id) return false;
                          if (widget.coletaParaEditar != null &&
                              c.id == widget.coletaParaEditar!.id) return false;
                          final d = c.dataHoraColeta;
                          final ref = _dataHoraOriginal ?? DateTime.now();
                          return d.year == ref.year &&
                              d.month == ref.month &&
                              d.day == ref.day;
                        });
                        return DropdownMenuItem(
                          value: t.id,
                          child: Row(children: [
                            Icon(
                              t.tipo == TipoTanque.individual
                                  ? Icons.person
                                  : Icons.group,
                              size: 16,
                              color: jaColetado
                                  ? AppColors.error
                                  : (t.tipo == TipoTanque.individual
                                      ? AppColors.primary
                                      : AppColors.accent),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                jaColetado
                                    ? '${t.nome} (já coletado)'
                                    : t.nome,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: jaColetado
                                      ? AppColors.error
                                      : AppColors.textDark,
                                ),
                              ),
                            ),
                          ]),
                        );
                      }),
                    ],
                    onChanged: (v) => _onTanqueChanged(v ?? '', provider),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Selecione um tanque' : null,
                  ),

                  // Aviso se tanque já coletado
                  if (tanqueJaColetado) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.warning_amber,
                            color: AppColors.error, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este tanque já possui uma coleta registrada hoje. '
                            'Apenas uma coleta é permitida por tanque por dia.',
                            style:
                                TextStyle(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 16),

              // ══ SEÇÃO 2: STATUS DA COLETA ═══════════════════════
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Coleta Realizada?',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark),
                              ),
                              Switch(
                                value: _coletaRealizada,
                                activeTrackColor: AppColors.success,
                                inactiveTrackColor:
                                    AppColors.error.withValues(alpha: 0.5),
                                onChanged: (v) =>
                                    setState(() => _coletaRealizada = v),
                              ),
                            ]),
                        if (!_coletaRealizada) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _motivoCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Motivo da Não Coleta*',
                              prefixIcon: Icon(Icons.warning_amber,
                                  color: AppColors.warning),
                            ),
                            maxLines: 3,
                            validator: (v) =>
                                (!_coletaRealizada && (v == null || v.isEmpty))
                                    ? 'Informe o motivo'
                                    : null,
                          ),
                        ],
                      ]),
                ),
              ),

              if (_coletaRealizada) ...[
                const SizedBox(height: 16),

                // ══ SEÇÃO 3: MEDIÇÕES DO TANQUE ══════════════════════
                _SectionCard(
                  title: 'Medições do Tanque',
                  icon: Icons.water_drop_outlined,
                  children: [
                    TextFormField(
                      controller: _litrosCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantidade Total Coletada (Litros)*',
                        prefixIcon:
                            Icon(Icons.water_drop, color: AppColors.primary),
                        suffixText: 'L',
                        helperText: 'Valor lido diretamente no tanque',
                      ),
                      validator: (v) =>
                          (_coletaRealizada && (v == null || v.isEmpty))
                              ? 'Informe a quantidade'
                              : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _reguaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Valor Medido na Régua*',
                        prefixIcon:
                            Icon(Icons.straighten, color: AppColors.accent),
                        helperText: 'Medição física da régua do tanque',
                      ),
                      validator: (v) =>
                          (_coletaRealizada && (v == null || v.isEmpty))
                              ? 'Informe o valor da régua'
                              : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _tempCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Temperatura do Leite*',
                        prefixIcon:
                            Icon(Icons.thermostat, color: AppColors.info),
                        suffixText: '°C',
                      ),
                      validator: (v) =>
                          (_coletaRealizada && (v == null || v.isEmpty))
                              ? 'Informe a temperatura'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    const Text('Teste de Alizarol',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: ResultadoAlizarol.values.map((r) {
                        Color chipColor;
                        switch (r) {
                          case ResultadoAlizarol.normal:
                            chipColor = AppColors.success;
                            break;
                          case ResultadoAlizarol.suspeito:
                            chipColor = AppColors.warning;
                            break;
                          default:
                            chipColor = AppColors.error;
                        }
                        final sel = _alizarol == r;
                        return GestureDetector(
                          onTap: () => setState(() => _alizarol = r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? chipColor.withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: sel ? chipColor : Colors.grey.shade300,
                                width: sel ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${r.emoji} ${r.label}',
                              style: TextStyle(
                                color: sel ? chipColor : AppColors.textLight,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    const Text('Boca do Caminhão (Compartimento)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    if (_caminhaoId.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline,
                              color: AppColors.textLight, size: 16),
                          SizedBox(width: 8),
                          Text(
                              'Inicie uma rota para selecionar a boca do caminhão',
                              style: TextStyle(
                                  color: AppColors.textLight, fontSize: 13)),
                        ]),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(totalComp, (i) {
                          final n = i + 1;
                          final sel = _compartimento == n;
                          return GestureDetector(
                            onTap: () => setState(() => _compartimento = n),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 80,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              decoration: BoxDecoration(
                                gradient:
                                    sel ? AppColors.primaryGradient : null,
                                color: sel ? null : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(children: [
                                Icon(Icons.local_shipping,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textLight,
                                    size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  'Boca $n',
                                  style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ]),
                            ),
                          );
                        }),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // ══ SEÇÃO 4: ENTREGAS POR PRODUTOR ══════════════════
                _EntregasProdutoresCard(
                  tanqueId: _tanqueId,
                  produtores: produtoresTanque,
                  entregasPorProdutor: _entregasPorProdutor,
                  dataReferencia: _dataHoraOriginal ?? DateTime.now(),
                  totalLitros: totalProd,
                  onChanged: () => setState(() {}),
                  onAddEntrada: (produtorId) => setState(() {
                    _entregasPorProdutor.putIfAbsent(produtorId, () => []).add(
                      _EntradaEntrega(
                        id: generateId(),
                        litrosCtrl: TextEditingController(),
                        obsCtrl: TextEditingController(),
                        dataEntrega: _dataHoraOriginal ?? DateTime.now(),
                      ),
                    );
                  }),
                  onRemoveEntrada: (produtorId, index) => setState(() {
                    final lista = _entregasPorProdutor[produtorId];
                    if (lista != null && lista.length > 1) {
                      lista[index].litrosCtrl.dispose();
                      lista[index].obsCtrl.dispose();
                      lista.removeAt(index);
                    } else {
                      lista?[0].litrosCtrl.clear();
                      lista?[0].obsCtrl.clear();
                    }
                  }),
                ),

                const SizedBox(height: 16),

                // ══ SEÇÃO 5: OBSERVAÇÕES DE QUALIDADE ═══════════════
                _SectionCard(
                  title: 'Observações de Qualidade',
                  icon: Icons.rate_review_outlined,
                  children: [
                    if (totalProd > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.people,
                              color: AppColors.accent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Total lançado pelos produtores: ${formatLitros(totalProd)}',
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ]),
                      ),
                    TextFormField(
                      controller: _obsQualCtrl,
                      decoration: const InputDecoration(
                        hintText:
                            'Ex: Leite com odor estranho, temperatura fora do padrão...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(
                    widget.coletaParaEditar == null
                        ? 'Registrar Coleta'
                        : 'Salvar Alterações',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () => _salvar(context, provider),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _salvar(BuildContext context, AppProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    // Bloqueia coleta duplicada no mesmo tanque no mesmo dia
    if (_coletaRealizada && _tanqueJaColetadoHoje(provider)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Já existe uma coleta registrada para este tanque hoje. '
            'Apenas uma coleta é permitida por tanque por dia.'),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 4),
      ));
      return;
    }

    // Bloqueia entrega duplicada produtor+data
    final duplicados = _validarEntregasDuplicadas();
    if (duplicados.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Produtor(es) com mais de uma entrega na mesma data: ${duplicados.join(', ')}. '
            'Cada produtor só pode ter uma entrega por data.'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    // Captura GPS automaticamente ao salvar
    await _capturarGpsSilencioso();

    // Montar entregas
    final entregas = <EntregaProdutor>[];
    for (final entry in _entregasPorProdutor.entries) {
      for (final entrada in entry.value) {
        final litros = double.tryParse(entrada.litrosCtrl.text) ?? 0;
        if (litros <= 0) continue;
        entregas.add(EntregaProdutor(
          id: entrada.id,
          produtorId: entry.key,
          tanqueId: _tanqueId,
          dataEntrega: entrada.dataEntrega,
          quantidadeLitros: litros,
          observacao: entrada.obsCtrl.text.trim(),
        ));
      }
    }

    final coleta = ColetaLeite(
      id: widget.coletaParaEditar?.id ?? generateId(),
      rotaId: _rotaId,
      tanqueId: _tanqueId,
      caminhaoId: _caminhaoId,
      carreiroId: _carreiroId,
      dataHoraColeta: _dataHoraOriginal ?? DateTime.now(),
      latitude: _lat,
      longitude: _lng,
      quantidadeLitros: double.tryParse(_litrosCtrl.text) ?? 0,
      valorRegua: double.tryParse(_reguaCtrl.text) ?? 0,
      temperatura: double.tryParse(_tempCtrl.text) ?? 0,
      alizarol: _alizarol,
      compartimentoCaminhao: _compartimento,
      observacoesQualidade: _obsQualCtrl.text.trim(),
      motivoNaoColeta: _motivoCtrl.text.trim(),
      coletaRealizada: _coletaRealizada,
      entregasProdutores: entregas,
      dataCadastro: widget.coletaParaEditar?.dataCadastro ?? DateTime.now(),
    );

    if (widget.coletaParaEditar == null) {
      provider.addColeta(coleta);
    } else {
      provider.updateColeta(coleta);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_lat != null
            ? 'Coleta registrada! GPS capturado: ${_lat!.toStringAsFixed(5)}'
            : 'Coleta registrada com sucesso!'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    }
  }
}

// ============================================================
// MODELO INTERNO: uma entrada de entrega de um produtor
// ============================================================
class _EntradaEntrega {
  final String id;
  final TextEditingController litrosCtrl;
  final TextEditingController obsCtrl;
  DateTime dataEntrega;

  _EntradaEntrega({
    required this.id,
    required this.litrosCtrl,
    required this.obsCtrl,
    required this.dataEntrega,
  });
}

// ============================================================
// BANNERS INFORMATIVOS
// ============================================================
class _RotaAtivaBanner extends StatelessWidget {
  final RotaDia rotaDia;
  final Rota? rota;
  final Carreteiro? carreteiro;
  final Caminhao? caminhao;
  const _RotaAtivaBanner(
      {required this.rotaDia,
      this.rota,
      this.carreteiro,
      this.caminhao});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        const Icon(Icons.play_circle_fill,
            color: AppColors.success, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rota em andamento: ${rota?.nome ?? rotaDia.nomeRota}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      fontSize: 13),
                ),
                if (carreteiro != null)
                  Text('Motorista: ${carreteiro!.nome}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textDark)),
                if (caminhao != null)
                  Text(
                    'Caminhão: ${caminhao!.placa} — ${caminhao!.totalCompartimentos} bocas',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textDark),
                  ),
              ]),
        ),
      ]),
    );
  }
}

class _SemRotaBanner extends StatelessWidget {
  final VoidCallback onIniciarRota;
  const _SemRotaBanner({required this.onIniciarRota});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber, color: AppColors.warning, size: 22),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Nenhuma rota em andamento. Inicie uma rota na aba "Rotas" antes de registrar uma coleta.',
            style:
                TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ),
        TextButton(
          onPressed: onIniciarRota,
          child: const Text('Ir para Rotas',
              style: TextStyle(
                  color: AppColors.warning, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }
}

// ============================================================
// INDICADOR DE GPS (sem botão — capturado ao salvar)
// ============================================================
class _GpsIndicator extends StatelessWidget {
  final double? lat;
  final double? lng;
  const _GpsIndicator({this.lat, this.lng});

  @override
  Widget build(BuildContext context) {
    final tem = lat != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tem
            ? AppColors.success.withValues(alpha: 0.06)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tem
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(children: [
        Icon(
          tem ? Icons.gps_fixed : Icons.gps_not_fixed,
          color: tem ? AppColors.success : AppColors.textLight,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tem
                ? 'GPS: ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                : 'Localização GPS será capturada automaticamente ao salvar',
            style: TextStyle(
                fontSize: 12,
                color: tem ? AppColors.success : AppColors.textLight),
          ),
        ),
      ]),
    );
  }
}

// ============================================================
// CARD PRINCIPAL: ENTREGAS DOS PRODUTORES
// ============================================================
class _EntregasProdutoresCard extends StatelessWidget {
  final String tanqueId;
  final List<Produtor> produtores;
  final Map<String, List<_EntradaEntrega>> entregasPorProdutor;
  final DateTime dataReferencia;
  final double totalLitros;
  final VoidCallback onChanged;
  final void Function(String produtorId) onAddEntrada;
  final void Function(String produtorId, int index) onRemoveEntrada;

  const _EntregasProdutoresCard({
    required this.tanqueId,
    required this.produtores,
    required this.entregasPorProdutor,
    required this.dataReferencia,
    required this.totalLitros,
    required this.onChanged,
    required this.onAddEntrada,
    required this.onRemoveEntrada,
  });

  @override
  Widget build(BuildContext context) {
    if (tanqueId.isEmpty) {
      return Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            Icon(Icons.info_outline, color: AppColors.textLight),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Selecione o tanque para lançar as entregas individuais dos produtores.',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
            ),
          ]),
        ),
      );
    }

    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Entregas dos Produtores',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    Text(
                      '${produtores.length} produtor(es) vinculado(s) ao tanque',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                  ]),
            ),
            if (totalLitros > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  formatLitros(totalLitros),
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
          ]),
          const Divider(height: 20),
          if (produtores.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(children: [
                Icon(Icons.person_off, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nenhum produtor vinculado a este tanque.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ]),
            )
          else
            ...produtores.map((p) => _ProdutorEntregasExpandido(
                  produtor: p,
                  entradas: entregasPorProdutor[p.id] ?? [],
                  dataReferencia: dataReferencia,
                  onChanged: onChanged,
                  onAddEntrada: () => onAddEntrada(p.id),
                  onRemoveEntrada: (i) => onRemoveEntrada(p.id, i),
                )),
        ]),
      ),
    );
  }
}

// ============================================================
// PRODUTOR COM MÚLTIPLAS ENTRADAS
// ============================================================
class _ProdutorEntregasExpandido extends StatefulWidget {
  final Produtor produtor;
  final List<_EntradaEntrega> entradas;
  final DateTime dataReferencia;
  final VoidCallback onChanged;
  final VoidCallback onAddEntrada;
  final void Function(int index) onRemoveEntrada;

  const _ProdutorEntregasExpandido({
    required this.produtor,
    required this.entradas,
    required this.dataReferencia,
    required this.onChanged,
    required this.onAddEntrada,
    required this.onRemoveEntrada,
  });

  @override
  State<_ProdutorEntregasExpandido> createState() =>
      _ProdutorEntregasExpandidoState();
}

class _ProdutorEntregasExpandidoState
    extends State<_ProdutorEntregasExpandido> {
  bool _expandido = true;

  double get _totalProdutor => widget.entradas
      .fold(0.0, (s, e) => s + (double.tryParse(e.litrosCtrl.text) ?? 0));

  @override
  Widget build(BuildContext context) {
    final total = _totalProdutor;
    final tem = total > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tem
            ? AppColors.primary.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        border: Border.all(
          color: tem
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.grey.shade200,
          width: tem ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        InkWell(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
          onTap: () => setState(() => _expandido = !_expandido),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    tem ? AppColors.primary : Colors.grey.shade300,
                child: Text(
                  widget.produtor.nome.isNotEmpty
                      ? widget.produtor.nome[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: tem ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.produtor.nome,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tem
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                              fontSize: 14)),
                      Text(
                        'Cód: ${widget.produtor.codigo}${widget.produtor.municipio.isNotEmpty ? " • ${widget.produtor.municipio}" : ""}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight),
                      ),
                    ]),
              ),
              if (tem) ...[
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatLitros(total),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(
                      '${widget.entradas.where((e) => (double.tryParse(e.litrosCtrl.text) ?? 0) > 0).length} entrega(s)',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textLight)),
                ]),
                const SizedBox(width: 8),
              ],
              Icon(
                _expandido
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: AppColors.textLight,
                size: 20,
              ),
            ]),
          ),
        ),
        if (_expandido) ...[
          const Divider(height: 1, indent: 14, endIndent: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(children: [
              ...widget.entradas.asMap().entries.map((e) =>
                  _EntradaEntregaTile(
                    entrada: e.value,
                    index: e.key,
                    totalEntradas: widget.entradas.length,
                    onChanged: () {
                      setState(() {});
                      widget.onChanged();
                    },
                    onRemove: () => widget.onRemoveEntrada(e.key),
                  )),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: widget.onAddEntrada,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Adicionar outra data de entrega',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ============================================================
// TILE: UMA ENTRADA (data + litros + obs)
// ============================================================
class _EntradaEntregaTile extends StatefulWidget {
  final _EntradaEntrega entrada;
  final int index;
  final int totalEntradas;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _EntradaEntregaTile({
    required this.entrada,
    required this.index,
    required this.totalEntradas,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_EntradaEntregaTile> createState() => _EntradaEntregaTileState();
}

class _EntradaEntregaTileState extends State<_EntradaEntregaTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabeçalho: número + data + remover
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Entrega ${widget.index + 1}',
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _selecionarData(context),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.calendar_today,
                  size: 13, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                formatDate(widget.entrada.dataEntrega),
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.edit, size: 12, color: AppColors.primary),
            ]),
          ),
          const Spacer(),
          // Botão excluir lançamento (sempre visível)
          Tooltip(
            message: widget.totalEntradas > 1
                ? 'Remover este lançamento'
                : 'Limpar este lançamento',
            child: InkWell(
              onTap: () => _confirmarExclusaoEntrada(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
              ),
            ),
          ),
        ]),

        const SizedBox(height: 10),

        // ── Litros (campo maior) + Observação em coluna ──────
        Column(children: [
          // Campo litros com tamanho generoso — sem suffixText para não cortar
          SizedBox(
            height: 72,
            child: TextFormField(
              controller: widget.entrada.litrosCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1.2),
              decoration: InputDecoration(
                labelText: 'Quantidade (Litros)',
                labelStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 10, right: 6),
                  child: Icon(Icons.water_drop,
                      color: AppColors.primary, size: 22),
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                suffix: const Text('L',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight)),
                filled: true,
                fillColor: AppColors.primary.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if ((double.tryParse(v) ?? 0) <= 0) return 'Valor inválido';
                return null;
              },
              onChanged: (_) => widget.onChanged(),
            ),
          ),
          const SizedBox(height: 8),
          // Campo observação
          TextFormField(
            controller: widget.entrada.obsCtrl,
            decoration: InputDecoration(
              labelText: 'Observação (opcional)',
              labelStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.notes,
                  color: AppColors.textLight, size: 18),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            onChanged: (_) => widget.onChanged(),
          ),
        ]),
      ]),
    );
  }

  Future<void> _selecionarData(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: widget.entrada.dataEntrega,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) {
      setState(() => widget.entrada.dataEntrega = d);
      widget.onChanged();
    }
  }

  void _confirmarExclusaoEntrada(BuildContext context) {
    final temValor = (double.tryParse(widget.entrada.litrosCtrl.text) ?? 0) > 0;
    if (!temValor && widget.totalEntradas == 1) {
      // Sem valor e é única entrada: nada a fazer
      return;
    }

    final acao = widget.totalEntradas > 1 ? 'remover' : 'limpar';
    final descricao = widget.totalEntradas > 1
        ? 'Deseja remover o lançamento ${widget.index + 1}?'
        : 'Deseja limpar os dados deste lançamento?';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${acao[0].toUpperCase()}${acao.substring(1)} lançamento'),
        content: Text(descricao),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onRemove();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(acao[0].toUpperCase() + acao.substring(1)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGETS AUXILIARES
// ============================================================
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
              ]),
              const Divider(height: 20),
              ...children,
            ]),
      ),
    );
  }
}

class _DataHoraTile extends StatelessWidget {
  final DateTime dataHora;
  final VoidCallback onTap;
  const _DataHoraTile({required this.dataHora, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.access_time, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              formatDateTime(dataHora),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
          const Icon(Icons.edit, color: AppColors.primary, size: 16),
        ]),
      ),
    );
  }
}
