import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../widgets/entrance.dart';
import '../widgets/primary_button.dart';
import '../widgets/wave.dart';

/// Reads a premium book. The first [EBook.freePages] pages are free; the rest
/// are locked behind a one-time payment. Unlocks live via [AppState] the moment
/// an admin approves the receipt. A book is either an uploaded PDF or typed
/// pages.
///
/// Offline this reads straight from [AppState.bookById] — unchanged from
/// before there was a backend. Online, the catalog's bulk book list only
/// ever carries metadata (see `AppState._loadCatalog`), so this fetches the
/// real, gated content once via [AppState.fetchBookDetail] instead.
class EBookReaderScreen extends StatefulWidget {
  const EBookReaderScreen({super.key, required this.book});

  final EBook book;

  @override
  State<EBookReaderScreen> createState() => _EBookReaderScreenState();
}

class _EBookReaderScreenState extends State<EBookReaderScreen> {
  EBook? _fetched;
  bool _fetchedUnlocked = false;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (AppStateScope.read(context).isOnline) _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final result = await AppStateScope.read(context).fetchBookDetail(widget.book.id);
      if (!mounted) return;
      setState(() {
        _fetched = result.book;
        _fetchedUnlocked = result.unlocked;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final online = state.isOnline;

    final EBook live;
    final bool unlocked;
    if (online) {
      live = _fetched ?? widget.book;
      unlocked = _fetched != null ? _fetchedUnlocked : state.isUnlocked(widget.book.id);
    } else {
      live = state.bookById(widget.book.id) ?? widget.book;
      unlocked = state.isUnlocked(live.id);
    }

    void openPayment() => Navigator.of(context)
        .pushNamed(AppRoutes.payMethod, arguments: state.purchasableForBook(live))
        .then((_) {
      // Coming back from a successful payment — reload so the newly
      // unlocked pages/PDF actually show up.
      if (online && mounted) _fetch();
    });

    Widget body;
    if (online && _loading && _fetched == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (online && _failed && _fetched == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Couldn't load this book.", textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(onPressed: _fetch, child: const Text('Try again')),
            ],
          ),
        ),
      );
    } else {
      body = live.hasPdf
          ? _PdfBody(book: live, unlocked: unlocked, onUnlock: openPayment)
          : _TextBody(book: live, unlocked: unlocked, onUnlock: openPayment);
    }

    return Scaffold(
      backgroundColor: AppColors.yellow,
      body: Column(
        children: [
          WaveHeader(
            height: 116,
            title: live.title,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

// --- Typed-pages book -------------------------------------------------------

class _TextBody extends StatelessWidget {
  const _TextBody({
    required this.book,
    required this.unlocked,
    required this.onUnlock,
  });

  final EBook book;
  final bool unlocked;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final total = book.pageCount;
    final visible = unlocked ? total : book.freePages.clamp(0, total);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        _ProgressRow(visible: visible, total: total, unlocked: unlocked),
        const SizedBox(height: 14),
        for (var i = 0; i < visible; i++)
          Entrance(
            delay: Duration(milliseconds: 60 * i),
            child: _Sheet(
              label: 'Page ${i + 1}',
              child: Text(
                book.pages[i],
                style: const TextStyle(
                    fontSize: 15, height: 1.55, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        if (!unlocked && visible < total)
          _LockCard(book: book, freeShown: visible, onUnlock: onUnlock),
        if (unlocked) const _EndMarker(),
      ],
    );
  }
}

// --- PDF book -------------------------------------------------------------

class _PdfBody extends StatefulWidget {
  const _PdfBody({
    required this.book,
    required this.unlocked,
    required this.onUnlock,
  });

  final EBook book;
  final bool unlocked;
  final VoidCallback onUnlock;

  @override
  State<_PdfBody> createState() => _PdfBodyState();
}

class _PdfBodyState extends State<_PdfBody> {
  Future<PdfDocument>? _docFuture;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    if (b.pdfPath != null && b.pdfPath!.isNotEmpty) {
      _docFuture = PdfDocument.openFile(b.pdfPath!);
    } else if (b.pdfBytes != null) {
      _docFuture = PdfDocument.openData(b.pdfBytes!);
    }
  }

  @override
  void dispose() {
    _docFuture?.then((d) => d.close()).catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_docFuture == null) {
      return const Center(child: Text('This book has no file yet.'));
    }
    return FutureBuilder<PdfDocument>(
      future: _docFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text("Couldn't open this PDF.", textAlign: TextAlign.center),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final doc = snap.data!;
        final total = doc.pagesCount;
        final visible =
            widget.unlocked ? total : widget.book.freePages.clamp(0, total);
        final showLock = !widget.unlocked && visible < total;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 40),
          itemCount: 1 + visible + (showLock ? 1 : 0) + (widget.unlocked ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: _ProgressRow(
                    visible: visible, total: total, unlocked: widget.unlocked),
              );
            }
            final pageIndex = index - 1;
            if (pageIndex < visible) {
              return _PdfPageSheet(doc: doc, pageNumber: pageIndex + 1);
            }
            if (showLock && pageIndex == visible) {
              return _LockCard(
                book: widget.book,
                freeShown: visible,
                totalOverride: total,
                onUnlock: widget.onUnlock,
              );
            }
            return const _EndMarker();
          },
        );
      },
    );
  }
}

