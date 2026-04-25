// ============================================================
// MODELOS DE DADOS - MILK COLLECTOR
// ============================================================

import 'dart:convert';

// ---- PRODUTOR ----
class Produtor {
  final String id;
  String nome;
  String codigo;
  String cpfCnpj;
  String telefone;
  String municipio;
  String estado;
  bool ativo;
  DateTime dataCadastro;

  Produtor({
    required this.id,
    required this.nome,
    required this.codigo,
    this.cpfCnpj = '',
    this.telefone = '',
    this.municipio = '',
    this.estado = '',
    this.ativo = true,
    required this.dataCadastro,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'codigo': codigo,
        'cpfCnpj': cpfCnpj,
        'telefone': telefone,
        'municipio': municipio,
        'estado': estado,
        'ativo': ativo,
        'dataCadastro': dataCadastro.toIso8601String(),
      };

  factory Produtor.fromMap(Map<String, dynamic> map) => Produtor(
        id: map['id'],
        nome: map['nome'],
        codigo: map['codigo'],
        cpfCnpj: map['cpfCnpj'] ?? '',
        telefone: map['telefone'] ?? '',
        municipio: map['municipio'] ?? '',
        estado: map['estado'] ?? '',
        ativo: map['ativo'] ?? true,
        dataCadastro: DateTime.parse(map['dataCadastro']),
      );

  String toJson() => jsonEncode(toMap());
  factory Produtor.fromJson(String source) =>
      Produtor.fromMap(jsonDecode(source));
}

// ---- TANQUE ----
enum TipoTanque { individual, coletivo }

class Tanque {
  final String id;
  String nome;
  String codigo;
  TipoTanque tipo;
  double capacidade;
  String localizacao;
  double? latitude;
  double? longitude;
  List<String> produtorIds; // produtores vinculados
  bool ativo;
  DateTime dataCadastro;

  Tanque({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.tipo,
    required this.capacidade,
    this.localizacao = '',
    this.latitude,
    this.longitude,
    List<String>? produtorIds,
    this.ativo = true,
    required this.dataCadastro,
  }) : produtorIds = produtorIds ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'codigo': codigo,
        'tipo': tipo.name,
        'capacidade': capacidade,
        'localizacao': localizacao,
        'latitude': latitude,
        'longitude': longitude,
        'produtorIds': produtorIds,
        'ativo': ativo,
        'dataCadastro': dataCadastro.toIso8601String(),
      };

  factory Tanque.fromMap(Map<String, dynamic> map) => Tanque(
        id: map['id'],
        nome: map['nome'],
        codigo: map['codigo'],
        tipo: TipoTanque.values.firstWhere((e) => e.name == map['tipo'],
            orElse: () => TipoTanque.individual),
        capacidade: (map['capacidade'] ?? 0).toDouble(),
        localizacao: map['localizacao'] ?? '',
        latitude: map['latitude']?.toDouble(),
        longitude: map['longitude']?.toDouble(),
        produtorIds: List<String>.from(map['produtorIds'] ?? []),
        ativo: map['ativo'] ?? true,
        dataCadastro: DateTime.parse(map['dataCadastro']),
      );
}

// ---- CAMINHÃO ----
enum NumeroCompartimentos { tres, quatro }

class Caminhao {
  final String id;
  String placa;
  String modelo;
  String marca;
  NumeroCompartimentos compartimentos;
  List<double> capacidadeCompartimentos;
  bool ativo;
  DateTime dataCadastro;

  Caminhao({
    required this.id,
    required this.placa,
    required this.modelo,
    required this.marca,
    required this.compartimentos,
    List<double>? capacidadeCompartimentos,
    this.ativo = true,
    required this.dataCadastro,
  }) : capacidadeCompartimentos =
            capacidadeCompartimentos ??
                (compartimentos == NumeroCompartimentos.tres
                    ? [0, 0, 0]
                    : [0, 0, 0, 0]);

  int get totalCompartimentos =>
      compartimentos == NumeroCompartimentos.tres ? 3 : 4;

