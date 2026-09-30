import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'game/game_controller.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = GameController(StorageService());
  await controller.load();

  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: const MascotaVirtualApp(),
    ),
  );
}

class MascotaVirtualApp extends StatefulWidget {
  const MascotaVirtualApp({super.key});

  @override
  State<MascotaVirtualApp> createState() => _MascotaVirtualAppState();
}

class _MascotaVirtualAppState extends State<MascotaVirtualApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando la app vuelve a primer plano, recalculamos el desgaste.
    if (state == AppLifecycleState.resumed) {
      context.read<GameController>().applyElapsedTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mascota Virtual',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}