class _PdfPageSheet extends StatefulWidget {
  const _PdfPageSheet({required this.doc, required this.pageNumber});

  final PdfDocument doc;
  final int pageNumber;

  @override
  State<_PdfPageSheet> createState() => _PdfPageSheetState();
}

class _PdfPageSheetState extends State<_PdfPageSheet> {
  PdfPageImage? _image;
  double _aspect = 0.7;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _render();
  }

  Future<void> _render() async {
    try {
      final page = await widget.doc.getPage(widget.pageNumber);
      final img = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();
      if (!mounted) return;
      setState(() {
        _image = img;
        if (page.height != 0) _aspect = page.width / page.height;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      label: 'Page ${widget.pageNumber}',
      child: AspectRatio(
        aspectRatio: _aspect == 0 ? 0.7 : _aspect,
        child: _failed
            ? const Center(child: Icon(Icons.broken_image_outlined))
            : _image == null
                ? const Center(child: CircularProgressIndicator())
                : Image.memory(_image!.bytes, fit: BoxFit.contain),
      ),
    );
  }
}

// --- shared bits ---------------------------------------------------------

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.visible,
    required this.total,
    required this.unlocked,
  });

  final int visible;
  final int total;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(unlocked ? Icons.lock_open_rounded : Icons.auto_stories,
            size: 18, color: AppColors.ink),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            unlocked
                ? 'Full access · $total pages'
                : 'Preview · $visible of $total pages',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _EndMarker extends StatelessWidget {
  const _EndMarker();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Text('— End of book —',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.ink.withValues(alpha: 0.5))),
      ),
    );
  }
}

class _LockCard extends StatelessWidget {
  const _LockCard({
    required this.book,
    required this.freeShown,
    required this.onUnlock,
    this.totalOverride,
  });

  final EBook book;
  final int freeShown;
  final VoidCallback onUnlock;
  final int? totalOverride;

  @override
  Widget build(BuildContext context) {
    final total = totalOverride ?? book.pageCount;
    final remaining = total - freeShown;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.ink, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            "That's the $freeShown free pages",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.yellow,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock the remaining $remaining pages of “${book.title}” — a '
            'one-time payment, yours for good.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Unlock for ${book.priceBirr} Birr',
            style: DpButtonStyle.yellow,
            trailingIcon: Icons.lock_open_rounded,
            onPressed: onUnlock,
          ),
        ],
      ),
    );
  }
}
