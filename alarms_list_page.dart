import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/utils/l10n_extensions.dart';
import 'package:life_os/core/widgets/empty_state_view.dart';
import 'package:life_os/features/alarms/pages/alarm_editor_page.dart';
import 'package:life_os/features/alarms/providers/alarms_provider.dart';
import 'package:life_os/features/alarms/widgets/alarm_tile.dart';

class AlarmsListPage extends ConsumerStatefulWidget {
  const AlarmsListPage({super.key});

  @override
  ConsumerState<AlarmsListPage> createState() => _AlarmsListPageState();
}

class _AlarmsListPageState extends ConsumerState<AlarmsListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    var alarms = ref.watch(sortedAlarmsProvider);
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      alarms = alarms.where((a) => a.label.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alarmsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: l10n.alarmsSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AlarmEditorPage())),
        child: const Icon(Icons.add_rounded),
      ),
      body: alarms.isEmpty
          ? EmptyStateView(
              icon: Icons.alarm_outlined,
              title: l10n.alarmsEmptyTitle,
              message: l10n.alarmsEmptyMessage,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
              itemCount: alarms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final alarm = alarms[i];
                return AlarmTile(
                  alarm: alarm,
                  onToggle: (_) => ref.read(alarmsProvider.notifier).toggleEnabled(alarm),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AlarmEditorPage(alarmId: alarm.id)),
                  ),
                );
              },
            ),
    );
  }
}
