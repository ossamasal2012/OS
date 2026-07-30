import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/features/calculator/logic/expression_evaluator.dart';

class CalculatorState {
  const CalculatorState({
    this.expression = '',
    this.result,
    this.error,
    this.isDegrees = true,
  });

  final String expression;
  final String? result;
  final String? error;
  final bool isDegrees;

  CalculatorState copyWith({
    String? expression,
    String? result,
    bool clearResult = false,
    String? error,
    bool clearError = false,
    bool? isDegrees,
  }) {
    return CalculatorState(
      expression: expression ?? this.expression,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
      isDegrees: isDegrees ?? this.isDegrees,
    );
  }
}

class CalculatorNotifier extends Notifier<CalculatorState> {
  @override
  CalculatorState build() => const CalculatorState();

  void input(String token) {
    state = state.copyWith(
      expression: state.expression + token,
      clearResult: true,
      clearError: true,
    );
  }

  void backspace() {
    if (state.expression.isEmpty) return;
    state = state.copyWith(
      expression: state.expression.substring(0, state.expression.length - 1),
      clearResult: true,
      clearError: true,
    );
  }

  void clear() => state = CalculatorState(isDegrees: state.isDegrees);

  void toggleDegrees() => state = state.copyWith(isDegrees: !state.isDegrees);

  void evaluate() {
    try {
      final value = ExpressionEvaluator.evaluate(state.expression, degrees: state.isDegrees);
      state = state.copyWith(result: _formatResult(value), clearError: true);
    } on CalculatorError catch (e) {
      state = state.copyWith(error: e.message, clearResult: true);
    }
  }

  static String _formatResult(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    var s = value.toStringAsPrecision(10);
    if (s.contains('.') && !s.contains('e')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }
}

final calculatorProvider = NotifierProvider<CalculatorNotifier, CalculatorState>(
  CalculatorNotifier.new,
);
