import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/request.dart';
import '../../domain/usecases/get_request_by_id_use_case.dart';
import 'request_details_page.dart';

class RequestByIdPage extends StatefulWidget {
  const RequestByIdPage({super.key, required this.requestId});

  final int requestId;

  @override
  State<RequestByIdPage> createState() => _RequestByIdPageState();
}

class _RequestByIdPageState extends State<RequestByIdPage> {
  Request? _request;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final request = await getIt<GetRequestByIdUseCase>()(widget.requestId);
      if (!mounted) return;
      setState(() => _request = request);
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذر تحميل الطلب');
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = _request;
    if (req != null) {
      return RequestDetailsPage(request: req);
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () { setState(() => _error = null); _load(); },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('حاول مرة أخرى'),
              ),
            ],
          ),
        ),
      );
    }
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