  Map<String, dynamic> toMap() => {
        'id': id,
        'placa': placa,
        'modelo': modelo,
        'marca': marca,
        'compartimentos': compartimentos.name,
        'capacidadeCompartimentos': capacidadeCompartimentos,
        'ativo': ativo,
        'dataCadastro': dataCadastro.toIso8601String(),
      };

  factory Caminhao.fromMap(Map<String, dynamic> map) => Caminhao(
        id: map['id'],
        placa: map['placa'],
        modelo: map['modelo'],
        marca: map['marca'],
        compartimentos: NumeroCompartimentos.values.firstWhere(
            (e) => e.name == map['compartimentos'],
            orElse: () => NumeroCompartimentos.tres),
        capacidadeCompartimentos:
            List<double>.from((map['capacidadeCompartimentos'] ?? [])
                .map((e) => (e as num).toDouble())),
        ativo: map['ativo'] ?? true,
        dataCadastro: DateTime.parse(map['dataCadastro']),
      );
}

// ---- CARRETEIRO ----
class Carreteiro {
  final String id;
  String nome;
  String cpf;
  String cnh;
  String telefone;
  String caminhaoId; // caminhão padrão vinculado ao carreteiro
  bool ativo;
  DateTime dataCadastro;

  Carreteiro({
    required this.id,
    required this.nome,
    this.cpf = '',
    this.cnh = '',
    this.telefone = '',
    this.caminhaoId = '',
    this.ativo = true,
    required this.dataCadastro,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'cpf': cpf,
        'cnh': cnh,
        'telefone': telefone,
        'caminhaoId': caminhaoId,
        'ativo': ativo,
        'dataCadastro': dataCadastro.toIso8601String(),
      };

  factory Carreteiro.fromMap(Map<String, dynamic> map) => Carreteiro(
        id: map['id'],
        nome: map['nome'],
        cpf: map['cpf'] ?? '',
        cnh: map['cnh'] ?? '',
        telefone: map['telefone'] ?? '',
        caminhaoId: map['caminhaoId'] ?? '',
        ativo: map['ativo'] ?? true,
        dataCadastro: DateTime.parse(map['dataCadastro']),
      );
}

// ---- ROTA ----
class Rota {
  final String id;
  String nome;
  String codigo;
  String carreiroId;
  String caminhaoId;
  List<String> tanqueIds; // tanques na ordem de coleta
  String descricao;
  bool ativo;
  DateTime dataCadastro;

  Rota({
    required this.id,
    required this.nome,
    required this.codigo,
    this.carreiroId = '',
    this.caminhaoId = '',
    List<String>? tanqueIds,
    this.descricao = '',
    this.ativo = true,
    required this.dataCadastro,
  }) : tanqueIds = tanqueIds ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'nome': nome,
        'codigo': codigo,
        'carreiroId': carreiroId,
        'caminhaoId': caminhaoId,
        'tanqueIds': tanqueIds,
        'descricao': descricao,
        'ativo': ativo,
        'dataCadastro': dataCadastro.toIso8601String(),
      };

  factory Rota.fromMap(Map<String, dynamic> map) => Rota(
        id: map['id'],
        nome: map['nome'],
        codigo: map['codigo'],
        carreiroId: map['carreiroId'] ?? '',
        caminhaoId: map['caminhaoId'] ?? '',
        tanqueIds: List<String>.from(map['tanqueIds'] ?? []),
        descricao: map['descricao'] ?? '',
        ativo: map['ativo'] ?? true,
        dataCadastro: DateTime.parse(map['dataCadastro']),
      );
}

// ---- RESULTADO ALIZAROL ----
enum ResultadoAlizarol { normal, suspeito, acido, alcalino }

extension ResultadoAlizarolExt on ResultadoAlizarol {
  String get label {
    switch (this) {
      case ResultadoAlizarol.normal:
        return 'Normal';
      case ResultadoAlizarol.suspeito:
        return 'Suspeito';
      case ResultadoAlizarol.acido:
        return 'Ácido';
      case ResultadoAlizarol.alcalino:
        return 'Alcalino';
    }
  }

