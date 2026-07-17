import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.dynamicColor = true,
  });

  final ThemeMode themeMode;
  final bool dynamicColor;

  SettingsState copyWith({ThemeMode? themeMode, bool? dynamicColor}) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        dynamicColor: dynamicColor ?? this.dynamicColor,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier(this._ref) : super(const SettingsState()) {
    _load();
  }

  final Ref _ref;
  static const _themeKey = 'theme_mode';
  static const _dynamicKey = 'dynamic_color';

  void _load() {
    final prefs = _ref.read(sharedPrefsProvider);
    state = SettingsState(
      themeMode: ThemeMode.values[prefs.getInt(_themeKey) ?? 0],
      dynamicColor: prefs.getBool(_dynamicKey) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _ref.read(sharedPrefsProvider).setInt(_themeKey, mode.index);
  }

  Future<void> setDynamicColor(bool enabled) async {
    state = state.copyWith(dynamicColor: enabled);
    await _ref.read(sharedPrefsProvider).setBool(_dynamicKey, enabled);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(ref),
);
