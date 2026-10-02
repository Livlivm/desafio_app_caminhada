import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/caminhada.dart';
import '../services/storage_service.dart';

class NovaCaminhada extends StatefulWidget {
  const NovaCaminhada({super.key});

  @override
  State<NovaCaminhada> createState() => _NovaCaminhadaState();
}

class _NovaCaminhadaState extends State<NovaCaminhada> {
  final MapController mapaController = MapController();

  LatLng? inicio;
  LatLng? destino;

  List<LatLng> pontosRota = [];

  double distancia = 0;
  double calorias = 0;
  int tempo = 0;

  bool carregando = true;
  bool calculandoRota = false;

  @override
  void initState() {
    super.initState();
    obterLocalizacao();
  }

  Future<void> obterLocalizacao() async {
    try {
      bool servicoAtivo = await Geolocator.isLocationServiceEnabled();

      if (!servicoAtivo) {
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permissao = await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        if (mounted) {
          _erro('Permissão de localização negada.');
        }
        return;
      }

      final posicao = await Geolocator.getCurrentPosition();

      if (!mounted) return;

      setState(() {
        inicio = LatLng(posicao.latitude, posicao.longitude);
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        carregando = false;

        inicio = const LatLng(-22.7088, -46.7647);
      });

      _erro(
        'Não foi possível obter sua localização. Usando uma posição aproximada.',
      );
    }
  }

  Future<void> selecionarDestino(TapPosition tapPosition, LatLng ponto) async {
    if (inicio == null || calculandoRota) {
      return;
    }

    setState(() {
      destino = ponto;
      calculandoRota = true;
      pontosRota = [];
    });

    await calcularRota();

    if (!mounted) return;

    setState(() {
      calculandoRota = false;
    });
  }

  Future<void> calcularRota() async {
    if (inicio == null || destino == null) return;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/foot/'
        '${inicio!.longitude},${inicio!.latitude};'
        '${destino!.longitude},${destino!.latitude}'
        '?overview=full&geometries=geojson',
      );

      final resposta = await http.get(url);

      if (resposta.statusCode != 200) {
        throw Exception();
      }

      final dados = jsonDecode(resposta.body);

      if (dados['routes'] == null || dados['routes'].isEmpty) {
        throw Exception();
      }

      final rota = dados['routes'][0];

      final distanciaMetros = (rota['distance'] as num).toDouble();

      final duracaoSegundos = (rota['duration'] as num).toDouble();

      final coordenadas = rota['geometry']['coordinates'] as List;

      final pontos = coordenadas.map<LatLng>((ponto) {
        return LatLng(
          (ponto[1] as num).toDouble(),
          (ponto[0] as num).toDouble(),
        );
      }).toList();

      setState(() {
        pontosRota = pontos;

        distancia = distanciaMetros / 1000;

        tempo = (duracaoSegundos / 60).ceil();

        calorias = distancia * 60;
      });
    } catch (e) {
      final distanciaMetros = Geolocator.distanceBetween(
        inicio!.latitude,
        inicio!.longitude,
        destino!.latitude,
        destino!.longitude,
      );

      final distanciaKm = distanciaMetros / 1000;

      setState(() {
        pontosRota = [inicio!, destino!];

        distancia = distanciaKm;
        tempo = (distanciaKm / 5 * 60).ceil();
        calorias = distanciaKm * 60;
      });

      _erro(
        'Não foi possível traçar a rota pela internet. Foi usada uma estimativa.',
      );
    }
  }

  Future<void> salvar() async {
    if (destino == null || distancia <= 0) {
      _erro('Selecione um destino no mapa primeiro.');
      return;
    }

    final controller = TextEditingController();

    final titulo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Salvar caminhada'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Título',
              hintText: 'Ex: Caminhada da manhã',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (titulo == null || titulo.isEmpty) {
      return;
    }

    final caminhada = Caminhada(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: titulo,
      inicioLat: inicio!.latitude,
      inicioLng: inicio!.longitude,
      destinoLat: destino!.latitude,
      destinoLng: destino!.longitude,
      distancia: distancia,
      calorias: calorias,
      tempoMinutos: tempo,
      rota: pontosRota
          .map((ponto) => [ponto.latitude, ponto.longitude])
          .toList(),
    );

    await StorageService.adicionarCaminhada(caminhada);

    if (!mounted) return;

    Navigator.pop(context);
  }

  void _erro(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    if (carregando || inicio == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nova caminhada')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapaController,
            options: MapOptions(
              initialCenter: inicio!,
              initialZoom: 15,
              onTap: selecionarDestino,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.caminhadas_app',
              ),

              if (pontosRota.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pontosRota,
                      strokeWidth: 5,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: inicio!,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 35,
                    ),
                  ),

                  if (destino != null)
                    Marker(
                      point: destino!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Toque no mapa para escolher o destino.'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (calculandoRota)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 15),
                      Text('Calculando rota...'),
                    ],
                  ),
                ),
              ),
            ),

          if (destino != null && !calculandoRota)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _painelInformacoes(),
            ),
        ],
      ),
    );
  }

  Widget _painelInformacoes() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 25),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: const [BoxShadow(blurRadius: 15, color: Colors.black26)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _dado(
                Icons.straighten,
                '${distancia.toStringAsFixed(2)} km',
                'Distância',
              ),
              _dado(
                Icons.local_fire_department,
                '${calorias.toStringAsFixed(0)} kcal',
                'Calorias',
              ),
              _dado(Icons.timer_outlined, '$tempo min', 'Tempo'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: salvar,
              icon: const Icon(Icons.save),
              label: const Text('Salvar caminhada'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dado(IconData icon, String valor, String titulo) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 5),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            titulo,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
