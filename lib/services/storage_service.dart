import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/caminhada.dart';

class StorageService {
  static const String chave = 'caminhadas';

  static Future<List<Caminhada>> carregarCaminhadas() async {
    final prefs = await SharedPreferences.getInstance();

    final dados = prefs.getString(chave);

    if (dados == null) {
      return [];
    }

    final lista = jsonDecode(dados) as List;

    return lista.map((item) => Caminhada.fromMap(item)).toList();
  }

  static Future<void> salvarCaminhadas(List<Caminhada> caminhadas) async {
    final prefs = await SharedPreferences.getInstance();

    final dados = caminhadas.map((caminhada) => caminhada.toMap()).toList();

    await prefs.setString(chave, jsonEncode(dados));
  }

  static Future<void> adicionarCaminhada(Caminhada caminhada) async {
    final caminhadas = await carregarCaminhadas();

    caminhadas.add(caminhada);

    await salvarCaminhadas(caminhadas);
  }

  static Future<void> atualizarCaminhada(Caminhada caminhada) async {
    final caminhadas = await carregarCaminhadas();

    final index = caminhadas.indexWhere((item) => item.id == caminhada.id);

    if (index != -1) {
      caminhadas[index] = caminhada;
    }

    await salvarCaminhadas(caminhadas);
  }
}