  String get emoji {
    switch (this) {
      case ResultadoAlizarol.normal:
        return '✅';
      case ResultadoAlizarol.suspeito:
        return '⚠️';
      case ResultadoAlizarol.acido:
        return '❌';
      case ResultadoAlizarol.alcalino:
        return '❌';
    }
  }
}

// ---- COLETA DE LEITE ----
class ColetaLeite {
  final String id;
  String rotaId;
  String tanqueId;
  String caminhaoId;
  String carreiroId;
  DateTime dataHoraColeta;
  double? latitude;
  double? longitude;
  double quantidadeLitros;
  double valorRegua;
  double temperatura;
  ResultadoAlizarol alizarol;
  int compartimentoCaminhao; // 1, 2, 3 ou 4
  String observacoesQualidade;
  String motivoNaoColeta; // se não coletou
  bool coletaRealizada;
  List<EntregaProdutor> entregasProdutores;
  DateTime dataCadastro;

  ColetaLeite({
    required this.id,
    required this.rotaId,
    required this.tanqueId,
    required this.caminhaoId,
    required this.carreiroId,
    required this.dataHoraColeta,
    this.latitude,
    this.longitude,
    this.quantidadeLitros = 0,
    this.valorRegua = 0,
    this.temperatura = 0,
    this.alizarol = ResultadoAlizarol.normal,
    this.compartimentoCaminhao = 1,
    this.observacoesQualidade = '',
    this.motivoNaoColeta = '',
    this.coletaRealizada = true,
    List<EntregaProdutor>? entregasProdutores,
    required this.dataCadastro,
  }) : entregasProdutores = entregasProdutores ?? [];

  Map<String, dynamic> toMap() => {
        'id': id,
        'rotaId': rotaId,
        'tanqueId': tanqueId,
        'caminhaoId': caminhaoId,
        'carreiroId': carreiroId,
        'dataHoraColeta': dataHoraColeta.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'quantidadeLitros': quantidadeLitros,
        'valorRegua': valorRegua,
        'temperatura': temperatura,
        'alizarol': alizarol.name,
        'compartimentoCaminhao': compartimentoCaminhao,
        'observacoesQualidade': observacoesQualidade,
        'motivoNaoColeta': motivoNaoColeta,
        'coletaRealizada': coletaRealizada,
        'entregasProdutores': entregasProdutores.map((e) => e.toMap()).toList(),
        'dataCadastro': dataCadastro.toIso8601String(),
      };

  factory ColetaLeite.fromMap(Map<String, dynamic> map) => ColetaLeite(
        id: map['id'],
        rotaId: map['rotaId'] ?? '',
        tanqueId: map['tanqueId'] ?? '',
        caminhaoId: map['caminhaoId'] ?? '',
        carreiroId: map['carreiroId'] ?? '',
        dataHoraColeta: DateTime.parse(map['dataHoraColeta']),
        latitude: map['latitude']?.toDouble(),
        longitude: map['longitude']?.toDouble(),
        quantidadeLitros: (map['quantidadeLitros'] ?? 0).toDouble(),
        valorRegua: (map['valorRegua'] ?? 0).toDouble(),
        temperatura: (map['temperatura'] ?? 0).toDouble(),
        alizarol: ResultadoAlizarol.values.firstWhere(
            (e) => e.name == map['alizarol'],
            orElse: () => ResultadoAlizarol.normal),
        compartimentoCaminhao: map['compartimentoCaminhao'] ?? 1,
        observacoesQualidade: map['observacoesQualidade'] ?? '',
        motivoNaoColeta: map['motivoNaoColeta'] ?? '',
        coletaRealizada: map['coletaRealizada'] ?? true,
        entregasProdutores: (map['entregasProdutores'] as List? ?? [])
            .map((e) => EntregaProdutor.fromMap(e))
            .toList(),
        dataCadastro: DateTime.parse(map['dataCadastro']),
      );
}

// ---- ENTREGA DO PRODUTOR NO TANQUE ----
class EntregaProdutor {
  final String id;
  String produtorId;
  String tanqueId;
  DateTime dataEntrega;
  double quantidadeLitros;
  String observacao;

