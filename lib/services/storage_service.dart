import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();
  StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw Exception('StorageService não inicializado');
    return _prefs!;
  }

  // ---- PRODUTORES ----
  Future<List<Produtor>> getProdutores() async {
    final jsonList = prefs.getStringList('produtores') ?? [];
    return jsonList.map((j) => Produtor.fromMap(jsonDecode(j))).toList();
  }

  Future<void> saveProdutores(List<Produtor> list) async {
    final jsonList = list.map((p) => jsonEncode(p.toMap())).toList();
    await prefs.setStringList('produtores', jsonList);
  }

  Future<void> saveProdutor(Produtor p) async {
    final list = await getProdutores();
    final idx = list.indexWhere((x) => x.id == p.id);
    if (idx >= 0) {
      list[idx] = p;
    } else {
      list.add(p);
    }
    await saveProdutores(list);
  }

  Future<void> deleteProdutor(String id) async {
    final list = await getProdutores();
    list.removeWhere((p) => p.id == id);
    await saveProdutores(list);
  }

  // ---- TANQUES ----
  Future<List<Tanque>> getTanques() async {
    final jsonList = prefs.getStringList('tanques') ?? [];
    return jsonList.map((j) => Tanque.fromMap(jsonDecode(j))).toList();
  }

  Future<void> saveTanques(List<Tanque> list) async {
    final jsonList = list.map((t) => jsonEncode(t.toMap())).toList();
    await prefs.setStringList('tanques', jsonList);
  }

  Future<void> saveTanque(Tanque t) async {
    final list = await getTanques();
    final idx = list.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      list[idx] = t;
    } else {
      list.add(t);
    }
    await saveTanques(list);
  }

  Future<void> deleteTanque(String id) async {
    final list = await getTanques();
    list.removeWhere((t) => t.id == id);
    await saveTanques(list);
  }

  // ---- CAMINHÕES ----
  Future<List<Caminhao>> getCaminhoes() async {
    final jsonList = prefs.getStringList('caminhoes') ?? [];
    return jsonList.map((j) => Caminhao.fromMap(jsonDecode(j))).toList();
  }

  Future<void> saveCaminhoes(List<Caminhao> list) async {
    final jsonList = list.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList('caminhoes', jsonList);
  }

  Future<void> saveCaminhao(Caminhao c) async {
    final list = await getCaminhoes();
    final idx = list.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      list[idx] = c;
    } else {
      list.add(c);
    }
    await saveCaminhoes(list);
  }

  Future<void> deleteCaminhao(String id) async {
    final list = await getCaminhoes();
    list.removeWhere((c) => c.id == id);
    await saveCaminhoes(list);
  }

  // ---- CARRETEIROS ----
  Future<List<Carreteiro>> getCarreteiros() async {
    final jsonList = prefs.getStringList('carreteiros') ?? [];
    return jsonList.map((j) => Carreteiro.fromMap(jsonDecode(j))).toList();
  }

  Future<void> saveCarreteiros(List<Carreteiro> list) async {
    final jsonList = list.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList('carreteiros', jsonList);
  }

  Future<void> saveCarreteiro(Carreteiro c) async {
    final list = await getCarreteiros();
    final idx = list.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      list[idx] = c;
    } else {
      list.add(c);
    }
    await saveCarreteiros(list);
  }

  Future<void> deleteCarreteiro(String id) async {
    final list = await getCarreteiros();
    list.removeWhere((c) => c.id == id);
    await saveCarreteiros(list);
  }

  // ---- ROTAS ----
  Future<List<Rota>> getRotas() async {
    final jsonList = prefs.getStringList('rotas') ?? [];
    return jsonList.map((j) => Rota.fromMap(jsonDecode(j))).toList();
  }

  Future<void> saveRotas(List<Rota> list) async {
    final jsonList = list.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList('rotas', jsonList);
  }

  Future<void> saveRota(Rota r) async {
    final list = await getRotas();
    final idx = list.indexWhere((x) => x.id == r.id);
    if (idx >= 0) {
      list[idx] = r;
    } else {
      list.add(r);
    }
    await saveRotas(list);
  }

  Future<void> deleteRota(String id) async {
    final list = await getRotas();
    list.removeWhere((r) => r.id == id);
    await saveRotas(list);
  }

  // ---- COLETAS ----
  Future<List<ColetaLeite>> getColetas() async {
    final jsonList = prefs.getStringList('coletas') ?? [];
    return jsonList.map((j) => ColetaLeite.fromMap(jsonDecode(j))).toList();
  }

  Future<void> saveColetas(List<ColetaLeite> list) async {
    final jsonList = list.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList('coletas', jsonList);
  }

  Future<void> saveColeta(ColetaLeite c) async {
    final list = await getColetas();
    final idx = list.indexWhere((x) => x.id == c.id);
    if (idx >= 0) {
      list[idx] = c;
    } else {
      list.add(c);
    }
    await saveColetas(list);
  }

  Future<void> deleteColeta(String id) async {
    final list = await getColetas();
    list.removeWhere((c) => c.id == id);
    await saveColetas(list);
  }

  // ---- ROTAS DO DIA ----
  Future<List<RotaDia>> getRotasDia() async {
    final jsonList = prefs.getStringList('rotasDia') ?? [];
    return jsonList.map((j) => RotaDia.fromMap(jsonDecode(j))).toList();
  }

  Future<void> saveRotasDia(List<RotaDia> list) async {
    final jsonList = list.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList('rotasDia', jsonList);
  }

  Future<void> saveRotaDia(RotaDia r) async {
    final list = await getRotasDia();
    final idx = list.indexWhere((x) => x.id == r.id);
    if (idx >= 0) {
      list[idx] = r;
    } else {
      list.add(r);
    }
    await saveRotasDia(list);
  }

  Future<void> deleteRotaDia(String id) async {
    final list = await getRotasDia();
    list.removeWhere((r) => r.id == id);
    await saveRotasDia(list);
  }

  // ---- ENTREGA PRODUTORES (standalone) ----
  Future<List<EntregaProdutor>> getEntregas() async {
    final jsonList = prefs.getStringList('entregas') ?? [];
    return jsonList.map((j) => EntregaProdutor.fromMap(jsonDecode(j))).toList();
  }

  Future<void> saveEntregas(List<EntregaProdutor> list) async {
    final jsonList = list.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('entregas', jsonList);
  }

  Future<void> saveEntrega(EntregaProdutor e) async {
    final list = await getEntregas();
    final idx = list.indexWhere((x) => x.id == e.id);
    if (idx >= 0) {
      list[idx] = e;
    } else {
      list.add(e);
    }
    await saveEntregas(list);
  }

  Future<void> deleteEntrega(String id) async {
    final list = await getEntregas();
    list.removeWhere((e) => e.id == id);
    await saveEntregas(list);
  }
}
