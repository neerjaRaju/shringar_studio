import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shringar_studio/core/theme/app_theme.dart';
import 'package:shringar_studio/presentation/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renders icon and message', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyState(icon: Icons.favorite_border, message: 'No favorites'),
      ),
    ));
    expect(find.text('No favorites'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  test('hexToColor parses valid and invalid input', () {
    expect(hexToColor('#8e1b3a').value, 0xFF8E1B3A);
    expect(hexToColor('bad'), const Color(0xFF888888));
    expect(hexToColor('#ffffff').value, 0xFFFFFFFF);
  });

  test('AppTheme builds light and dark M3 schemes', () {
    expect(AppTheme.light().useMaterial3, true);
    expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
  });
}
