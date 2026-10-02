import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/caminhada.dart';
import '../services/storage_service.dart';
import '../widgets/menu_drawer.dart';
import 'detalhes_caminhada.dart';
import 'nova_caminhada.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Caminhada> caminhadas = [];
  bool carregando = true;

  final Map<String, Uint8List?> imagens = {};

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final dados = await StorageService.carregarCaminhadas();

    if (!mounted) return;

    setState(() {
      caminhadas = dados;
      carregando = false;
    });

    await carregarImagens();
  }

  Future<void> carregarImagens() async {
    for (final caminhada in caminhadas) {
      if (caminhada.foto == null) {
        imagens[caminhada.id] = null;
        continue;
      }

      try {
        final arquivo = XFile(caminhada.foto!);
        final bytes = await arquivo.readAsBytes();

        if (!mounted) return;

        setState(() {
          imagens[caminhada.id] = bytes;
        });
      } catch (_) {
        imagens[caminhada.id] = null;
      }
    }
  }

  Future<void> abrirNovaCaminhada() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NovaCaminhada()),
    );

    await carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuDrawer(),

      appBar: AppBar(
        title: const Text(
          'Minhas caminhadas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : caminhadas.isEmpty
          ? _estadoVazio()
          : RefreshIndicator(
              onRefresh: carregar,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: caminhadas.length,
                itemBuilder: (context, index) {
                  return _cardCaminhada(caminhadas[index]);
                },
              ),
            ),

      floatingActionButton: FloatingActionButton(
        onPressed: abrirNovaCaminhada,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_walk_outlined,
              size: 90,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 20),

            const Text(
              'Nenhuma caminhada ainda',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Toque no botão + para registrar sua primeira caminhada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardCaminhada(Caminhada caminhada) {
    final imagem = imagens[caminhada.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,

      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesCaminhada(caminhada: caminhada),
            ),
          );

          await carregar();
        },

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagem != null)
              SizedBox(
                height: 170,
                width: double.infinity,
                child: Image.memory(imagem, fit: BoxFit.cover),
              )
            else
              Container(
                height: 140,
                width: double.infinity,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),

                child: Icon(
                  Icons.directions_walk,
                  size: 65,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    caminhada.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _info(
                        Icons.straighten,
                        '${caminhada.distancia.toStringAsFixed(2)} km',
                      ),

                      _info(
                        Icons.local_fire_department,
                        '${caminhada.calorias.toStringAsFixed(0)} kcal',
                      ),

                      _info(
                        Icons.timer_outlined,
                        '${caminhada.tempoMinutos} min',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String texto) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),

          const SizedBox(width: 5),

          Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
