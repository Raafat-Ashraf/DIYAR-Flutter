import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../cubit/requests_cubit.dart';
import '../widgets/requests_list_view.dart';

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('طلباتي'),
          surfaceTintColor: Colors.transparent,
        ),
        body: BlocProvider(
          create: (_) => RequestsCubit(
            getRequests: getIt(),
            clientId: clientId,
          )..load(),
          child: const RequestsListView(
            emptyTitle: 'لا توجد طلبات بعد',
            emptySubtitle: 'اضغط + لإضافة طلبك الأول.',
            showTypeFilter: true,
            showStatusFilter: true,
          ),
        ),
      ),
    );
  }
}
