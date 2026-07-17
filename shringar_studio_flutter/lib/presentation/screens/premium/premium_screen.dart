import 'package:flutter/material.dart';

import '../../../domain/repositories/design_repository.dart';
import '../../widgets/design_grid.dart';
import '../../providers/design_providers.dart';

/// Premium gallery. Each design is unlocked individually via a rewarded ad —
/// no subscriptions.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(28),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Unlock any design free by watching a short ad',
                style: TextStyle(fontSize: 12)),
          ),
        ),
      ),
      body: const DesignGrid(
        query: FeedQuery(filter: DesignFilter(premiumOnly: true)),
        heroPrefix: 'premium',
      ),
    );
  }
}
