import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../widgets/empty_state_widget.dart';

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: _error != null
            ? EmptyStateWidget(
                icon: Icons.error_outline_rounded,
                title: _error!,
                subtitle: 'تأكد من اتصال الإنترنت وحاول مرة أخرى.',
              )
            : SfPdfViewer.network(
                widget.url,
                onDocumentLoadFailed: (details) {
                  setState(() => _error = 'تعذر تحميل الملف.');
                },
              ),
      ),
    );
  }
}
