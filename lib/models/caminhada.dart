class Caminhada {
  String id;
  String titulo;

  double inicioLat;
  double inicioLng;

  double destinoLat;
  double destinoLng;

  double distancia;
  double calorias;
  int tempoMinutos;

  List<List<double>> rota;

  String? foto;

  Caminhada({
    required this.id,
    required this.titulo,
    required this.inicioLat,
    required this.inicioLng,
    required this.destinoLat,
    required this.destinoLng,
    required this.distancia,
    required this.calorias,
    required this.tempoMinutos,
    required this.rota,
    this.foto,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'inicioLat': inicioLat,
      'inicioLng': inicioLng,
      'destinoLat': destinoLat,
      'destinoLng': destinoLng,
      'distancia': distancia,
      'calorias': calorias,
      'tempoMinutos': tempoMinutos,
      'rota': rota,
      'foto': foto,
    };
  }

  factory Caminhada.fromMap(Map<String, dynamic> map) {
    return Caminhada(
      id: map['id'],
      titulo: map['titulo'],
      inicioLat: map['inicioLat'],
      inicioLng: map['inicioLng'],
      destinoLat: map['destinoLat'],
      destinoLng: map['destinoLng'],
      distancia: map['distancia'],
      calorias: map['calorias'],
      tempoMinutos: map['tempoMinutos'],
      rota: (map['rota'] as List)
          .map<List<double>>(
            (ponto) => [
              (ponto[0] as num).toDouble(),
              (ponto[1] as num).toDouble(),
            ],
          )
          .toList(),
      foto: map['foto'],
    );
  }
}
