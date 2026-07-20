import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/core_providers.dart';
import '../../providers/design_providers.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _checkUpdate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('Checking for updates…')));
    final service = ref.read(updateServiceProvider);
    final info = await service.checkForUpdate();
    if (info == null) {
      messenger.showSnackBar(const SnackBar(content: Text('You are up to date')));
      return;
    }
    final file = await service.downloadDatabase(info);
    if (file == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Update download failed')));
      return;
    }
    // Live-swap and refresh — no restart needed.
    await ref.read(appDatabaseProvider).reopenDesignDb(file);
    await service.markUpdated(info.version);
    ref.read(libraryRevisionProvider.notifier).state++;
    ref.invalidate(categoriesProvider);
    ref.invalidate(festivalsProvider);
    ref.invalidate(dailyDesignProvider);
    ref.invalidate(totalCountProvider);
    messenger.showSnackBar(SnackBar(
        content: Text('Updated to ${info.version} · ${info.totalDesigns} designs')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final total = ref.watch(totalCountProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          RadioListTile(
            title: const Text('System theme'),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (m) =>
                ref.read(settingsProvider.notifier).setThemeMode(m!),
          ),
          RadioListTile(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (m) =>
                ref.read(settingsProvider.notifier).setThemeMode(m!),
          ),
          RadioListTile(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (m) =>
                ref.read(settingsProvider.notifier).setThemeMode(m!),
          ),
          SwitchListTile(
            title: const Text('Material You dynamic colors'),
            subtitle: const Text('Use your wallpaper colors (Android 12+)'),
            value: settings.dynamicColor,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setDynamicColor(v),
          ),
          const Divider(),
          const _SectionHeader('Library'),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Designs available'),
            trailing: total.maybeWhen(
                data: (n) => Text('$n'), orElse: () => const Text('…')),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Check for updates'),
            subtitle: const Text('Downloads new designs from GitHub Releases'),
            onTap: () => _checkUpdate(context, ref),
          ),
          const Divider(),
          const _SectionHeader('About'),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) => ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Version'),
              trailing: Text(snap.hasData
                  ? '${snap.data!.version}+${snap.data!.buildNumber}'
                  : '…'),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.favorite_outline),
            title: Text('Shringar Studio'),
            subtitle: Text("India's largest offline women's design library"),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold)),
      );
}
