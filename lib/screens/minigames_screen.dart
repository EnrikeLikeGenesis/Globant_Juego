import 'package:flutter/material.dart';

import 'catch_game_screen.dart';
import 'crossy_road_screen.dart';
import 'sudoku_screen.dart';

class MinigamesScreen extends StatelessWidget {
  const MinigamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minijuegos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Text('🧺', style: TextStyle(fontSize: 28)),
              title: const Text('Atrapa objetos'),
              subtitle: const Text('Atrapa lo que cae y gana monedas'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CatchGameScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Image.asset(
                'assets/images/buho1.png',
                width: 40,
                height: 40,
              ),
              title: const Text('Cruza la calle'),
              subtitle: const Text('Guía al búho entre los coches'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CrossyRoadScreen()),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.grid_4x4, size: 32),
              title: const Text('Sudoku'),
              subtitle: const Text('Completa el tablero y elige la dificultad'),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SudokuScreen())),
            ),
          ),
        ],
      ),
    );
  }
}
