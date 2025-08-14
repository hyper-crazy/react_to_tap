// lib/score_page.dart
import 'package:flutter/material.dart';

class ScorePage extends StatelessWidget {
  static const route = '/score';
  const ScorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve arguments from GamePage
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final List<int> times = List<int>.from(args['times'] ?? []);
    final int best = args['best'] ?? 0;
    final double average = args['average'] ?? 0;
    final int hits = args['rounds'] ?? times.length;
    final int duration = args['duration'] ?? 30; // in seconds

    final double hps = duration > 0 ? hits / duration : 0;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cs.surfaceVariant.withOpacity(0.12),
              cs.primary.withOpacity(0.25),
              cs.secondary.withOpacity(0.12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Results',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  color: cs.surface.withOpacity(0.7),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _StatRow(label: 'Best Time', value: '${best}ms'),
                        const Divider(height: 20, thickness: 0.5),
                        _StatRow(
                            label: 'Average Time',
                            value: '${average.toStringAsFixed(1)}ms'),
                        const Divider(height: 20, thickness: 0.5),
                        _StatRow(label: 'Total Hits', value: '$hits'),
                        const Divider(height: 20, thickness: 0.5),
                        _StatRow(
                            label: 'Hits per Second', value: hps.toStringAsFixed(2)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Round times list
                Expanded(
                  child: ListView.separated(
                    itemCount: times.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: cs.primary.withOpacity(0.2)),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primary.withOpacity(0.2),
                          child: Text('${index + 1}',
                              style: TextStyle(color: Colors.white)),
                        ),
                        title: Text('Hit ${index + 1}',
                            style: const TextStyle(color: Colors.white)),
                        trailing: Text('${times[index]}ms',
                            style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      child: const Text('Play Again'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Exit'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// --- Helper widget for stats ---
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
            Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.white70)),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
