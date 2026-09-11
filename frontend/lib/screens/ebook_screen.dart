import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/app_state.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_image.dart';
import '../widgets/entrance.dart';
import '../widgets/marquee_ticker.dart';
import '../widgets/press_scale.dart';
import '../widgets/wave.dart';

class EBookScreen extends StatelessWidget {
  const EBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final books = state.books;

    return Scaffold(
      backgroundColor: AppColors.yellow,
      drawer: const AppDrawer(),
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(current: 2),
      body: Builder(
        builder: (context) => CustomScrollView(
          slivers: [
            SliverPinnedHeader(
              height: 220,
              child: WaveHeader(
                height: 220,
                greeting: 'Hello! ${state.profile.name.split(' ').first}!',
                headline: 'Welcome to dodo premium book collection',
                onMenu: () => Scaffold.of(context).openDrawer(),
                avatar: AppImage.provider(state.profile.avatar),
                onAvatarTap: () =>
                    AppRoutes.goToSection(context, AppRoutes.profile),
              ),
            ),
            SliverToBoxAdapter(child: MarqueeTicker(text: state.aboutInfo.marqueeText)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
              sliver: SliverList.list(
                children: [
                  if (books.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text(
                        'No books yet.\nAn admin can add them from the admin '
                        'panel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  for (var i = 0; i < books.length; i++)
                    Entrance(
                      delay: Duration(milliseconds: 120 + i * 120),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _BookCard(
                          book: books[i],
                          unlocked: state.isUnlocked(books[i].id),
                          onOpen: () => Navigator.of(context).pushNamed(
                            AppRoutes.ebookReader,
                            arguments: books[i],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.unlocked,
    required this.onOpen,
  });

  final EBook book;
  final bool unlocked;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onOpen,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.yellowSoft.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppImage(book.cover,
                          width: 120, height: 150, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 120,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unlocked ? 'Owned' : '${book.priceBirr} birr',
                        style: const TextStyle(
                            color: AppColors.yellow,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: AppTheme.h2),
                      const SizedBox(height: 6),
                      Text(
                        book.hasPdf
                            ? 'PDF · first ${book.freePages} pages free to '
                                'preview'
                            : '${book.pageCount} pages · first '
                                '${book.freePages} free to preview',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: AppColors.ink.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in book.subjects.take(4))
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.ink,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(s,
                                  style: const TextStyle(
                                      color: AppColors.yellow,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.yellow,
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: onOpen,
                icon: Icon(
                    unlocked ? Icons.menu_book_rounded : Icons.auto_stories,
                    size: 18),
                label: Text(unlocked ? 'Read now' : 'Preview & unlock',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
