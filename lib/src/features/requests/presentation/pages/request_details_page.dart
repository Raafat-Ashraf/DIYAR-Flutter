import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../account/presentation/widgets/profile_avatar.dart';
import '../../../showcases/presentation/utils/showcase_formatters.dart';
import '../../domain/entities/request.dart';
import '../../domain/usecases/add_comment_use_case.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

class _CNode {
  _CNode({required this.comment});
  final RequestComment comment;
  final List<_CNode> children = [];
}

List<_CNode> _buildTree(List<RequestComment> flat) {
  final map = <int, _CNode>{for (final c in flat) c.id: _CNode(comment: c)};
  final roots = <_CNode>[];
  for (final c in flat) {
    if (c.parentCommentId == null || !map.containsKey(c.parentCommentId)) {
      roots.add(map[c.id]!);
    } else {
      map[c.parentCommentId]!.children.add(map[c.id]!);
    }
  }
  return roots;
}

// Collect ALL descendants (any depth) in DFS order.
List<RequestComment> _descendants(_CNode node) {
  final result = <RequestComment>[];
  for (final child in node.children) {
    result.add(child.comment);
    result.addAll(_descendants(child));
  }
  return result;
}

String _relativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays} يوم';
  if (diff.inHours >= 1) return '${diff.inHours} س';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} د';
  return 'الآن';
}

// ── Page ──────────────────────────────────────────────────────────────────────

class RequestDetailsPage extends StatefulWidget {
  const RequestDetailsPage({super.key, required this.request});

  final Request request;

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool _isSending = false;
  RequestComment? _replyingTo;
  late List<RequestComment> _comments;
  late Map<int, RequestComment> _commentMap;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    _comments = List.of(widget.request.comments);
    _commentMap = {for (final c in _comments) c.id: c};
  }

  void _rebuildMap() =>
      _commentMap = {for (final c in _comments) c.id: c};

  void _startReply(RequestComment c) {
    setState(() => _replyingTo = c);
    _focusNode.requestFocus();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      final newComment = await getIt<AddCommentUseCase>()(
        AddCommentInput(
          requestId: widget.request.id,
          content: text,
          parentCommentId: _replyingTo?.id,
        ),
      );
      setState(() {
        _comments.add(newComment);
        _rebuildMap();
        _controller.clear();
        _replyingTo = null;
      });
    } on AppFailure catch (f) {
      setState(() => _commentError = f.message);
    } catch (_) {
      setState(() => _commentError = 'تعذر إرسال التعليق.');
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final req = widget.request;
    final imageFiles = req.files.where((f) => f.isImage).toList();
    final roots = _buildTree(_comments);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scheme.surfaceContainerLowest,
        // resizeToAvoidBottomInset: true (default) makes body shrink when keyboard opens
        // so _InputBar at bottom of Column stays visible above keyboard
        body: Column(
          children: [
        Expanded(child: CustomScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // ── AppBar ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              surfaceTintColor: Colors.transparent,
              title: Text(
                req.specialization?.name ?? 'تفاصيل الطلب',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: imageFiles.isNotEmpty
                    ? _ImageCarousel(images: imageFiles)
                    : _TypeCover(requestType: req.requestType),
              ),
            ),

            // ── Request details ────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(children: [
                    _Badge(
                      label: req.requestType?.arabicLabel ?? '',
                      color: req.requestType == RequestType.material
                          ? const Color(0xFF0EA5E9)
                          : scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    if (req.status != null) _StatusBadge(status: req.status!),
                  ]),
                  if (req.specialization != null) ...[
                    const SizedBox(height: 12),
                    Text(req.specialization!.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 20)),
                  ],
                  const SizedBox(height: 14),
                  _InfoGrid(request: req),
                  if (req.description != null &&
                      req.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const _Label('الوصف'),
                    const SizedBox(height: 6),
                    Text(req.description!,
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: scheme.onSurface.withValues(alpha: .85))),
                  ],
                  if (req.client != null) ...[
                    const SizedBox(height: 16),
                    const _Label('العميل'),
                    const SizedBox(height: 8),
                    _ClientTile(client: req.client!),
                  ],
                  if (req.files.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Label('الملفات (${req.files.length})'),
                    const SizedBox(height: 8),
                    ...req.files.map((f) => _FileTile(file: f)),
                  ],
                  if (req.createdAt != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.access_time_rounded,
                          size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('أُضيف في ${formatShowcaseDate(req.createdAt)}',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                  ],
                  const SizedBox(height: 20),
                  Divider(color: scheme.outlineVariant),
                  const SizedBox(height: 4),
                  _Label('التعليقات  •  ${_comments.length}'),
                  const SizedBox(height: 4),
                ]),
              ),
            ),

            // ── Comments ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              sliver: roots.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'كن أول من يعلّق!',
                            style: TextStyle(
                                color: scheme.onSurfaceVariant, fontSize: 14),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _RootComment(
                          node: roots[i],
                          commentMap: _commentMap,
                          onReply: _startReply,
                        ),
                        childCount: roots.length,
                      ),
                    ),
            ),
          ],
        )),
        // ── Input bar inside body → pushed up by keyboard ──────
        _InputBar(
          controller: _controller,
          focusNode: _focusNode,
          isSending: _isSending,
          replyingTo: _replyingTo,
          errorMessage: _commentError,
          onCancelReply: () => setState(() => _replyingTo = null),
          onSend: () {
            setState(() => _commentError = null);
            _send();
          },
        ),
          ],
        ),
      ),
    );
  }
}

