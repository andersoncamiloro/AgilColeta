import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  List<Produtor> _produtores = [];
  List<Tanque> _tanques = [];
  List<Caminhao> _caminhoes = [];
  List<Carreteiro> _carreteiros = [];
  List<Rota> _rotas = [];
  List<ColetaLeite> _coletas = [];
  List<EntregaProdutor> _entregas = [];
  List<RotaDia> _rotasDia = [];
  bool _loading = false;

  List<Produtor> get produtores => _produtores;
  List<Tanque> get tanques => _tanques;
  List<Caminhao> get caminhoes => _caminhoes;
  List<Carreteiro> get carreteiros => _carreteiros;
  List<Rota> get rotas => _rotas;
  List<ColetaLeite> get coletas => _coletas;
  List<EntregaProdutor> get entregas => _entregas;
  List<RotaDia> get rotasDia => _rotasDia;
  bool get loading => _loading;

  final _storage = StorageService.instance;

  Future<void> loadAll() async {
    _loading = true;
    notifyListeners();
    _produtores = await _storage.getProdutores();
    _tanques = await _storage.getTanques();
    _caminhoes = await _storage.getCaminhoes();
    _carreteiros = await _storage.getCarreteiros();
    _rotas = await _storage.getRotas();
    _coletas = await _storage.getColetas();
    _entregas = await _storage.getEntregas();
    _rotasDia = await _storage.getRotasDia();
    _loading = false;
    notifyListeners();
  }

  // ---- PRODUTORES ----
  Future<void> addProdutor(Produtor p) async {
    await _storage.saveProdutor(p);
    _produtores = await _storage.getProdutores();
    notifyListeners();
  }

  Future<void> updateProdutor(Produtor p) async {
    await _storage.saveProdutor(p);
    _produtores = await _storage.getProdutores();
    notifyListeners();
  }

  Future<void> deleteProdutor(String id) async {
    await _storage.deleteProdutor(id);
    _produtores = await _storage.getProdutores();
    notifyListeners();
  }

  Produtor? getProdutorById(String id) {
    try {
      return _produtores.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---- TANQUES ----
  Future<void> addTanque(Tanque t) async {
    await _storage.saveTanque(t);
    _tanques = await _storage.getTanques();
    notifyListeners();
  }

  Future<void> updateTanque(Tanque t) async {
    await _storage.saveTanque(t);
    _tanques = await _storage.getTanques();
    notifyListeners();
  }

  Future<void> deleteTanque(String id) async {
    await _storage.deleteTanque(id);
    _tanques = await _storage.getTanques();
    notifyListeners();
  }

  Tanque? getTanqueById(String id) {
    try {
      return _tanques.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Produtor> getProdutoresDeTanque(String tanqueId) {
    final tanque = getTanqueById(tanqueId);
    if (tanque == null) return [];
    return _produtores
        .where((p) => tanque.produtorIds.contains(p.id))
        .toList();
  }

  // ---- CAMINHÕES ----
  Future<void> addCaminhao(Caminhao c) async {
    await _storage.saveCaminhao(c);
    _caminhoes = await _storage.getCaminhoes();
    notifyListeners();
  }

  Future<void> updateCaminhao(Caminhao c) async {
    await _storage.saveCaminhao(c);
    _caminhoes = await _storage.getCaminhoes();
    notifyListeners();
  }

  Future<void> deleteCaminhao(String id) async {
    await _storage.deleteCaminhao(id);
    _caminhoes = await _storage.getCaminhoes();
    notifyListeners();
  }

  Caminhao? getCaminhaoById(String id) {
    try {
      return _caminhoes.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---- CARRETEIROS ----
  Future<void> addCarreteiro(Carreteiro c) async {
    await _storage.saveCarreteiro(c);
    _carreteiros = await _storage.getCarreteiros();
    notifyListeners();
  }

  Future<void> updateCarreteiro(Carreteiro c) async {
    await _storage.saveCarreteiro(c);
    _carreteiros = await _storage.getCarreteiros();
    notifyListeners();
  }

  Future<void> deleteCarreteiro(String id) async {
    await _storage.deleteCarreteiro(id);
    _carreteiros = await _storage.getCarreteiros();
    notifyListeners();
  }

  Carreteiro? getCarreiroById(String id) {
    try {
      return _carreteiros.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---- ROTAS ----
  Future<void> addRota(Rota r) async {
    await _storage.saveRota(r);
    _rotas = await _storage.getRotas();
    notifyListeners();
  }

  Future<void> updateRota(Rota r) async {
    await _storage.saveRota(r);
    _rotas = await _storage.getRotas();
    notifyListeners();
  }

  Future<void> deleteRota(String id) async {
    await _storage.deleteRota(id);
    _rotas = await _storage.getRotas();
    notifyListeners();
  }

  Rota? getRotaById(String id) {
    try {
      return _rotas.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---- COLETAS ----
  Future<void> addColeta(ColetaLeite c) async {
    await _storage.saveColeta(c);
    _coletas = await _storage.getColetas();
    notifyListeners();
  }

  Future<void> updateColeta(ColetaLeite c) async {
    await _storage.saveColeta(c);
    _coletas = await _storage.getColetas();
    notifyListeners();
  }

  Future<void> deleteColeta(String id) async {
    await _storage.deleteColeta(id);
    _coletas = await _storage.getColetas();
    notifyListeners();
  }

  List<ColetaLeite> getColetasDaRota(String rotaId) {
    return _coletas.where((c) => c.rotaId == rotaId).toList();
  }

  List<ColetaLeite> getColetasDeHoje() {
    final hoje = DateTime.now();
    return _coletas.where((c) {
      final d = c.dataHoraColeta;
      return d.year == hoje.year && d.month == hoje.month && d.day == hoje.day;
    }).toList();
  }

  double getTotalLitrosHoje() {
    return getColetasDeHoje()
        .where((c) => c.coletaRealizada)
        .fold(0, (sum, c) => sum + c.quantidadeLitros);
  }

  // ---- ENTREGAS ----
  Future<void> addEntrega(EntregaProdutor e) async {
    await _storage.saveEntrega(e);
    _entregas = await _storage.getEntregas();
    notifyListeners();
  }

  Future<void> updateEntrega(EntregaProdutor e) async {
    await _storage.saveEntrega(e);
    _entregas = await _storage.getEntregas();
    notifyListeners();
  }

  Future<void> deleteEntrega(String id) async {
    await _storage.deleteEntrega(id);
    _entregas = await _storage.getEntregas();
    notifyListeners();
  }

  List<EntregaProdutor> getEntregasDeTanque(String tanqueId) {
    return _entregas.where((e) => e.tanqueId == tanqueId).toList();
  }

  List<EntregaProdutor> getEntregasDeProdutor(String produtorId) {
    return _entregas.where((e) => e.produtorId == produtorId).toList();
  }

  // ── ENTREGAS INTEGRADAS NAS COLETAS ────────────────────────
  // Extrai todas as entregas de produtores que estão dentro das coletas
  List<EntregaProdutor> getEntregasIntegradas() {
    return _coletas.expand((c) => c.entregasProdutores).toList();
  }

  // Retorna as entregas de um produtor específico dentro de todas as coletas
  List<EntregaProdutor> getEntregasIntegadasDeProdutor(String produtorId) {
    return _coletas
        .expand((c) => c.entregasProdutores)
        .where((e) => e.produtorId == produtorId)
        .toList();
  }

  // Retorna as entregas de um tanque específico dentro de todas as coletas
  List<EntregaProdutor> getEntregasIntegadasDeTanque(String tanqueId) {
    return _coletas
        .where((c) => c.tanqueId == tanqueId)
        .expand((c) => c.entregasProdutores)
        .toList();
  }

  // Total de litros entregues por um produtor em um período
  double getTotalLitrosProdutor(String produtorId, {DateTime? inicio, DateTime? fim}) {
    return _coletas
        .expand((c) => c.entregasProdutores)
        .where((e) {
          if (e.produtorId != produtorId) return false;
          if (inicio != null && e.dataEntrega.isBefore(inicio)) return false;
          if (fim != null && e.dataEntrega.isAfter(fim)) return false;
          return true;
        })
        .fold(0.0, (sum, e) => sum + e.quantidadeLitros);
  }

  // ---- ROTAS DO DIA ----
  Future<void> addRotaDia(RotaDia r) async {
    await _storage.saveRotaDia(r);
    _rotasDia = await _storage.getRotasDia();
    notifyListeners();
  }

  Future<void> updateRotaDia(RotaDia r) async {
    await _storage.saveRotaDia(r);
    _rotasDia = await _storage.getRotasDia();
    notifyListeners();
  }

  Future<void> deleteRotaDia(String id) async {
    await _storage.deleteRotaDia(id);
    _rotasDia = await _storage.getRotasDia();
    notifyListeners();
  }

  RotaDia? getRotaDiaById(String id) {
    try {
      return _rotasDia.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  List<RotaDia> getRotasDiaHoje() {
    final hoje = DateTime.now();
    return _rotasDia.where((r) {
      return r.data.year == hoje.year &&
          r.data.month == hoje.month &&
          r.data.day == hoje.day;
    }).toList();
  }

  List<RotaDia> getRotasDiaEmAndamento() {
    return _rotasDia.where((r) => r.status == 'em_andamento').toList();
  }

  // ---- ESTATÍSTICAS ----
  Map<String, dynamic> getEstatisticas() {
    final hoje = DateTime.now();
    final coletasHoje = getColetasDeHoje();
    final totalHoje = getTotalLitrosHoje();

    final mesAtual = _coletas.where((c) {
      return c.dataHoraColeta.year == hoje.year &&
          c.dataHoraColeta.month == hoje.month;
    }).toList();

    final totalMes =
        mesAtual.where((c) => c.coletaRealizada).fold<double>(
              0,
              (sum, c) => sum + c.quantidadeLitros,
            );

    return {
      'totalLitrosHoje': totalHoje,
      'coletasHoje': coletasHoje.length,
      'totalLitrosMes': totalMes,
      'coletasMes': mesAtual.length,
      'totalProdutores': _produtores.where((p) => p.ativo).length,
      'totalTanques': _tanques.where((t) => t.ativo).length,
      'totalRotas': _rotas.where((r) => r.ativo).length,
    };
  }
}
