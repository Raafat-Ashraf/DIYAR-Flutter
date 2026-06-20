import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../../account/presentation/widgets/custom_bottom_nav_bar.dart';
import '../../../requests/presentation/cubit/requests_cubit.dart';
import '../../../requests/presentation/widgets/requests_list_view.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((AccountCubit cubit) => cubit.state.profile);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('طلبيات العملاء'),
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocProvider(
          create: (_) => getIt<RequestsCubit>()..load(),
          child: const RequestsListView(
            emptyTitle: 'لا توجد طلبات حالياً',
            emptySubtitle: 'سيظهر هنا أي طلب جديد من العملاء.',
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selected: BottomNavDestination.trending,
          profileImageUrl: profile?.imageUrl,
        ),
      ),
    );
  }
}
