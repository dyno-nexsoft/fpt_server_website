import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/toast/app_toast.dart';
import 'admin_actions_controller.dart';

/// One entry from `system.hive.list`'s `boxes` array.
class HiveBoxInfo {
  const HiveBoxInfo({required this.name, required this.entryCount});

  final String name;
  final int entryCount;
}

/// Drives [HivePanel]: `null` means "never loaded" (the panel only fetches
/// once expanded), distinct from an empty list of boxes.
class HiveBoxesController extends Notifier<List<HiveBoxInfo>?> {
  @override
  List<HiveBoxInfo>? build() => null;

  Future<void> load() async {
    final body = await ref
        .read(adminActionsControllerProvider)
        .run('system.hive.list', const {});
    if (body == null) return;
    final raw = body['boxes'] as List<dynamic>? ?? const [];
    state = [
      for (final entry in raw.whereType<Map<String, dynamic>>())
        HiveBoxInfo(
          name: entry['name'] as String? ?? '',
          entryCount: entry['entry_count'] as int? ?? 0,
        ),
    ];
  }

  Future<void> clean(String boxName) async {
    final body = await ref.read(adminActionsControllerProvider).run(
      'system.hive.clean',
      {'box': boxName},
    );
    if (body == null) return;
    ref
        .read(appToastProvider.notifier)
        .show(body['message'] as String? ?? 'Done');
    await load();
  }
}

final hiveBoxesControllerProvider =
    NotifierProvider<HiveBoxesController, List<HiveBoxInfo>?>(
      HiveBoxesController.new,
    );
