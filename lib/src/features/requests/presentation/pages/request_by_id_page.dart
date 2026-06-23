import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/usecases/get_request_by_id_use_case.dart';
import 'request_details_page.dart';

class RequestByIdPage extends StatefulWidget {
  const RequestByIdPage({super.key, required this.requestId});

  final int requestId;

  @override
  State<RequestByIdPage> createState() => _RequestByIdPageState();
}

class _RequestByIdPageState extends State<RequestByIdPage> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final request = await getIt<GetRequestByIdUseCase>()(widget.requestId);
      if (!mounted) return;
      // Replace this loader page with the real details page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RequestDetailsPage(request: request),
        ),
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('تعذر تحميل الطلب');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
