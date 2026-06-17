import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/usecases/get_showcases_use_case.dart';
import '../cubit/showcases_cubit.dart';
import '../widgets/showcases_list_view.dart';

class MyShowcasesPage extends StatelessWidget {
  const MyShowcasesPage({
    super.key,
    required this.title,
    required this.userId,
  });

  final String title;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(title: Text(title), surfaceTintColor: Colors.transparent),
        body: BlocProvider(
          create: (_) => ShowcasesCubit(
            getShowcases: getIt<GetShowcasesUseCase>(),
            userId: userId,
          )..load(),
          child: ShowcasesListView(
            emptyTitle: 'لا توجد عروض حالياً',
            emptySubtitle: 'سيظهر هنا أي عرض تقوم بإضافته.',
            showTypeFilter: false,
          ),
        ),
      ),
    );
  }
}
