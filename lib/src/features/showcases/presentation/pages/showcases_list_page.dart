import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/showcase.dart';
import '../../domain/usecases/get_showcases_use_case.dart';
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
          title: const Text('المشاريع الهندسية'),
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocProvider(
          create: (_) {
            final cubit = ShowcasesCubit(
              getShowcases: getIt<GetShowcasesUseCase>(),
            );
            cubit.changeType(ShowcaseType.portfolio);
            return cubit;
          },
          child: const ShowcasesListView(
            showTypeFilter: false,
            emptyTitle: 'لا توجد مشاريع هندسية حالياً',
            emptySubtitle: 'سيظهر هنا أي مشروع جديد من المهندسين.',
          ),
        ),
      ),
    );
  }
}