// ── Root comment (big avatar) + flat reply list ───────────────────────────────

class _RootComment extends StatefulWidget {
  const _RootComment({
    required this.node,
    required this.commentMap,
    required this.onReply,
  });

  final _CNode node;
  final Map<int, RequestComment> commentMap;
  final void Function(RequestComment) onReply;

  @override
  State<_RootComment> createState() => _RootCommentState();
}

class _RootCommentState extends State<_RootComment> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final comment = widget.node.comment;
    final replies = _descendants(widget.node); // flat list of ALL descendants

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Root comment row ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileAvatar(imageUrl: comment.user.imageUrl, size: 38),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(comment.user.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                            const SizedBox(width: 6),
                            Text(_relativeTime(comment.createdAt),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant)),
                          ]),
                          const SizedBox(height: 4),
                          Text(comment.content,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    // Actions
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 4),
                      child: GestureDetector(
                        onTap: () => widget.onReply(comment),
                        child: Text('رد',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Replies section ──────────────────────────────
          if (replies.isNotEmpty)
            Padding(
              // Indent from the right (avatar side)
              padding: const EdgeInsets.only(right: 46, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // View/hide replies toggle
                  if (!_expanded)
                    GestureDetector(
                      onTap: () => setState(() => _expanded = true),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2, bottom: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.expand_more_rounded,
                                size: 16, color: scheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'عرض ${replies.length} ${replies.length == 1 ? 'رد' : 'ردود'}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Connector + replies
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: scheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(right: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: replies.map((reply) {
                          final parentComment =
                              widget.commentMap[reply.parentCommentId];
                          return _ReplyTile(
                            comment: reply,
                            parentUser: parentComment?.user,
                            onReply: () => widget.onReply(reply),
                          );
                        }).toList(),
                      ),
                    ),
                    // Hide replies
                    GestureDetector(
                      onTap: () => setState(() => _expanded = false),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, right: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.expand_less_rounded,
                                size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('إخفاء الردود',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Reply tile (smaller, flat under root) ─────────────────────────────────────

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    required this.comment,
    required this.parentUser,
    required this.onReply,
  });

  final RequestComment comment;
  final CommentUser? parentUser;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileAvatar(imageUrl: comment.user.imageUrl, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(comment.user.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5)),
                        const SizedBox(width: 6),
                        Text(_relativeTime(comment.createdAt),
                            style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurfaceVariant)),
                      ]),
                      const SizedBox(height: 3),
                      // Content with @mention
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black87),
                          children: [
                            if (parentUser != null)
                              TextSpan(
                                text: '@${parentUser!.displayName}  ',
                                style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            TextSpan(text: comment.content),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6, top: 3),
                  child: GestureDetector(
                    onTap: onReply,
                    child: Text('رد',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.replyingTo,
    required this.onCancelReply,
    required this.onSend,
    this.errorMessage,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final RequestComment? replyingTo;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // When keyboard is hidden, add bottom safe area; when open, body is already shifted
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bottomPad = keyboardOpen ? 4.0 : MediaQuery.paddingOf(context).bottom + 4;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPad),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: .06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error message above keyboard
          if (errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: .3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          // Replying-to banner
          if (replyingTo != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: scheme.primary.withValues(alpha: .2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded,
                      size: 14, color: scheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'رد على ${replyingTo!.user.displayName}',
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: onCancelReply,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: replyingTo != null
                        ? 'اكتب ردك...'
                        : 'اكتب تعليقك...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox.square(
                          dimension: 22,
                          child:
                              CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Material(
                      color: scheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onSend,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.send_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets (unchanged) ────────────────────────────────────────────

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.images});
  final List<RequestFileItem> images;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) {
            final url = ProfileAvatar.fullUrl(widget.images[i].fileUrl);
            return url != null
                ? Image.network(url, fit: BoxFit.cover)
                : const SizedBox.shrink();
          },
        ),
        if (widget.images.length > 1)
          Positioned(
            bottom: 12, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _current == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _current == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _TypeCover extends StatelessWidget {
  const _TypeCover({required this.requestType});
  final RequestType? requestType;

  @override
  Widget build(BuildContext context) {
    final isMaterial = requestType == RequestType.material;
    final colors = isMaterial
        ? [const Color(0xFF0EA5E9), const Color(0xFF0369A1)]
        : [const Color(0xFF10B981), const Color(0xFF065F46)];
    final bgIcon =
        isMaterial ? Icons.warehouse_rounded : Icons.architecture_rounded;
    final fgIcon =
        isMaterial ? Icons.inventory_2_rounded : Icons.engineering_rounded;
    final label = isMaterial ? 'طلب مادة' : 'طلب خدمة هندسية';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topRight,
            end: Alignment.bottomLeft),
      ),
      child: Stack(children: [
        Positioned(
          bottom: -20, left: -16,
          child: Icon(bgIcon, size: 160,
              color: Colors.white.withValues(alpha: .10)),
        ),
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  shape: BoxShape.circle),
              child: Icon(fgIcon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: .3)),
          ]),
        ),
      ]),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.request});
  final Request request;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[];
    if (request.city != null) {
      items.add((Icons.location_on_outlined, 'المدينة', request.city!.name));
    }
    if (request.address != null && request.address!.isNotEmpty) {
      items.add((Icons.home_outlined, 'العنوان', request.address!));
    }
    if (request.quantity != null &&
        request.specialization?.measurementUnitName != null) {
      final qty = request.quantity!;
      final v = qty == qty.roundToDouble()
          ? qty.toStringAsFixed(0)
          : qty.toStringAsFixed(2);
      items.add((Icons.inventory_2_outlined, 'الكمية',
          '$v ${request.specialization!.measurementUnitName}'));
    }
    if (request.expectedBudget != null) {
      items.add((Icons.payments_outlined, 'الميزانية',
          formatShowcasePrice(request.expectedBudget)));
    }
    if (request.executionDurationDays != null) {
      items.add((Icons.calendar_today_outlined, 'مدة التنفيذ',
          '${request.executionDurationDays} يوم'));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((e) => _InfoCard(icon: e.$1, label: e.$2, value: e.$3))
          .toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style:
          const TextStyle(fontWeight: FontWeight.w800, fontSize: 15));
}

