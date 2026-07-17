import 'package:flutter/material.dart';

import '../../../domain/repositories/design_repository.dart';
import '../../providers/design_providers.dart';
import '../../widgets/design_grid.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen(
      {super.key, required this.categoryId, required this.categoryName});

  final String categoryId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: DesignGrid(
        query: FeedQuery(filter: DesignFilter(category: categoryId)),
        heroPrefix: 'cat-$categoryId',
      ),
    );
  }
}
