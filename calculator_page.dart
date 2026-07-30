import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/calculator/logic/calculator_provider.dart';
import 'package:life_os/features/calculator/pages/root_calculator_page.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calculatorTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l10n.calculatorScientific), Tab(text: l10n.calculatorRoots)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ScientificCalculator(), RootCalculatorPage()],
      ),
    );
  }
}

class _ScientificCalculator extends ConsumerWidget {
  const _ScientificCalculator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calculatorProvider);
    final notifier = ref.read(calculatorProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            alignment: Alignment.bottomRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  state.expression.isEmpty ? '0' : state.expression,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.end,
                ),
                const SizedBox(height: 8),
                if (state.error != null)
                  Text(
                    state.error!,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error),
                  )
                else if (state.result != null)
                  Text(
                    '= ${state.result}',
                    style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: notifier.toggleDegrees,
                child: Text(state.isDegrees ? 'DEG' : 'RAD'),
              ),
              IconButton(
                onPressed: notifier.backspace,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          child: Column(
            children: [
              _row(['sin(', 'cos(', 'tan(', '^'], notifier, secondary: true),
              _row(['log(', 'ln(', 'sqrt(', '%'], notifier, secondary: true),
              _row(['(', ')', 'π', 'C'], notifier, secondary: true, isClear: true),
              _row(['7', '8', '9', '÷'], notifier),
              _row(['4', '5', '6', '×'], notifier),
              _row(['1', '2', '3', '-'], notifier),
              _row(['0', '.', '=', '+'], notifier, isEquals: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(
    List<String> labels,
    CalculatorNotifier notifier, {
    bool secondary = false,
    bool isClear = false,
    bool isEquals = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: labels.map((label) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _CalcButton(
                label: label,
                secondary: secondary,
                isAccent: isEquals && label == '=',
                onTap: () => _handleTap(label, notifier),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleTap(String label, CalculatorNotifier notifier) {
    switch (label) {
      case 'C':
        notifier.clear();
        break;
      case '=':
        notifier.evaluate();
        break;
      case 'π':
        notifier.input('pi');
        break;
      default:
        notifier.input(label);
    }
  }
}

class _CalcButton extends StatelessWidget {
  const _CalcButton({
    required this.label,
    required this.onTap,
    this.secondary = false,
    this.isAccent = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool secondary;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isAccent
        ? scheme.primary
        : secondary
            ? scheme.surfaceContainerHigh
            : scheme.surfaceContainer;
    final fg = isAccent ? scheme.onPrimary : scheme.onSurface;

    return AspectRatio(
      aspectRatio: 1.3,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
