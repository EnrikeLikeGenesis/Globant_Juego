import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/game_controller.dart';
import '../game/sudoku_logic.dart';

class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  SudokuDifficulty _difficulty = SudokuDifficulty.easy;
  SudokuLogic? _game;
  int? _selectedCell;

  void _startGame() {
    if (!context.read<GameController>().startMiniGame()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu mascota está demasiado cansada para jugar.'),
        ),
      );
      return;
    }

    setState(() {
      _game = SudokuLogic.generate(_difficulty);
      _selectedCell = null;
    });
  }

  void _selectNumber(int value) {
    final game = _game;
    final cell = _selectedCell;
    if (game == null || cell == null) return;
    final row = cell ~/ SudokuLogic.size;
    final column = cell % SudokuLogic.size;
    if (game.given[row][column]) return;

    setState(() => game.puzzle[row][column] = value);
  }

  void _eraseSelected() {
    final game = _game;
    final cell = _selectedCell;
    if (game == null || cell == null) return;
    final row = cell ~/ SudokuLogic.size;
    final column = cell % SudokuLogic.size;
    if (game.given[row][column]) return;
    setState(() => game.puzzle[row][column] = 0);
  }

  bool get _isComplete {
    final game = _game;
    if (game == null) return false;
    for (var row = 0; row < SudokuLogic.size; row++) {
      for (var column = 0; column < SudokuLogic.size; column++) {
        if (game.puzzle[row][column] != game.solution[row][column]) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: SafeArea(
        child: _game == null ? _buildDifficultyPicker() : _buildBoard(),
      ),
    );
  }

  Widget _buildDifficultyPicker() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.grid_4x4, size: 56),
              const SizedBox(height: 16),
              Text(
                'Elige la dificultad',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              SegmentedButton<SudokuDifficulty>(
                segments: [
                  for (final difficulty in SudokuDifficulty.values)
                    ButtonSegment(
                      value: difficulty,
                      label: Text(difficulty.label),
                    ),
                ],
                selected: {_difficulty},
                onSelectionChanged: (selection) {
                  setState(() => _difficulty = selection.first);
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${_difficulty.emptyCells} casillas vacías',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Comenzar partida'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoard() {
    final game = _game!;
    final selectedRow = _selectedCell == null
        ? null
        : _selectedCell! ~/ SudokuLogic.size;
    final selectedColumn = _selectedCell == null
        ? null
        : _selectedCell! % SudokuLogic.size;
    final selectedValue = selectedRow == null
        ? 0
        : game.puzzle[selectedRow][selectedColumn!];

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = (constraints.maxWidth - 32).clamp(0.0, 480.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Center(
            child: SizedBox(
              width: boardSize,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _difficulty.label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _game = null;
                          _selectedCell = null;
                        }),
                        icon: const Icon(Icons.tune),
                        label: const Text('Dificultad'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: SudokuLogic.size * SudokuLogic.size,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: SudokuLogic.size,
                          ),
                      itemBuilder: (context, index) {
                        final row = index ~/ SudokuLogic.size;
                        final column = index % SudokuLogic.size;
                        final value = game.puzzle[row][column];
                        final isSelected = index == _selectedCell;
                        final sameUnit =
                            _selectedCell != null &&
                            (row == selectedRow || column == selectedColumn);
                        final sameBox =
                            _selectedCell != null &&
                            row ~/ 3 == selectedRow! ~/ 3 &&
                            column ~/ 3 == selectedColumn! ~/ 3;
                        final isRelated = sameUnit || sameBox;
                        final isSameValue =
                            value != 0 && value == selectedValue;
                        final isWrong =
                            value != 0 && value != game.solution[row][column];
                        final isFixed = game.given[row][column];

                        return GestureDetector(
                          onTap: () => setState(() => _selectedCell = index),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFB7D7C5)
                                  : isSameValue
                                  ? const Color(0xFFDCEBE2)
                                  : isRelated
                                  ? const Color(0xFFF1F5F1)
                                  : Colors.white,
                              border: Border(
                                left: BorderSide(
                                  color: const Color(0xFF65736A),
                                  width: column % 3 == 0 ? 1.5 : 0.5,
                                ),
                                top: BorderSide(
                                  color: const Color(0xFF65736A),
                                  width: row % 3 == 0 ? 1.5 : 0.5,
                                ),
                                right: BorderSide(
                                  color: const Color(0xFF65736A),
                                  width: column == 8 ? 1.5 : 0.5,
                                ),
                                bottom: BorderSide(
                                  color: const Color(0xFF65736A),
                                  width: row == 8 ? 1.5 : 0.5,
                                ),
                              ),
                            ),
                            child: value == 0
                                ? null
                                : Text(
                                    '$value',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: isFixed
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isWrong
                                          ? const Color(0xFFC13D3D)
                                          : isFixed
                                          ? const Color(0xFF35423A)
                                          : const Color(0xFF287C5D),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isComplete) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '¡Sudoku resuelto!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => setState(() {
                        _game = null;
                        _selectedCell = null;
                      }),
                      icon: const Icon(Icons.replay),
                      label: const Text('Elegir dificultad'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: [
                      for (var number = 1; number <= 9; number++)
                        OutlinedButton(
                          onPressed: () => _selectNumber(number),
                          child: Text(
                            '$number',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _eraseSelected,
                    icon: const Icon(Icons.backspace_outlined),
                    label: const Text('Borrar casilla'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