class _ClientTile extends StatelessWidget {
  const _ClientTile({required this.client});
  final RequestClient client;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        ProfileAvatar(imageUrl: client.imageUrl, size: 42),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.displayName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                if (client.providerType != null)
                  Text(client.providerType!.arabicName,
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant)),
              ]),
        ),
      ]),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file});
  final RequestFileItem file;

  bool get _isPdf => file.fileUrl.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = ProfileAvatar.fullUrl(file.fileUrl);
    final hasDesc = file.description != null && file.description!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: url == null ? null : () => _open(context, url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(children: [
            // Thumbnail
            SizedBox(
              width: 64, height: 64,
              child: file.isImage && url != null
                  ? Image.network(url, fit: BoxFit.cover)
                  : Container(
                      alignment: Alignment.center,
                      color: scheme.primary.withValues(alpha: .08),
                      child: Icon(
                        _isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.insert_drive_file_outlined,
                        color: scheme.primary,
                        size: 28,
                      ),
                    ),
            ),
            // Description (if any)
            if (hasDesc) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  file.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: scheme.onSurface),
                ),
              ),
              const SizedBox(width: 12),
            ] else
              const SizedBox(width: 12),
          ]),
        ),
      ),
    );
  }

  void _open(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FileViewerPage(
          url: url,
          isImage: file.isImage,
          isPdf: _isPdf,
        ),
      ),
    );
  }
}

// ── File viewer page ──────────────────────────────────────────────────────────

class _FileViewerPage extends StatelessWidget {
  const _FileViewerPage({
    required this.url,
    required this.isImage,
    required this.isPdf,
  });

  final String url;
  final bool isImage;
  final bool isPdf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isImage) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (ctx, e, s) => const Center(
              child: Icon(Icons.broken_image_rounded,
                  color: Colors.white54, size: 64),
            ),
          ),
        ),
      );
    }

    if (isPdf) {
      return SfPdfViewer.network(url);
    }

    // Unsupported type
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          const Text(
            'لا يمكن معاينة هذا النوع من الملفات',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(7)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      RequestStatus.open =>
        (const Color(0xFF16A34A), const Color(0xFFDCFCE7)),
      RequestStatus.inProgress =>
        (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      RequestStatus.completed =>
        (const Color(0xFF2563EB), const Color(0xFFDBEAFE)),
      RequestStatus.cancelled =>
        (const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(status.arabicLabel,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