  EntregaProdutor({
    required this.id,
    required this.produtorId,
    required this.tanqueId,
    required this.dataEntrega,
    required this.quantidadeLitros,
    this.observacao = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'produtorId': produtorId,
        'tanqueId': tanqueId,
        'dataEntrega': dataEntrega.toIso8601String(),
        'quantidadeLitros': quantidadeLitros,
        'observacao': observacao,
      };

  factory EntregaProdutor.fromMap(Map<String, dynamic> map) => EntregaProdutor(
        id: map['id'],
        produtorId: map['produtorId'],
        tanqueId: map['tanqueId'],
        dataEntrega: DateTime.parse(map['dataEntrega']),
        quantidadeLitros: (map['quantidadeLitros'] ?? 0).toDouble(),
        observacao: map['observacao'] ?? '',
      );
}

// ---- DADOS DA ROTA DO DIA (para recebimento externo) ----
class RotaDia {
  final String id;
  String rotaId;
  String nomeRota;
  DateTime data;
  String carreiroId;
  String caminhaoId;
  List<TanqueRota> tanques;
  String status; // pendente, em_andamento, concluida
  DateTime? horaInicio;
  DateTime? horaFim;
  String observacoes;
  DateTime dataCriacao;

  RotaDia({
    required this.id,
    required this.rotaId,
    required this.nomeRota,
    required this.data,
    required this.carreiroId,
    required this.caminhaoId,
    List<TanqueRota>? tanques,
    this.status = 'pendente',
    this.horaInicio,
    this.horaFim,
    this.observacoes = '',
    required this.dataCriacao,
  }) : tanques = tanques ?? [];

  bool get emAndamento => status == 'em_andamento';
  bool get concluida => status == 'concluida';
  bool get pendente => status == 'pendente';

  Map<String, dynamic> toMap() => {
        'id': id,
        'rotaId': rotaId,
        'nomeRota': nomeRota,
        'data': data.toIso8601String(),
        'carreiroId': carreiroId,
        'caminhaoId': caminhaoId,
        'tanques': tanques.map((t) => t.toMap()).toList(),
        'status': status,
        'horaInicio': horaInicio?.toIso8601String(),
        'horaFim': horaFim?.toIso8601String(),
        'observacoes': observacoes,
        'dataCriacao': dataCriacao.toIso8601String(),
      };

  factory RotaDia.fromMap(Map<String, dynamic> map) => RotaDia(
        id: map['id'],
        rotaId: map['rotaId'] ?? '',
        nomeRota: map['nomeRota'] ?? '',
        data: DateTime.parse(map['data']),
        carreiroId: map['carreiroId'] ?? '',
        caminhaoId: map['caminhaoId'] ?? '',
        tanques: (map['tanques'] as List? ?? [])
            .map((t) => TanqueRota.fromMap(t))
            .toList(),
        status: map['status'] ?? 'pendente',
        horaInicio: map['horaInicio'] != null
            ? DateTime.parse(map['horaInicio'])
            : null,
        horaFim:
            map['horaFim'] != null ? DateTime.parse(map['horaFim']) : null,
        observacoes: map['observacoes'] ?? '',
        dataCriacao: DateTime.parse(map['dataCriacao']),
      );
}

class TanqueRota {
  String tanqueId;
  String nomeTanque;
  int ordem;
  List<String> produtorIds;

  TanqueRota({
    required this.tanqueId,
    required this.nomeTanque,
    required this.ordem,
    List<String>? produtorIds,
  }) : produtorIds = produtorIds ?? [];

  Map<String, dynamic> toMap() => {
        'tanqueId': tanqueId,
        'nomeTanque': nomeTanque,
        'ordem': ordem,
        'produtorIds': produtorIds,
      };

  factory TanqueRota.fromMap(Map<String, dynamic> map) => TanqueRota(
        tanqueId: map['tanqueId'] ?? '',
        nomeTanque: map['nomeTanque'] ?? '',
        ordem: map['ordem'] ?? 0,
        produtorIds: List<String>.from(map['produtorIds'] ?? []),
      );
}
