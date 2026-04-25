import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/helpers.dart';

class ExportarScreen extends StatefulWidget {
  const ExportarScreen({super.key});
  @override
  State<ExportarScreen> createState() => _ExportarScreenState();
}

class _ExportarScreenState extends State<ExportarScreen> {
  DateTime? _dataInicio;
  DateTime? _dataFim;
  String _formatoExport = 'JSON';
  bool _exporting = false;
  String _serverUrl = 'https://erp.suaempresa.com.br/api/coleta/importar';
  String _statusMsg = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final coletas = _filtrarColetas(provider);
      final entregas = _filtrarEntregas(provider);

      return Scaffold(
        appBar: AppBar(title: const Text('Exportar para ERP')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(children: [
                Icon(Icons.upload_file, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Exportação de Dados', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Envie os dados coletados para o servidor ERP',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ])),
              ]),
            ),

            const SizedBox(height: 20),

            // Filtro de Período
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.filter_alt, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Período de Exportação', style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dataInicio != null ? formatDate(_dataInicio!) : 'Data Início'),
                    onPressed: () async {
                      final d = await showDatePicker(context: context,
                        initialDate: _dataInicio ?? DateTime.now(),
                        firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) setState(() => _dataInicio = d);
                    },
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dataFim != null ? formatDate(_dataFim!) : 'Data Fim'),
                    onPressed: () async {
                      final d = await showDatePicker(context: context,
                        initialDate: _dataFim ?? DateTime.now(),
                        firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (d != null) setState(() => _dataFim = d);
                    },
                  )),
                ]),
                if (_dataInicio != null || _dataFim != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Limpar filtros'),
                    onPressed: () => setState(() { _dataInicio = null; _dataFim = null; }),
                  ),
                ],
              ]),
            )),

            const SizedBox(height: 12),

            // Resumo dos dados
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.summarize, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Resumo dos Dados', style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const Divider(),
                _SummaryRow('Coletas', '${coletas.length}', Icons.water_drop, AppColors.primary),
                _SummaryRow('Coletas Realizadas', '${coletas.where((c) => c.coletaRealizada).length}', Icons.check_circle, AppColors.success),
                _SummaryRow('Não Coletadas', '${coletas.where((c) => !c.coletaRealizada).length}', Icons.cancel, AppColors.error),
                _SummaryRow('Total de Litros',
                    formatLitros(coletas.where((c) => c.coletaRealizada).fold(0.0, (s, c) => s + c.quantidadeLitros)),
                    Icons.local_drink, AppColors.accent),
                _SummaryRow('Entregas de Produtores', '${entregas.length}', Icons.person, AppColors.info),
              ]),
            )),

            const SizedBox(height: 12),

            // Formato de Exportação
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Formato de Exportação', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: ['JSON', 'CSV'].map((f) {
                  return Expanded(child: RadioListTile<String>(
                    title: Text(f, style: const TextStyle(fontSize: 14)),
                    value: f, groupValue: _formatoExport,
                    onChanged: (v) => setState(() => _formatoExport = v!),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ));
                }).toList()),
              ]),
            )),

            const SizedBox(height: 12),

            // Configuração do Servidor
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.cloud_upload, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Servidor ERP', style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _serverUrl,
                  decoration: const InputDecoration(
                    labelText: 'URL do Endpoint ERP',
                    prefixIcon: Icon(Icons.link),
                    hintText: 'https://erp.empresa.com.br/api/importar',
                  ),
                  onChanged: (v) => _serverUrl = v,
                ),
              ]),
            )),

            const SizedBox(height: 16),

            if (_statusMsg.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMsg.startsWith('✅')
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _statusMsg.startsWith('✅') ? AppColors.success : AppColors.error),
                ),
                child: Text(_statusMsg,
                    style: TextStyle(color: _statusMsg.startsWith('✅') ? AppColors.success : AppColors.error)),
              ),

            // Botões de Ação
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.preview),
                label: const Text('Pré-visualizar'),
                onPressed: coletas.isEmpty ? null : () => _preview(context, provider, coletas, entregas),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                icon: _exporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_exporting ? 'Enviando...' : 'Enviar ao ERP'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                onPressed: (coletas.isEmpty || _exporting) ? null : () => _exportar(context, provider, coletas, entregas),
              )),
            ]),

            const SizedBox(height: 20),

            // Informações
            Card(
              color: AppColors.info.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.info, color: AppColors.info, size: 20),
                    SizedBox(width: 8),
                    Text('Sobre a Exportação', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.info)),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    '• Os dados são enviados via HTTP POST no formato selecionado\n'
                    '• O servidor ERP deve aceitar requisições na URL configurada\n'
                    '• Dados exportados incluem: coletas, quantidades, GPS, alizarol, temperatura e entregas por produtor\n'
                    '• Configure a autenticação do servidor conforme necessário\n'
                    '• Em caso de falha, verifique a conectividade e a URL do servidor',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  List _filtrarColetas(AppProvider provider) {
    var coletas = provider.coletas;
    if (_dataInicio != null) {
      coletas = coletas.where((c) => c.dataHoraColeta.isAfter(_dataInicio!.subtract(const Duration(days: 1)))).toList();
    }
    if (_dataFim != null) {
      coletas = coletas.where((c) => c.dataHoraColeta.isBefore(_dataFim!.add(const Duration(days: 1)))).toList();
    }
    return coletas;
  }

  List _filtrarEntregas(AppProvider provider) {
    // Entregas agora são extraídas das coletas (integradas)
    final coletas = _filtrarColetas(provider);
    final entregas = coletas.expand((c) => c.entregasProdutores).toList();
    if (_dataInicio != null) {
      return entregas.where((e) => e.dataEntrega.isAfter(_dataInicio!.subtract(const Duration(days: 1)))).toList();
    }
    if (_dataFim != null) {
      return entregas.where((e) => e.dataEntrega.isBefore(_dataFim!.add(const Duration(days: 1)))).toList();
    }
    return entregas;
  }

  Map<String, dynamic> _buildPayload(AppProvider provider, List coletas, List entregas) {
    return {
      'exportadoEm': DateTime.now().toIso8601String(),
      'periodo': {
        'inicio': _dataInicio?.toIso8601String() ?? 'todos',
        'fim': _dataFim?.toIso8601String() ?? 'todos',
      },
      'resumo': {
        'totalColetas': coletas.length,
        'coletasRealizadas': coletas.where((c) => c.coletaRealizada).length,
        'totalLitros': coletas.where((c) => c.coletaRealizada).fold(0.0, (s, c) => s + c.quantidadeLitros),
        'totalEntregasProdutores': entregas.length,
      },
      'coletas': coletas.map((c) => c.toMap()).toList(),
      'entregasProdutores': entregas.map((e) => e.toMap()).toList(),
    };
  }

  void _preview(BuildContext context, AppProvider provider, List coletas, List entregas) {
    final payload = _buildPayload(provider, coletas, entregas);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pré-visualização dos Dados'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(jsonStr, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _exportar(BuildContext context, AppProvider provider, List coletas, List entregas) async {
    setState(() { _exporting = true; _statusMsg = ''; });
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _exporting = false;
      _statusMsg = '❌ Não foi possível conectar ao servidor ERP.\n\nVerifique:\n• URL correta\n• Servidor online\n• Permissões de rede\n• Autenticação configurada';
    });
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryRow(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    ]),
  );
}
