// lib/game_page.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'score_page.dart';

enum SpeedMode { Normal, Fast, Lightning }

class GamePage extends StatefulWidget {
  static const route = '/';
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  final Random rng = Random();

  // --- Game Mode Settings ---
  SpeedMode currentMode = SpeedMode.Normal;
  int gameDuration = 30; // seconds
  List<int> reactionTimes = [];

  // --- Target State ---
  bool targetVisible = false;
  Offset targetPos = Offset.zero;
  double targetSize = 50;
  int spawnTime = 0;
  Timer? targetTimer;
  Timer? delayTimer;

  // --- Timer ---
  Timer? gameTimer;
  int remainingTime = 0;
  bool running = false;

  // --- Animation ---
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  // --- Mode Mapping ---
  final Map<SpeedMode, List<int>> subModeDurations = {
    SpeedMode.Normal: [15, 30, 60],
    SpeedMode.Fast: [15, 25, 45],
    SpeedMode.Lightning: [10, 20, 30],
  };

  // --- Mode timing (ms) based on human reaction references ---
  final Map<SpeedMode, List<int>> targetDurations = {
    SpeedMode.Normal: [500, 500, 500],
    SpeedMode.Fast: [450, 450, 450],
    SpeedMode.Lightning: [350, 350, 350], // slightly longer for tappable
  };

  final Map<SpeedMode, int> delayBetweenTargets = {
    SpeedMode.Normal: 300,
    SpeedMode.Fast: 200,
    SpeedMode.Lightning: 200,
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    targetTimer?.cancel();
    delayTimer?.cancel();
    gameTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void startGame() {
    setState(() {
      reactionTimes.clear();
      running = true;
      remainingTime = gameDuration;
    });

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime--;
        if (remainingTime <= 0) {
          timer.cancel();
          endGame();
        }
      });
    });

    spawnTarget();
  }

  void endGame() {
    running = false;
    targetVisible = false;
    targetTimer?.cancel();
    delayTimer?.cancel();

    int best = reactionTimes.isNotEmpty ? reactionTimes.reduce(min) : 0;
    double avg = reactionTimes.isNotEmpty
        ? reactionTimes.reduce((a, b) => a + b) / reactionTimes.length
        : 0;

    Navigator.pushReplacementNamed(context, ScorePage.route, arguments: {
      'times': reactionTimes,
      'best': best,
      'average': avg,
      'rounds': reactionTimes.length,
      'duration': gameDuration,
    });
  }

  void spawnTarget() {
    if (!running) return;

    final sizeScreen = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    // Random target size
    double minSize = 50;
    double maxSize = 75;
    double size = minSize + rng.nextDouble() * (maxSize - minSize);

    double margin = 10;
    double hudHeight = 100;

    final maxX = sizeScreen.width - size - margin;
    final maxY = sizeScreen.height - size - hudHeight - padding.top - padding.bottom - margin;

    double x = margin + rng.nextDouble() * (maxX - margin);
    double y = hudHeight + padding.top + margin + rng.nextDouble() * (maxY - hudHeight - padding.top - margin);

    setState(() {
      targetVisible = true;
      targetSize = size;
      targetPos = Offset(x, y);
      spawnTime = DateTime.now().millisecondsSinceEpoch;
    });

    _animController.reset();
    _animController.forward();

    // Target disappears after mode-based duration
    int duration = targetDurations[currentMode]![rng.nextInt(targetDurations[currentMode]!.length)];
    targetTimer?.cancel();
    targetTimer = Timer(Duration(milliseconds: duration), () {
      if (!running) return;
      setState(() => targetVisible = false);

      // Small delay before next target
      delayTimer?.cancel();
      delayTimer = Timer(Duration(milliseconds: delayBetweenTargets[currentMode]!), () {
        if (running) spawnTarget();
      });
    });
  }

  void onTargetTap() {
    if (!targetVisible) return; // ignore taps if target already gone

    int rt = DateTime.now().millisecondsSinceEpoch - spawnTime;
    reactionTimes.add(rt);

    // Cancel target timer to prevent it from disappearing mid-tap
    targetTimer?.cancel();

    setState(() => targetVisible = false);

    // Small delay before next target
    delayTimer?.cancel();
    delayTimer = Timer(Duration(milliseconds: delayBetweenTargets[currentMode]!), () {
      if (running) spawnTarget();
    });
  }

  Widget buildModeSelector() {
    return Column(
      children: [
        Text('Select Mode',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: SpeedMode.values.map((mode) {
            return ChoiceChip(
              label: Text(mode.name),
              selected: currentMode == mode,
              onSelected: (sel) {
                setState(() {
                  currentMode = mode;
                  gameDuration = subModeDurations[mode]!.first;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text('Duration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            )),
        Wrap(
          spacing: 6,
          children: subModeDurations[currentMode]!.map((d) {
            return ChoiceChip(
              label: Text('$d sec'),
              selected: gameDuration == d,
              onSelected: (sel) {
                setState(() {
                  gameDuration = d;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 15),
        FilledButton(
          onPressed: running ? null : startGame,
          child: Text(running ? 'Running...' : 'Start Game'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F1020), Color(0xFF24104F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time: $remainingTime s',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                      Text('Hits: ${reactionTimes.length}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: running
                        ? Stack(
                      children: [
                        if (targetVisible)
                          Positioned(
                            left: targetPos.dx,
                            top: targetPos.dy,
                            child: GestureDetector(
                              onTap: onTargetTap,
                              child: ScaleTransition(
                                scale: _scaleAnim,
                                child: Container(
                                  width: targetSize,
                                  height: targetSize,
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white24,
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                        : Center(child: buildModeSelector()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
