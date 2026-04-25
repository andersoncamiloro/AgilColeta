// ============================================================
// SEED SERVICE — Dados de exemplo para agilizar o uso do app
// Carregado apenas na primeira execução (flag no SharedPreferences)
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'storage_service.dart';

class SeedService {
  static const _seedKey = 'seed_loaded_v1';

  // IDs fixos para permitir vínculos consistentes
  static const _c1 = 'carr-001';
  static const _c2 = 'carr-002';

  static const _cam1 = 'cam-001';
  static const _cam2 = 'cam-002';

  static const _p1 = 'prod-001';
  static const _p2 = 'prod-002';
  static const _p3 = 'prod-003';
  static const _p4 = 'prod-004';
  static const _p5 = 'prod-005';
  static const _p6 = 'prod-006';
  static const _p7 = 'prod-007';
  static const _p8 = 'prod-008';
  static const _p9 = 'prod-009';
  static const _p10 = 'prod-010';

  static const _t1 = 'tanq-001';
  static const _t2 = 'tanq-002';
  static const _t3 = 'tanq-003';
  static const _t4 = 'tanq-004';
  static const _t5 = 'tanq-005';

  static const _r1 = 'rota-001';
  static const _r2 = 'rota-002';

  /// Verifica se já foi executado e, se não, insere os dados de exemplo.
  static Future<void> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seedKey) == true) return;

    final s = StorageService.instance;
    final now = DateTime.now();

    // ── 1. CARRETEIROS ─────────────────────────────────────────
    final carreteiros = [
      Carreteiro(
        id: _c1,
        nome: 'João Carlos Silveira',
        cpf: '123.456.789-01',
        cnh: '12345678901',
        telefone: '(47) 99101-2233',
        caminhaoId: _cam1, // VW Constellation 4 bocas
        ativo: true,
        dataCadastro: now,
      ),
      Carreteiro(
        id: _c2,
        nome: 'Pedro Antônio Luz',
        cpf: '987.654.321-00',
        cnh: '98765432100',
        telefone: '(47) 99202-4455',
        caminhaoId: _cam2, // Scania Atron 3 bocas
        ativo: true,
        dataCadastro: now,
      ),
    ];
    for (final c in carreteiros) {
      await s.saveCarreteiro(c);
    }

    // ── 2. CAMINHÕES ────────────────────────────────────────────
    final caminhoes = [
      Caminhao(
        id: _cam1,
        placa: 'ABC-1D23',
        modelo: 'Constellation 24.280',
        marca: 'Volkswagen',
        compartimentos: NumeroCompartimentos.quatro,
        capacidadeCompartimentos: [4000, 4000, 4000, 4000],
        ativo: true,
        dataCadastro: now,
      ),
      Caminhao(
        id: _cam2,
        placa: 'DEF-4G56',
        modelo: 'Atron 2430',
        marca: 'Scania',
        compartimentos: NumeroCompartimentos.tres,
        capacidadeCompartimentos: [5000, 5000, 5000],
        ativo: true,
        dataCadastro: now,
      ),
    ];
    for (final c in caminhoes) {
      await s.saveCaminhao(c);
    }

    // ── 3. PRODUTORES ───────────────────────────────────────────
    final produtores = [
      // Rota Norte
      Produtor(id: _p1, nome: 'Alfredo Bauer',       codigo: 'P001', cpfCnpj: '111.222.333-44', telefone: '(47) 99301-0001', municipio: 'Timbó',       estado: 'SC', dataCadastro: now),
      Produtor(id: _p2, nome: 'Bernardo Kramer',     codigo: 'P002', cpfCnpj: '222.333.444-55', telefone: '(47) 99302-0002', municipio: 'Rodeio',      estado: 'SC', dataCadastro: now),
      Produtor(id: _p3, nome: 'Cláudia Weiss',       codigo: 'P003', cpfCnpj: '333.444.555-66', telefone: '(47) 99303-0003', municipio: 'Ascurra',     estado: 'SC', dataCadastro: now),
      Produtor(id: _p4, nome: 'Dietmar Schmidt',     codigo: 'P004', cpfCnpj: '444.555.666-77', telefone: '(47) 99304-0004', municipio: 'Indaial',     estado: 'SC', dataCadastro: now),
      Produtor(id: _p5, nome: 'Elza Müller',         codigo: 'P005', cpfCnpj: '555.666.777-88', telefone: '(47) 99305-0005', municipio: 'Benedito Novo',estado: 'SC', dataCadastro: now),
      // Rota Sul
      Produtor(id: _p6,  nome: 'Fabio Koerich',     codigo: 'P006', cpfCnpj: '666.777.888-99', telefone: '(47) 99306-0006', municipio: 'Apiúna',      estado: 'SC', dataCadastro: now),
      Produtor(id: _p7,  nome: 'Graça Petry',        codigo: 'P007', cpfCnpj: '777.888.999-00', telefone: '(47) 99307-0007', municipio: 'Ibirama',     estado: 'SC', dataCadastro: now),
      Produtor(id: _p8,  nome: 'Helmut Fischer',     codigo: 'P008', cpfCnpj: '888.999.000-11', telefone: '(47) 99308-0008', municipio: 'Presidente Getúlio', estado: 'SC', dataCadastro: now),
      Produtor(id: _p9,  nome: 'Irene Zimmermann',   codigo: 'P009', cpfCnpj: '999.000.111-22', telefone: '(47) 99309-0009', municipio: 'Lontras',     estado: 'SC', dataCadastro: now),
      Produtor(id: _p10, nome: 'Jonas Brandt',        codigo: 'P010', cpfCnpj: '000.111.222-33', telefone: '(47) 99310-0010', municipio: 'Rio do Sul',  estado: 'SC', dataCadastro: now),
    ];
    for (final p in produtores) {
      await s.saveProdutor(p);
    }

    // ── 4. TANQUES ──────────────────────────────────────────────
    // Rota Norte: 3 tanques (2 coletivos + 1 individual)
    // Rota Sul  : 2 tanques (1 coletivo + 1 individual)
    final tanques = [
      Tanque(
        id: _t1,
        nome: 'Tanque Bauer & Kramer',
        codigo: 'T001',
        tipo: TipoTanque.coletivo,
        capacidade: 2000,
        localizacao: 'Estrada Bauer, km 3 — Timbó/SC',
        latitude: -26.8270,
        longitude: -49.2700,
        produtorIds: [_p1, _p2],
        dataCadastro: now,
      ),
      Tanque(
        id: _t2,
        nome: 'Tanque Família Weiss',
        codigo: 'T002',
        tipo: TipoTanque.individual,
        capacidade: 1000,
        localizacao: 'Linha Weiss, s/n — Ascurra/SC',
        latitude: -26.8500,
        longitude: -49.3100,
        produtorIds: [_p3],
        dataCadastro: now,
      ),
      Tanque(
        id: _t3,
        nome: 'Tanque Schmidt & Müller',
        codigo: 'T003',
        tipo: TipoTanque.coletivo,
        capacidade: 3000,
        localizacao: 'Estrada Indaial, km 7 — Benedito Novo/SC',
        latitude: -26.7800,
        longitude: -49.3700,
        produtorIds: [_p4, _p5],
        dataCadastro: now,
      ),
      Tanque(
        id: _t4,
        nome: 'Tanque Koerich & Petry',
        codigo: 'T004',
        tipo: TipoTanque.coletivo,
        capacidade: 2500,
        localizacao: 'Linha Colonial, km 5 — Apiúna/SC',
        latitude: -27.0300,
        longitude: -49.3900,
        produtorIds: [_p6, _p7],
        dataCadastro: now,
      ),
      Tanque(
        id: _t5,
        nome: 'Tanque Fischer & Zimm.',
        codigo: 'T005',
        tipo: TipoTanque.coletivo,
        capacidade: 4000,
        localizacao: 'Estrada Rio do Sul, km 2 — Lontras/SC',
        latitude: -27.1600,
        longitude: -49.5300,
        produtorIds: [_p8, _p9, _p10],
        dataCadastro: now,
      ),
    ];
    for (final t in tanques) {
      await s.saveTanque(t);
    }

    // ── 5. ROTAS ────────────────────────────────────────────────
    final rotas = [
      Rota(
        id: _r1,
        nome: 'Rota Norte — Timbó/Ascurra/Benedito',
        codigo: 'R001',
        carreiroId: _c1,
        caminhaoId: _cam1,
        tanqueIds: [_t1, _t2, _t3],
        descricao: 'Saída às 05h — percurso aproximado 45 km',
        ativo: true,
        dataCadastro: now,
      ),
      Rota(
        id: _r2,
        nome: 'Rota Sul — Apiúna/Lontras/Rio do Sul',
        codigo: 'R002',
        carreiroId: _c2,
        caminhaoId: _cam2,
        tanqueIds: [_t4, _t5],
        descricao: 'Saída às 05h30 — percurso aproximado 60 km',
        ativo: true,
        dataCadastro: now,
      ),
    ];
    for (final r in rotas) {
      await s.saveRota(r);
    }

    // ── Marca seed como executado ───────────────────────────────
    await prefs.setBool(_seedKey, true);
  }

  /// Permite recarregar os dados de exemplo (usado no botão "Restaurar dados demo")
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_seedKey);
    await runIfNeeded();
  }
}
