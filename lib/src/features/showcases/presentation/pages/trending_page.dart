import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../account/presentation/cubit/account_cubit.dart';
import '../../../account/presentation/widgets/custom_bottom_nav_bar.dart';
import '../../../admin/presentation/widgets/empty_state_widget.dart';
import '../cubit/showcases_cubit.dart';
import '../widgets/showcases_list_view.dart';

class TrendingPage extends StatelessWidget {
  const TrendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.select((AccountCubit cubit) => cubit.state.profile);

    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: const Text('الرائج'),
            surfaceTintColor: Colors.transparent,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'عروض المهندسين والموردين'),
                Tab(text: 'طلبيات المستخدمين'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [_ShowcasesTab(), _OrdersPlaceholderTab()],
          ),
          bottomNavigationBar: CustomBottomNavBar(
            selected: BottomNavDestination.trending,
            profileImageUrl: profile?.imageUrl,
          ),
        ),
      ),
    );
  }
}

class _OrdersPlaceholderTab extends StatelessWidget {
  const _OrdersPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.shopping_bag_outlined,
      title: 'طلبيات المستخدمين',
      subtitle: 'سيتم توفير هذه الميزة قريباً.',
    );
  }
}

class _ShowcasesTab extends StatelessWidget {
  const _ShowcasesTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ShowcasesCubit>()..load(),
      child: const ShowcasesListView(),
    );
  }
}
