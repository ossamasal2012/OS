import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';

class RootCalculatorPage extends StatefulWidget {
  const RootCalculatorPage({super.key});

  @override
  State<RootCalculatorPage> createState() => _RootCalculatorPageState();
}

class _RootCalculatorPageState extends State<RootCalculatorPage> {
  final _numberController = TextEditingController();
  final _degreeController = TextEditingController(text: '2');
  String? _result;
  String? _error;

  @override
  void dispose() {
    _numberController.dispose();
    _degreeController.dispose();
    super.dispose();
  }

  void _compute(int? fixedDegree) {
    final l10n = context.l10n;
    final x = double.tryParse(_numberController.text);
    final n = fixedDegree ?? int.tryParse(_degreeController.text);
    if (x == null || n == null || n == 0) {
      setState(() {
        _error = l10n.rootCalculatorInvalidInput;
        _result = null;
      });
      return;
    }
    if (x < 0 && n.isEven) {
      setState(() {
        _error = l10n.rootCalculatorEvenRootNegative;
        _result = null;
      });
      return;
    }
    final value = x < 0 ? -math.pow(-x, 1 / n).toDouble() : math.pow(x, 1 / n).toDouble();
    setState(() {
      _result = value.toStringAsPrecision(10).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _numberController,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: InputDecoration(labelText: l10n.rootCalculatorNumber),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _compute(2),
                  child: Text(l10n.rootCalculatorSquare),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _compute(3),
                  child: Text(l10n.rootCalculatorCube),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _degreeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l10n.rootCalculatorDegree),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: () => _compute(null),
                child: Text(l10n.rootCalculatorCompute),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (_error != null)
            Text(_error!, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.error))
          else if (_result != null)
            Center(
              child: Text('= $_result', style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
            ),
        ],
      ),
    );
  }
}
