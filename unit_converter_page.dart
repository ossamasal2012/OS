import 'package:flutter/material.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/features/unit_converter/logic/unit_converter_data.dart';

const _iconMap = {
  'straighten': Icons.straighten_rounded,
  'crop_square': Icons.crop_square_rounded,
  'water_drop': Icons.water_drop_rounded,
  'scale': Icons.scale_rounded,
  'thermostat': Icons.thermostat_rounded,
  'compress': Icons.compress_rounded,
  'bolt': Icons.bolt_rounded,
  'speed': Icons.speed_rounded,
  'schedule': Icons.schedule_rounded,
  'architecture': Icons.architecture_rounded,
  'storage': Icons.storage_rounded,
};

class UnitConverterPage extends StatefulWidget {
  const UnitConverterPage({super.key});

  @override
  State<UnitConverterPage> createState() => _UnitConverterPageState();
}

class _UnitConverterPageState extends State<UnitConverterPage> {
  UnitCategory _category = UnitConverterData.all.first;
  late String _fromKey = _category.units[0].key;
  late String _toKey = _category.units[1].key;
  final _inputController = TextEditingController(text: '1');

  double? get _result {
    final input = double.tryParse(_inputController.text);
    if (input == null) return null;
    return _category.convert(input, _fromKey, _toKey);
  }

  void _selectCategory(UnitCategory c) {
    setState(() {
      _category = c;
      _fromKey = c.units[0].key;
      _toKey = c.units.length > 1 ? c.units[1].key : c.units[0].key;
    });
  }

  void _swap() {
    setState(() {
      final tmp = _fromKey;
      _fromKey = _toKey;
      _toKey = tmp;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.converterTitle)),
      body: Column(
        children: [
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: UnitConverterData.all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final c = UnitConverterData.all[i];
                final selected = c.key == _category.key;
                return GestureDetector(
                  onTap: () => _selectCategory(c),
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary.withOpacity(0.15)
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: selected ? Border.all(color: theme.colorScheme.primary) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _iconMap[c.icon] ?? Icons.category_rounded,
                          color: selected ? theme.colorScheme.primary : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c.labelAr,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _UnitBox(
                      units: _category.units,
                      selectedKey: _fromKey,
                      controller: _inputController,
                      onUnitChanged: (k) => setState(() => _fromKey = k),
                      editable: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton.filledTonal(
                      onPressed: _swap,
                      icon: const Icon(Icons.swap_horiz_rounded),
                    ),
                  ),
                  Expanded(
                    child: _UnitBox(
                      units: _category.units,
                      selectedKey: _toKey,
                      value: _result,
                      onUnitChanged: (k) => setState(() => _toKey = k),
                      editable: false,
                    ),
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

class _UnitBox extends StatelessWidget {
  const _UnitBox({
    required this.units,
    required this.selectedKey,
    required this.onUnitChanged,
    required this.editable,
    this.controller,
    this.value,
  });

  final List<UnitDef> units;
  final String selectedKey;
  final ValueChanged<String> onUnitChanged;
  final bool editable;
  final TextEditingController? controller;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: selectedKey,
          isExpanded: true,
          items: units
              .map(
                (u) => DropdownMenuItem(
                  value: u.key,
                  child: Text('${u.labelAr} (${u.symbol})', overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onUnitChanged(v);
          },
        ),
        const SizedBox(height: 12),
        if (editable)
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
            decoration: const InputDecoration(),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value == null ? '—' : _format(value!),
              style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.primary),
            ),
          ),
      ],
    );
  }

  String _format(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e12) return v.toStringAsFixed(0);
    var s = v.toStringAsPrecision(8);
    if (s.contains('.') && !s.contains('e')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }
}
