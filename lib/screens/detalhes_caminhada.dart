import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/caminhada.dart';
import '../services/storage_service.dart';

class DetalhesCaminhada extends StatefulWidget {
  final Caminhada caminhada;

  const DetalhesCaminhada({super.key, required this.caminhada});

  @override
  State<DetalhesCaminhada> createState() => _DetalhesCaminhadaState();
}

class _DetalhesCaminhadaState extends State<DetalhesCaminhada> {
  late Caminhada caminhada;

  final ImagePicker picker = ImagePicker();

  Uint8List? imagemBytes;

  @override
  void initState() {
    super.initState();

    caminhada = widget.caminhada;

    carregarImagem();
  }

  Future<void> carregarImagem() async {
    if (caminhada.foto == null) {
      return;
    }

    try {
      final imagem = XFile(caminhada.foto!);
      final bytes = await imagem.readAsBytes();

      if (!mounted) return;

      setState(() {
        imagemBytes = bytes;
      });
    } catch (e) {
      imagemBytes = null;
    }
  }

  Future<void> tirarFoto() async {
    try {
      final imagem = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (imagem == null) {
        return;
      }

      final bytes = await imagem.readAsBytes();

      caminhada.foto = imagem.path;

      await StorageService.atualizarCaminhada(caminhada);

      if (!mounted) return;

      setState(() {
        imagemBytes = bytes;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto salva com sucesso!')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível adicionar a foto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inicio = LatLng(caminhada.inicioLat, caminhada.inicioLng);

    final destino = LatLng(caminhada.destinoLat, caminhada.destinoLng);

    final pontosRota = caminhada.rota
        .map((ponto) => LatLng(ponto[0], ponto[1]))
        .toList();

    final temFoto = imagemBytes != null;

    return Scaffold(
      appBar: AppBar(title: Text(caminhada.titulo)),

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 320,
              child: FlutterMap(
                options: MapOptions(initialCenter: inicio, initialZoom: 14),

                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

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
                        point: inicio,
                        width: 45,
                        height: 45,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),

                      Marker(
                        point: destino,
                        width: 45,
                        height: 45,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    caminhada.titulo,

                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      _cardInfo(
                        Icons.straighten,
                        caminhada.distancia.toStringAsFixed(2),
                        'km',
                      ),

                      const SizedBox(width: 10),

                      _cardInfo(
                        Icons.local_fire_department,
                        caminhada.calorias.toStringAsFixed(0),
                        'kcal',
                      ),

                      const SizedBox(width: 10),

                      _cardInfo(
                        Icons.timer_outlined,
                        '${caminhada.tempoMinutos}',
                        'min',
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Foto da caminhada',

                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  if (temFoto)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),

                      child: Image.memory(
                        imagemBytes!,
                        width: double.infinity,
                        height: 230,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: tirarFoto,

                      child: Container(
                        width: double.infinity,
                        height: 200,

                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(.10),

                          borderRadius: BorderRadius.circular(18),

                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(.3),
                          ),
                        ),

                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 55,

                              color: Theme.of(context).colorScheme.primary,
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Adicionar foto',

                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (temFoto)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),

                      child: SizedBox(
                        width: double.infinity,

                        child: OutlinedButton.icon(
                          onPressed: tirarFoto,

                          icon: const Icon(Icons.camera_alt),

                          label: const Text('Tirar outra foto'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardInfo(IconData icon, String valor, String unidade) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),

        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(.08),

          borderRadius: BorderRadius.circular(15),
        ),

        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),

            const SizedBox(height: 7),

            Text(
              valor,

              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            Text(
              unidade,

              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
