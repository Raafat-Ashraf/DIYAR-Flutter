import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../requests/presentation/cubit/requests_cubit.dart';
import '../../../requests/presentation/widgets/requests_list_view.dart';

class AdminRequestsPage extends StatelessWidget {
  const AdminRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocProvider(
        create: (_) => getIt<RequestsCubit>()..load(),
        child: Scaffold(
          appBar: AppBar(title: const Text('إدارة الطلبيات')),
          body: const RequestsListView(
            emptyTitle: 'لا توجد طلبات',
            emptySubtitle: 'لا توجد طلبات في النظام حالياً.',
            showTypeFilter: true,
            showStatusFilter: true,
          ),
        ),
      ),
    );
  }
}
