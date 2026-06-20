import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../cubit/showcases_cubit.dart';
import '../widgets/showcases_list_view.dart';

class ShowcasesListPage extends StatelessWidget {
  const ShowcasesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('عروض المهندسين والموردين'),
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocProvider(
          create: (_) => getIt<ShowcasesCubit>()..load(),
          child: const ShowcasesListView(),
        ),
      ),
    );
  }
}
