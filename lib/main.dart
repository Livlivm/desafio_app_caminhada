import 'package:flutter/material.dart';

import 'screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const CaminhadasApp());
}

class CaminhadasApp extends StatefulWidget {
  const CaminhadasApp({super.key});

  @override
  State<CaminhadasApp> createState() => _CaminhadasAppState();

  static _CaminhadasAppState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppScope>()?._state;
  }
}

class _CaminhadasAppState extends State<CaminhadasApp> {
  bool isDarkMode = false;

  void alterarTema(bool valor) {
    setState(() {
      isDarkMode = valor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AppScope(
      state: this,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Caminhadas',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF7C4DFF),
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF7F5FA),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF9C7CFF),
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF15121A),
        ),
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const Splash(),
      ),
    );
  }
}

class _AppScope extends InheritedWidget {
  final _CaminhadasAppState state;

  const _AppScope({required this.state, required super.child});

  _CaminhadasAppState get _state => state;

  @override
  bool updateShouldNotify(_AppScope oldWidget) {
    return oldWidget.state.isDarkMode != state.isDarkMode;
  }
}
